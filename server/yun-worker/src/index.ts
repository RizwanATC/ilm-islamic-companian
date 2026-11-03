import Anthropic from "@anthropic-ai/sdk";

export interface Env {
  ANTHROPIC_API_KEY: string;
  /** Shared key the app sends in X-App-Key. */
  APP_KEY: string;
  /** Optional model override; defaults to claude-opus-5-5. */
  MODEL?: string;
  /** Optional Cloudflare rate limiting binding (see wrangler.toml). */
  RATE_LIMITER?: { limit(opts: { key: string }): Promise<{ success: boolean }> };
}

type Role = "user" | "assistant";
interface ChatMessage {
  role: Role;
  content: string;
}
interface Context {
  name?: string;
  botName?: string;
  place?: string;
  prayerTimes?: Record<string, string>;
  nextPrayer?: string;
  lang?: string;
  today?: string;
}

const MAX_MESSAGES = 20;
const MAX_CHARS = 2000;

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });

function systemPrompt(ctx: Context): string {
  const bot = clean(ctx.botName, 40) || "Yun";
  const lines = [
    `You are ${bot}, a warm, gentle companion inside "Ilm", a Muslim prayer and Quran app.`,
    "Answer questions about Islam, the Quran, prayer, fasting, duas and daily Muslim life.",
    "",
    "How to answer:",
    "- Be warm and concise: a few short paragraphs at most, plain text, no markdown headings.",
    "- Follow mainstream Sunni scholarship. Many users are in Malaysia, where the Shafi'i school is followed; mention the Shafi'i position when schools differ.",
    "- When you quote or refer to the Quran, cite it as Surah name surah:ayah (for example Al-Baqarah 2:286).",
    "- Only mention hadith you are confident are authentic, and name the collection (Bukhari, Muslim, etc.). Never invent or paraphrase a hadith as if quoting it. If unsure, say so.",
    "- For personal rulings (divorce, inheritance, specific fatwa questions, unusual situations), give the general principle and suggest the user ask a local ustaz or their state mufti office.",
    "- If someone sounds in crisis or at risk of harm, respond with compassion and encourage them to contact local emergency services or a professional helpline (in Malaysia, Befrienders KL: 03-7627 2929).",
    "- Reply in the language the user writes in (Malay, English or Arabic).",
    "- For prayer times, use only the times provided below. Never guess times for other places or days.",
  ];
  const facts: string[] = [];
  const name = clean(ctx.name, 40);
  if (name) facts.push(`The user's name is ${name}.`);
  const place = clean(ctx.place, 80);
  if (place) facts.push(`They are in ${place}.`);
  const today = clean(ctx.today, 40);
  if (today) facts.push(`Today is ${today}.`);
  if (ctx.prayerTimes && typeof ctx.prayerTimes === "object") {
    const t = Object.entries(ctx.prayerTimes)
      .slice(0, 8)
      .map(([k, v]) => `${clean(k, 12)} ${clean(String(v), 12)}`)
      .join(", ");
    if (t) facts.push(`Today's prayer times there: ${t}.`);
  }
  const next = clean(ctx.nextPrayer, 60);
  if (next) facts.push(`Next prayer: ${next}.`);
  const lang = clean(ctx.lang, 10);
  if (lang) facts.push(`App language: ${lang}.`);
  if (facts.length) lines.push("", "About the user:", ...facts);
  return lines.join("\n");
}

function clean(v: unknown, max: number): string {
  return typeof v === "string" ? v.replace(/[\r\n]+/g, " ").trim().slice(0, max) : "";
}

function parseMessages(raw: unknown): ChatMessage[] | null {
  if (!Array.isArray(raw) || raw.length === 0) return null;
  const msgs: ChatMessage[] = [];
  for (const m of raw.slice(-MAX_MESSAGES)) {
    if (!m || (m.role !== "user" && m.role !== "assistant")) return null;
    if (typeof m.content !== "string") return null;
    const content = m.content.trim().slice(0, MAX_CHARS);
    if (!content) continue;
    // Merge consecutive turns from the same side.
    const last = msgs[msgs.length - 1];
    if (last && last.role === m.role) last.content += "\n\n" + content;
    else msgs.push({ role: m.role, content });
  }
  while (msgs.length && msgs[0].role !== "user") msgs.shift();
  if (!msgs.length || msgs[msgs.length - 1].role !== "user") return null;
  return msgs;
}

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url);
    if (url.pathname !== "/chat") return json({ error: "not_found" }, 404);
    if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
    if (!env.APP_KEY || req.headers.get("x-app-key") !== env.APP_KEY) {
      return json({ error: "unauthorized" }, 401);
    }

    if (env.RATE_LIMITER) {
      const ip = req.headers.get("cf-connecting-ip") ?? "unknown";
      const { success } = await env.RATE_LIMITER.limit({ key: ip });
      if (!success) return json({ error: "rate_limited" }, 429);
    }

    let body: { messages?: unknown; context?: Context };
    try {
      body = await req.json();
    } catch {
      return json({ error: "bad_request" }, 400);
    }
    const messages = parseMessages(body.messages);
    if (!messages) return json({ error: "bad_request" }, 400);

    const client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });
    try {
      const res = await client.beta.messages.create({
        model: env.MODEL || "claude-opus-5-5",
        max_tokens: 2000,
        output_config: { effort: "low" },
        betas: ["server-side-fallback-2026-07-01"],
        fallbacks: "default",
        system: systemPrompt(body.context ?? {}),
        messages,
      });
      if (res.stop_reason === "refusal") {
        return json({ error: "refused" }, 422);
      }
      const reply = res.content
        .flatMap((b) => (b.type === "text" ? [b.text] : []))
        .join("")
        .trim();
      if (!reply) return json({ error: "empty" }, 502);
      return json({ reply });
    } catch (e) {
      if (e instanceof Anthropic.RateLimitError) return json({ error: "busy" }, 503);
      if (e instanceof Anthropic.APIError) {
        console.error("anthropic", e.status, e.message);
        return json({ error: "upstream" }, 502);
      }
      console.error(e);
      return json({ error: "internal" }, 500);
    }
  },
};
