// StrokeSense chat proxy (Cloudflare Worker, free plan).
// Holds the OpenAI key and system prompt server-side, and only answers requests carrying
// a valid Firebase App Check token, so the endpoint can't be used outside the real app.

const MODEL = "gpt-4.1-mini";
const MAX_MESSAGES = 20;
const MAX_MESSAGE_LENGTH = 2000;
const MAX_REPLY_TOKENS = 800;
const JWKS_URL = "https://firebaseappcheck.googleapis.com/v1/jwks";
const JWKS_CACHE_MS = 6 * 60 * 60 * 1000;

const SYSTEM_PROMPT =
  "You are an experienced vascular neurologist. Answer stroke related questions in a simple language. " +
  "Include the source/citation of the information/recommendation if possible. Be concise. " +
  "Decline to answer questions about any other topic. You are not a doctor. " +
  "When some ask who you are say, 'I’m an AI designed to provide information about strokes. " +
  "If you have any questions related to strokes, feel free to ask!'";

let jwksCache = { keys: null, fetchedAt: 0 };

export default {
  async fetch(request, env) {
    if (request.method !== "POST") {
      return errorResponse(405, "Method not allowed.");
    }

    try {
      await verifyAppCheckToken(request.headers.get("X-Firebase-AppCheck"), env);
    } catch (error) {
      console.warn("App Check rejected:", error.message);
      return errorResponse(401, "This request could not be verified.");
    }

    let messages;
    try {
      const body = await request.json();
      messages = sanitizeMessages(body && body.messages);
    } catch (error) {
      return errorResponse(400, error instanceof ClientError ? error.message : "Invalid request body.");
    }

    let response;
    try {
      response = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${env.OPENAI_API_KEY}`,
        },
        body: JSON.stringify({
          model: MODEL,
          messages: [{ role: "system", content: SYSTEM_PROMPT }, ...messages],
          max_tokens: MAX_REPLY_TOKENS,
        }),
      });
    } catch (error) {
      console.error("Failed to reach OpenAI:", error);
      return errorResponse(502, "The Stroke Expert is unavailable right now. Please try again.");
    }

    const data = await response.json().catch(() => null);

    if (!response.ok) {
      console.error("OpenAI error", response.status, JSON.stringify(data && data.error));
      if (response.status === 429) {
        return errorResponse(429, "The Stroke Expert is busy right now. Please try again later.");
      }
      return errorResponse(502, "The Stroke Expert couldn't answer right now. Please try again.");
    }

    const reply = data?.choices?.[0]?.message?.content;
    if (!reply) {
      return errorResponse(502, "The Stroke Expert returned an empty response.");
    }

    return Response.json({ reply });
  },
};

class ClientError extends Error {}

function errorResponse(status, message) {
  return Response.json({ error: message }, { status });
}

function sanitizeMessages(messages) {
  if (!Array.isArray(messages) || messages.length === 0) {
    throw new ClientError("messages must be a non-empty array.");
  }

  const cleaned = messages
    .filter((m) => m && (m.role === "user" || m.role === "assistant") && typeof m.content === "string")
    .slice(-MAX_MESSAGES)
    .map((m) => {
      const content = m.content.trim();
      if (content.length > MAX_MESSAGE_LENGTH) {
        throw new ClientError(`Messages must be ${MAX_MESSAGE_LENGTH} characters or fewer.`);
      }
      return { role: m.role, content };
    });

  if (cleaned.length === 0) {
    throw new ClientError("No valid messages were provided.");
  }
  return cleaned;
}

// Verifies a Firebase App Check token (an RS256 JWT) as described in
// https://firebase.google.com/docs/app-check/custom-resource-backend
async function verifyAppCheckToken(token, env) {
  if (!token) throw new Error("missing token");

  const parts = token.split(".");
  if (parts.length !== 3) throw new Error("malformed token");
  const [headerB64, payloadB64, signatureB64] = parts;

  const header = JSON.parse(base64UrlDecodeToString(headerB64));
  const payload = JSON.parse(base64UrlDecodeToString(payloadB64));

  if (header.alg !== "RS256" || header.typ !== "JWT") throw new Error("unexpected header");

  const jwk = await findSigningKey(header.kid);
  const key = await crypto.subtle.importKey(
    "jwk",
    jwk,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["verify"]
  );
  const valid = await crypto.subtle.verify(
    "RSASSA-PKCS1-v1_5",
    key,
    base64UrlDecodeToBytes(signatureB64),
    new TextEncoder().encode(`${headerB64}.${payloadB64}`)
  );
  if (!valid) throw new Error("bad signature");

  const projectNumber = env.FIREBASE_PROJECT_NUMBER;
  if (payload.iss !== `https://firebaseappcheck.googleapis.com/${projectNumber}`) throw new Error("bad issuer");
  if (!Array.isArray(payload.aud) || !payload.aud.includes(`projects/${projectNumber}`)) throw new Error("bad audience");
  if (env.FIREBASE_APP_ID && payload.sub !== env.FIREBASE_APP_ID) throw new Error("bad subject");
  if (typeof payload.exp !== "number" || payload.exp * 1000 < Date.now()) throw new Error("expired");
}

async function findSigningKey(kid) {
  const now = Date.now();
  let keys = jwksCache.keys;
  if (!keys || now - jwksCache.fetchedAt > JWKS_CACHE_MS || !keys.some((k) => k.kid === kid)) {
    const response = await fetch(JWKS_URL);
    if (!response.ok) throw new Error(`JWKS fetch failed (${response.status})`);
    keys = (await response.json()).keys;
    jwksCache = { keys, fetchedAt: now };
  }
  const jwk = keys.find((k) => k.kid === kid);
  if (!jwk) throw new Error("unknown key id");
  return jwk;
}

function base64UrlDecodeToBytes(input) {
  const base64 = input.replace(/-/g, "+").replace(/_/g, "/").padEnd(Math.ceil(input.length / 4) * 4, "=");
  return Uint8Array.from(atob(base64), (c) => c.charCodeAt(0));
}

function base64UrlDecodeToString(input) {
  return new TextDecoder().decode(base64UrlDecodeToBytes(input));
}
