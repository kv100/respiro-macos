# Respiro Backend Proxy — PRD

**Backend proxy: наш сервер, наш ключ, юзер ничего не знает про Anthropic**
**Date:** 2026-02-11

---

## 1. What & Why

### Текущая схема (BYOK — Bring Your Own Key)

```
App → (юзер свой API key) → api.anthropic.com
```

Проблема: юзер должен знать про Anthropic, получить ключ, вставить. Friction = 0% adoption.

### Новая схема

```
App → api.respiro.app (наш Supabase Edge Function, наш $500 API key) → api.anthropic.com
```

Юзер скачивает, запускает — работает. Без ключей, без регистрации, без знания Anthropic.

---

## 2. Architecture

### 2.1 Stack

| Layer             | Technology                                      | Why                                                   |
| ----------------- | ----------------------------------------------- | ----------------------------------------------------- |
| **Proxy**         | Supabase Edge Function (Deno/TypeScript)        | Бесплатно, быстро, глобальный CDN, уже есть MCP tools |
| **Auth**          | Supabase Auth (anonymous → Apple Sign-In later) | Встроенный в Supabase, zero config                    |
| **Rate Limiting** | Supabase DB (simple counter table)              | Простая таблица, RLS, без Redis                       |
| **App Client**    | URLSession (existing)                           | Минимальные изменения в ClaudeVisionClient            |

### 2.2 Edge Function (~80 lines)

```
POST /functions/v1/claude-proxy

Headers:
  Authorization: Bearer <supabase_anon_key>  (or user JWT)
  Content-Type: application/json

Body:
  { ...same as Anthropic API body... }

Function:
  1. Validate auth (anon or JWT)
  2. Check rate limit (user_id + date → count)
  3. Forward request to api.anthropic.com with OUR API key
  4. Stream response back to app
  5. Increment usage counter
```

### 2.3 Rate Limiting

| Tier                  | Limit        | Reset        |
| --------------------- | ------------ | ------------ |
| **Anonymous**         | 20 calls/day | Midnight UTC |
| **Free (signed in)**  | 50 calls/day | Midnight UTC |
| **Unlimited (later)** | No limit     | —            |

Для хакатона: anonymous 20/day достаточно. Auth добавим после.

### 2.4 Database Schema

```sql
-- Usage tracking (per device/user per day)
CREATE TABLE usage (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  device_id text NOT NULL,
  user_id uuid REFERENCES auth.users(id),
  date date NOT NULL DEFAULT CURRENT_DATE,
  call_count int NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  UNIQUE(device_id, date)
);

-- RLS: each device sees only their own usage
ALTER TABLE usage ENABLE ROW LEVEL SECURITY;

CREATE POLICY "device_usage" ON usage
  FOR ALL USING (device_id = current_setting('request.headers')::json->>'x-device-id');
```

---

## 3. App Changes

### 3.1 ClaudeVisionClient — Dual Mode

```swift
struct ClaudeVisionClient: Sendable {
    enum Mode: Sendable {
        case direct(apiKey: String)      // BYOK — current behavior
        case proxy(supabaseURL: String)  // Backend proxy — new
    }

    let mode: Mode

    // Existing methods unchanged, just swap endpoint + headers
}
```

**Proxy mode:**

- Endpoint: `https://<project>.supabase.co/functions/v1/claude-proxy`
- Headers: `Authorization: Bearer <supabase_anon_key>`, `x-device-id: <UUID>`
- Body: identical to Anthropic API body (pass-through)
- Response: identical to Anthropic API response (pass-through)

**Direct mode:** unchanged (current BYOK behavior, fallback).

### 3.2 Settings — Remove Key Requirement

- Default mode: proxy (no key needed)
- Settings: toggle "Use own API key" → switches to direct mode
- If proxy fails (rate limit, server down) → prompt user to enter own key

### 3.3 Streaming Support

Edge Function uses `ReadableStream` to stream Anthropic's SSE response back:

```typescript
return new Response(anthropicResponse.body, {
  headers: { "Content-Type": "text/event-stream" },
});
```

App's streaming code (`URLSession.bytes`) works unchanged — same SSE format.

---

## 4. Scope

### In Scope (Now)

- Supabase Edge Function proxy (stream-through)
- Anonymous rate limiting (20 calls/day, device_id based)
- Usage tracking table
- App: dual mode (proxy default, BYOK fallback)
- App: remove mandatory API key requirement

### Out of Scope (Later)

- Apple Sign-In (proper auth)
- Payment/subscription (Stripe/RevenueCat)
- User dashboard (usage stats)
- Multiple API key rotation
- Geographic routing (single region fine for now)

### Budget

- **Supabase:** Free tier (50k Edge Function invocations/month, 500MB DB)
- **Claude API:** $500 budget from Anthropic key
- **At 20 calls/day/user × ~$0.02/call = ~$0.40/user/day**
- **$500 supports ~1,250 user-days** (or ~125 users for 10 days)

---

## 5. Implementation Estimate

| Task                                        | Est       | Where                    |
| ------------------------------------------- | --------- | ------------------------ |
| Supabase project setup + Edge Function      | 1h        | Supabase dashboard + CLI |
| Usage table + RLS                           | 30min     | Supabase SQL editor      |
| ClaudeVisionClient dual mode                | 1.5h      | Swift                    |
| Settings UI update (remove key requirement) | 30min     | Swift                    |
| Testing (proxy + streaming + rate limit)    | 1h        | Manual                   |
| **Total**                                   | **~4.5h** |

---

## 6. Security

- API key lives ONLY in Supabase Edge Function env var (never in app, never in git)
- Anonymous auth via device UUID (hardware ID or generated UUID stored in Keychain)
- Rate limiting prevents abuse
- CORS: only allow requests from our app (User-Agent check)
- No PII stored — only device_id + call_count
- Screenshots never stored server-side (pass-through only)
