import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";

import {

  BKASH_API_URL,

  bkashCallbackUrl,

  cancelBkashAgreement,

  clientAppUrl,

  corsHeaders,

  getBkashCredentials,

  getBkashToken,

  isBkashExecuteSuccess,

  queryBkashPayment,

} from "../_shared/bkash.ts";



function serviceClient() {

  return createClient(

    Deno.env.get("SUPABASE_URL") ?? "",

    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",

  );

}



async function authenticateUser(req: Request) {

  const authHeader = req.headers.get("Authorization");

  if (!authHeader?.startsWith("Bearer ")) {

    return { error: "Missing authorization", status: 401 };

  }



  const supabase = createClient(

    Deno.env.get("SUPABASE_URL") ?? "",

    Deno.env.get("SUPABASE_ANON_KEY") ?? "",

    { global: { headers: { Authorization: authHeader } } },

  );



  const {

    data: { user },

    error,

  } = await supabase.auth.getUser();



  if (error || !user) {

    return { error: "Invalid or expired session", status: 401 };

  }



  return { user };

}



function addMonths(date: Date, months: number): Date {

  const result = new Date(date);

  result.setMonth(result.getMonth() + months);

  return result;

}



function jsonResponse(body: unknown, status = 200) {

  return new Response(JSON.stringify(body), {

    status,

    headers: { ...corsHeaders, "Content-Type": "application/json" },

  });

}



async function executeBkashPayment(paymentID: string, token: string, appKey: string) {

  const execRes = await fetch(`${BKASH_API_URL}/checkout/execute`, {

    method: "POST",

    headers: {

      "Content-Type": "application/json",

      Authorization: `Bearer ${token}`,

      "X-APP-Key": appKey,

    },

    body: JSON.stringify({ paymentID }),

  });

  return await execRes.json();

}



async function resolvePaymentStatus(

  paymentID: string,

  token: string,

  appKey: string,

  execData: Record<string, unknown>,

): Promise<Record<string, unknown>> {

  if (isBkashExecuteSuccess(execData)) return execData;

  try {

    const queried = await queryBkashPayment(paymentID, token, appKey);

    if (isBkashExecuteSuccess(queried)) return queried;

  } catch {

    // fall through to original execute response

  }

  return execData;

}



async function createInitialPayment(

  rental: Record<string, unknown>,

  agreementID: string,

  payerPhone: string,

  token: string,

  appKey: string,

  rentalId: string,

) {

  const amount = (

    Number(rental.monthly_price) + Number(rental.security_deposit)

  ).toString();



  const bkashRes = await fetch(`${BKASH_API_URL}/checkout/create`, {

    method: "POST",

    headers: {

      "Content-Type": "application/json",

      Authorization: `Bearer ${token}`,

      "X-APP-Key": appKey,

    },

    body: JSON.stringify({

      mode: "0001",

      agreementID,

      payerReference: payerPhone,

      callbackURL: bkashCallbackUrl("execute-initial-payment", rentalId),

      amount,

      currency: "BDT",

      intent: "sale",

      merchantInvoiceNumber: `INV-${String(rentalId).substring(0, 8)}-INIT`,

    }),

  });



  return await bkashRes.json();

}



serve(async (req) => {

  if (req.method === "OPTIONS") {

    return new Response("ok", { headers: corsHeaders });

  }



  try {

    const supabase = serviceClient();

    const bkashCreds = getBkashCredentials();

    const url = new URL(req.url);

    let action = url.searchParams.get("action");



    let postBody: Record<string, unknown> | null = null;

    if (req.method === "POST") {

      try {

        postBody = await req.json();

        if (!action && postBody?.action) {

          action = String(postBody.action);

        }

      } catch {

        postBody = null;

      }

    }



    // Step 1: Create tokenized agreement (mode 0000)

    if (req.method === "POST" && action === "create-agreement") {

      const auth = await authenticateUser(req);

      if ("error" in auth) {

        return jsonResponse({ error: auth.error }, auth.status);

      }



      const rental_id = postBody?.rental_id as string | undefined;

      const payer_phone = postBody?.payer_phone as string | undefined;



      if (!rental_id) {

        return jsonResponse({ error: "rental_id is required" }, 400);

      }



      const { data: rental, error: fetchErr } = await supabase

        .from("rentals")

        .select("*, devices(*)")

        .eq("id", rental_id)

        .single();



      if (fetchErr || !rental) {

        return jsonResponse({ error: "Rental not found" }, 404);

      }



      if (rental.user_id !== auth.user.id) {

        return jsonResponse({ error: "Forbidden" }, 403);

      }



      const token = await getBkashToken(bkashCreds);

      const callbackURL = bkashCallbackUrl("execute-agreement", rental_id);



      const bkashRes = await fetch(`${BKASH_API_URL}/checkout/create`, {

        method: "POST",

        headers: {

          "Content-Type": "application/json",

          Authorization: `Bearer ${token}`,

          "X-APP-Key": bkashCreds.appKey,

        },

        body: JSON.stringify({

          mode: "0000",

          payerReference: payer_phone ?? "01770618575",

          callbackURL,

          currency: "BDT",

          intent: "sale",

          merchantInvoiceNumber: `AGR-${String(rental_id).substring(0, 8)}`,

        }),

      });



      const bkashData = await bkashRes.json();

      const redirectUrl =

        bkashData.bkashURL ?? bkashData.redirectURL ?? bkashData.redirect_url;



      return jsonResponse({

        ...bkashData,

        redirect_url: redirectUrl,

        flow_step: "agreement",

      });

    }



    // Step 2: bKash callback after agreement OTP — execute agreement, chain to initial payment

    if (req.method === "GET" && action === "execute-agreement") {

      const paymentID = url.searchParams.get("paymentID");

      const status = url.searchParams.get("status");

      const rental_id = url.searchParams.get("rental_id");



      if (!rental_id) {

        return new Response("Missing rental_id", { status: 400 });

      }



      if (status === "cancel" || status === "failure") {

        return Response.redirect(

          clientAppUrl(

            `/checkout/status?status=failed&rental_id=${rental_id}&message=${encodeURIComponent("Agreement cancelled or failed")}`,

          ),

        );

      }



      if (!paymentID) {

        return Response.redirect(

          clientAppUrl(

            `/checkout/status?status=failed&rental_id=${rental_id}&message=${encodeURIComponent("Missing paymentID")}`,

          ),

        );

      }



      const token = await getBkashToken(bkashCreds);

      const execData = await executeBkashPayment(

        paymentID,

        token,

        bkashCreds.appKey,

      );



      if (!isBkashExecuteSuccess(execData)) {

        return Response.redirect(

          clientAppUrl(

            `/checkout/status?status=failed&rental_id=${rental_id}&message=${encodeURIComponent(execData.statusMessage ?? "Agreement execution failed")}`,

          ),

        );

      }



      const agreementID = (execData.agreementID ?? execData.agreementId) as string;

      await supabase

        .from("rentals")

        .update({ bkash_agreement_id: agreementID })

        .eq("id", rental_id);



      const { data: rental } = await supabase

        .from("rentals")

        .select("*, profiles(phone)")

        .eq("id", rental_id)

        .single();



      const payerPhone =

        rental?.profiles?.phone ?? execData.payerReference ?? "01770618575";



      const paymentData = await createInitialPayment(

        rental!,

        agreementID,

        payerPhone,

        token,

        bkashCreds.appKey,

        rental_id,

      );



      const paymentUrl =

        paymentData.bkashURL ?? paymentData.redirectURL ?? paymentData.redirect_url;



      if (!paymentUrl) {

        return Response.redirect(

          clientAppUrl(

            `/checkout/status?status=failed&rental_id=${rental_id}&message=${encodeURIComponent(paymentData.statusMessage ?? "Initial payment creation failed")}`,

          ),

        );

      }



      return Response.redirect(paymentUrl);

    }



    // Step 3: bKash callback after initial payment PIN

    if (req.method === "GET" && action === "execute-initial-payment") {

      const paymentID = url.searchParams.get("paymentID");

      const status = url.searchParams.get("status");

      const rental_id = url.searchParams.get("rental_id");



      if (!rental_id) {

        return new Response("Missing rental_id", { status: 400 });

      }



      if (status === "cancel" || status === "failure") {

        return Response.redirect(

          clientAppUrl(

            `/checkout/status?status=failed&rental_id=${rental_id}&message=${encodeURIComponent("Payment cancelled or failed")}`,

          ),

        );

      }



      if (!paymentID) {

        return Response.redirect(

          clientAppUrl(

            `/checkout/status?status=failed&rental_id=${rental_id}&message=${encodeURIComponent("Missing paymentID")}`,

          ),

        );

      }



      const token = await getBkashToken(bkashCreds);

      let execData = await executeBkashPayment(

        paymentID,

        token,

        bkashCreds.appKey,

      );

      execData = await resolvePaymentStatus(

        paymentID,

        token,

        bkashCreds.appKey,

        execData,

      );



      if (!isBkashExecuteSuccess(execData)) {

        return Response.redirect(

          clientAppUrl(

            `/checkout/status?status=failed&rental_id=${rental_id}&message=${encodeURIComponent(execData.statusMessage ?? "Payment execution failed")}`,

          ),

        );

      }



      const { data: rental } = await supabase

        .from("rentals")

        .select("plan_months")

        .eq("id", rental_id)

        .single();



      const startDate = new Date();

      const planMonths = rental?.plan_months ?? 3;

      const endDate = addMonths(startDate, planMonths);

      const nextBilling = new Date(

        startDate.getTime() + 30 * 24 * 60 * 60 * 1000,

      );



      const { error: updateErr } = await supabase

        .from("rentals")

        .update({

          status: "awaiting_dispatch",

          start_date: startDate.toISOString(),

          end_date: endDate.toISOString(),

          next_billing_date: nextBilling.toISOString(),

          billing_retry_count: 0,

        })

        .eq("id", rental_id);



      if (updateErr) throw updateErr;



      await supabase.from("transactions").insert({

        rental_id,

        amount: Number(execData.amount ?? 0),

        bkash_payment_id: execData.trxID,

        status: "success",

      });



      return Response.redirect(

        clientAppUrl(`/checkout/status?status=success&rental_id=${rental_id}`),

      );

    }



    // Retry initial payment if agreement exists but payment URL expired

    if (req.method === "POST" && action === "create-initial-payment") {

      const auth = await authenticateUser(req);

      if ("error" in auth) {

        return jsonResponse({ error: auth.error }, auth.status);

      }



      const rental_id = postBody?.rental_id as string | undefined;

      if (!rental_id) {

        return jsonResponse({ error: "rental_id is required" }, 400);

      }



      const { data: rental, error: fetchErr } = await supabase

        .from("rentals")

        .select("*, profiles(phone)")

        .eq("id", rental_id)

        .single();



      if (fetchErr || !rental) {

        return jsonResponse({ error: "Rental not found" }, 404);

      }



      if (rental.user_id !== auth.user.id) {

        return jsonResponse({ error: "Forbidden" }, 403);

      }



      if (!rental.bkash_agreement_id) {

        return jsonResponse({ error: "No bKash agreement on this rental" }, 400);

      }



      const token = await getBkashToken(bkashCreds);

      const payerPhone = rental.profiles?.phone ?? "01770618575";

      const paymentData = await createInitialPayment(

        rental,

        rental.bkash_agreement_id,

        payerPhone,

        token,

        bkashCreds.appKey,

        rental_id,

      );



      const redirectUrl =

        paymentData.bkashURL ?? paymentData.redirectURL ?? paymentData.redirect_url;



      return jsonResponse({

        ...paymentData,

        redirect_url: redirectUrl,

        flow_step: "initial_payment",

      });

    }



    // Cancel agreement (admin or customer cancel flow)

    if (req.method === "POST" && action === "cancel-agreement") {

      const auth = await authenticateUser(req);

      if ("error" in auth) {

        return jsonResponse({ error: auth.error }, auth.status);

      }



      const rental_id = postBody?.rental_id as string | undefined;

      if (!rental_id) {

        return jsonResponse({ error: "rental_id is required" }, 400);

      }



      const { data: rental } = await supabase

        .from("rentals")

        .select("bkash_agreement_id, user_id")

        .eq("id", rental_id)

        .single();



      if (!rental || rental.user_id !== auth.user.id) {

        return jsonResponse({ error: "Forbidden" }, 404);

      }



      if (!rental.bkash_agreement_id) {

        return jsonResponse({ error: "No agreement to cancel" }, 400);

      }



      const token = await getBkashToken(bkashCreds);

      const result = await cancelBkashAgreement(

        rental.bkash_agreement_id,

        token,

        bkashCreds.appKey,

      );



      await supabase

        .from("rentals")

        .update({ bkash_agreement_id: null, status: "pending_kyc" })

        .eq("id", rental_id);



      return jsonResponse(result);

    }



    if (req.method === "POST" && action === "execute-agreement") {

      return jsonResponse(

        { error: "execute-agreement must be completed via bKash redirect" },

        405,

      );

    }



    return jsonResponse({ error: "Invalid action" }, 400);

  } catch (err) {

    const message = err instanceof Error ? err.message : String(err);

    return jsonResponse({ error: message }, 500);

  }

});


