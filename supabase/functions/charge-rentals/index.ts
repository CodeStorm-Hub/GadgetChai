import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";
import {
  BKASH_API_URL,
  corsHeaders,
  getBkashCredentials,
  getBkashToken,
  isBkashExecuteSuccess,
  queryBkashPayment,
} from "../_shared/bkash.ts";

const MAX_BILLING_RETRIES = 3;

function requireCronAuth(req: Request): Response | null {
  const cronSecret = Deno.env.get("CRON_SECRET");
  if (!cronSecret) {
    return new Response(
      JSON.stringify({ error: "CRON_SECRET is not configured" }),
      {
        status: 503,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  const authHeader = req.headers.get("Authorization");
  if (authHeader !== `Bearer ${cronSecret}`) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  return null;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const authError = requireCronAuth(req);
  if (authError) return authError;

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data: rentals, error: fetchErr } = await supabase
      .from("rentals")
      .select("*, profiles(phone)")
      .eq("status", "active")
      .lte("next_billing_date", new Date().toISOString());

    if (fetchErr) {
      throw new Error(fetchErr.message ?? JSON.stringify(fetchErr));
    }

    if (!rentals?.length) {
      return new Response(
        JSON.stringify({ processed: 0, results: [], message: "No rentals due" }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const bkashCreds = getBkashCredentials();
    const token = await getBkashToken(bkashCreds);

    const results: Array<Record<string, unknown>> = [];

    for (const rental of rentals ?? []) {
      if (!rental.bkash_agreement_id) {
        results.push({
          rental_id: rental.id,
          status: "error",
          message: "No bKash agreement ID",
        });
        continue;
      }

      if (rental.end_date && new Date(rental.end_date) <= new Date()) {
        await supabase
          .from("rentals")
          .update({ status: "returned" })
          .eq("id", rental.id);
        results.push({
          rental_id: rental.id,
          status: "completed",
          message: "Rental contract period ended",
        });
        continue;
      }

      try {
        const createPaymentRes = await fetch(`${BKASH_API_URL}/checkout/create`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
            "X-APP-Key": bkashCreds.appKey,
          },
          body: JSON.stringify({
            mode: "0001",
            agreementID: rental.bkash_agreement_id,
            payerReference: rental.profiles?.phone ?? "01700000000",
            callbackURL: "https://example.com/unused-callback",
            amount: rental.monthly_price.toString(),
            currency: "BDT",
            intent: "sale",
            merchantInvoiceNumber:
              `INV-${String(rental.id).substring(0, 8)}-${Date.now()}`,
          }),
        });

        const createPaymentData = await createPaymentRes.json();

        if (createPaymentData.statusCode !== "0000") {
          throw new Error(
            createPaymentData.statusMessage ?? "Payment creation failed",
          );
        }

        const execPaymentRes = await fetch(`${BKASH_API_URL}/checkout/execute`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
            "X-APP-Key": bkashCreds.appKey,
          },
          body: JSON.stringify({ paymentID: createPaymentData.paymentID }),
        });

        const execPaymentData = await execPaymentRes.json();

        let finalData = execPaymentData as Record<string, unknown>;
        if (!isBkashExecuteSuccess(finalData)) {
          try {
            const queried = await queryBkashPayment(
              createPaymentData.paymentID,
              token,
              bkashCreds.appKey,
            );
            if (isBkashExecuteSuccess(queried)) {
              finalData = queried;
            }
          } catch (queryErr) {
            console.error(
              `Query payment fallback failed for rental ${rental.id}:`,
              queryErr,
            );
          }
        }

        if (isBkashExecuteSuccess(finalData)) {
          const nextBilling = new Date(
            new Date(rental.next_billing_date).getTime() +
              30 * 24 * 60 * 60 * 1000,
          );

          await supabase
            .from("rentals")
            .update({
              next_billing_date: nextBilling.toISOString(),
              billing_retry_count: 0,
            })
            .eq("id", rental.id);

          await supabase.from("transactions").insert({
            rental_id: rental.id,
            amount: rental.monthly_price,
            bkash_payment_id: finalData.trxID,
            status: "success",
          });

          results.push({
            rental_id: rental.id,
            status: "success",
            transaction_id: finalData.trxID,
          });
        } else {
          throw new Error(
            (finalData.statusMessage as string) ?? "Payment execution failed",
          );
        }
      } catch (chargeErr) {
        const message = chargeErr instanceof Error
          ? chargeErr.message
          : String(chargeErr);
        const retryCount = (rental.billing_retry_count ?? 0) + 1;

        await supabase.from("transactions").insert({
          rental_id: rental.id,
          amount: rental.monthly_price,
          status: "failed",
        });

        if (retryCount >= MAX_BILLING_RETRIES) {
          await supabase
            .from("rentals")
            .update({ status: "defaulted", billing_retry_count: retryCount })
            .eq("id", rental.id);
        } else {
          await supabase
            .from("rentals")
            .update({ billing_retry_count: retryCount })
            .eq("id", rental.id);
        }

        console.error(`Billing failed for rental ${rental.id}: ${message}`);
        results.push({
          rental_id: rental.id,
          status: "failed",
          retries: retryCount,
          error: message,
        });
      }
    }

    return new Response(
      JSON.stringify({ processed: results.length, results }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
