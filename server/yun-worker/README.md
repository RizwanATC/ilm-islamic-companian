# Yun AI server

A small Cloudflare Worker that answers questions in the app's Yun/Ayu chat using Claude.
The app sends the conversation plus the user's place and today's prayer times; the worker
adds the system prompt (mainstream Sunni, Shafi'i notes for Malaysia, Quran citations,
no invented hadith) and returns `{ "reply": "..." }`.

## Deploy (about 10 minutes)

You need Node.js 22+, a free Cloudflare account and a Claude API key.

1. Create an API key at https://platform.claude.com (Settings → API keys) and add some credit.
2. In this folder:
   ```sh
   npm install
   npx wrangler login
   npx wrangler secret put ANTHROPIC_API_KEY   # paste the Claude key
   npx wrangler secret put APP_KEY             # paste a long random string, e.g. from `openssl rand -hex 24`
   npx wrangler deploy
   ```
   Wrangler prints the URL, like `https://ilm-yun.<your-subdomain>.workers.dev`.
3. Build the app with both values:
   ```sh
   flutter build appbundle \
     --dart-define=YUN_API_URL=https://ilm-yun.<your-subdomain>.workers.dev \
     --dart-define=YUN_APP_KEY=<the APP_KEY you chose>
   ```
   Use the same two `--dart-define` flags with `flutter run` and `flutter build ipa`.
   Without them the chat keeps its built-in sample answers.

## Test it

```sh
curl -X POST https://ilm-yun.<your-subdomain>.workers.dev/chat \
  -H 'content-type: application/json' -H 'x-app-key: <APP_KEY>' \
  -d '{"messages":[{"role":"user","content":"What is Ayat al-Kursi?"}]}'
```

## Notes

- **Cost control.** The app key ships inside the app, so treat it as a speed bump, not a
  password. `wrangler.toml` limits each IP to 20 requests a minute, and each request is capped
  at 20 messages of 2,000 characters. Set a monthly spend limit in the Claude Console too.
- **Model.** Defaults to `claude-opus-5-5` at low effort. Set a `MODEL` variable in
  `wrangler.toml` to change it. If that model is overloaded the API falls back to another
  automatically.
- **Local run.** `npx wrangler dev` (put the two secrets in a `.dev.vars` file).
- **Logs.** `npx wrangler tail`.
