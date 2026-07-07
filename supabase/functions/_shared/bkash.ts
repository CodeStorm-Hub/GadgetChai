export const BKASH_API_URL =
  Deno.env.get("BKASH_API_URL") ??
  "https://tokenized.sandbox.bka.sh/v1.2.0-beta/tokenized";

/** Production: https://tokenized.pay.bka.sh/v1.2.0-beta/tokenized (after merchant onboarding) */
export const BKASH_PRODUCTION_API_URL =
  "https://tokenized.pay.bka.sh/v1.2.0-beta/tokenized";

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

export interface BkashCredentials {
  appKey: string;
  appSecret: string;
  username: string;
  password: string;
}

export function getBkashCredentials(): BkashCredentials {
  return {
    appKey: Deno.env.get("BKASH_APP_KEY") ?? "sandbox_app_key",
    appSecret: Deno.env.get("BKASH_APP_SECRET") ?? "sandbox_app_secret",
    username: Deno.env.get("BKASH_USERNAME") ?? "sandbox_username",
    password: Deno.env.get("BKASH_PASSWORD") ?? "sandbox_password",
  };
}

export async function getBkashToken(creds: BkashCredentials): Promise<string> {
  const response = await fetch(`${BKASH_API_URL}/checkout/token/grant`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      username: creds.username,
      password: creds.password,
    },
    body: JSON.stringify({
      app_key: creds.appKey,
      app_secret: creds.appSecret,
    }),
  });

  if (!response.ok) {
    throw new Error(`Failed to grant bKash token: ${response.statusText}`);
  }

  const data = await response.json();
  return data.id_token as string;
}

export function clientAppUrl(path: string): string {
  const base = (Deno.env.get("CLIENT_APP_URL") ?? "http://localhost:3000").replace(
    /\/$/,
    "",
  );
  return `${base}${path.startsWith("/") ? path : `/${path}`}`;
}

export function bkashCallbackUrl(action: string, rentalId: string): string {
  const callbackBase = `${Deno.env.get("SUPABASE_URL")}/functions/v1/bkash-webhook`;
  return `${callbackBase}?action=${action}&rental_id=${rentalId}`;
}

export function isBkashExecuteSuccess(data: Record<string, unknown>): boolean {
  if (data.statusCode !== "0000") return false;
  const agreementStatus = data.agreementStatus as string | undefined;
  const transactionStatus = data.transactionStatus as string | undefined;
  return agreementStatus === "Completed" || transactionStatus === "Completed";
}

export async function queryBkashPayment(
  paymentID: string,
  token: string,
  appKey: string,
): Promise<Record<string, unknown>> {
  const response = await fetch(
    `${BKASH_API_URL}/checkout/payment/query/${paymentID}`,
    {
      method: "GET",
      headers: {
        Accept: "application/json",
        Authorization: `Bearer ${token}`,
        "X-APP-Key": appKey,
      },
    },
  );
  if (!response.ok) {
    throw new Error(`Query payment failed: ${response.statusText}`);
  }
  return await response.json();
}

export async function cancelBkashAgreement(
  agreementID: string,
  token: string,
  appKey: string,
): Promise<Record<string, unknown>> {
  const response = await fetch(`${BKASH_API_URL}/checkout/agreement/cancel`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      Authorization: `Bearer ${token}`,
      "X-APP-Key": appKey,
    },
    body: JSON.stringify({ agreementID }),
  });
  return await response.json();
}
