# Respiro Backend Proxy — Backlog

> Full PRD: `docs/PRD_BACKEND.md`
> Stack: Supabase Edge Functions (Deno/TypeScript) + Supabase DB

---

## Task List

| ID   | Task                                                                 | Est   | Agent           | Depends   | Status |
| ---- | -------------------------------------------------------------------- | ----- | --------------- | --------- | ------ |
| BE.1 | Supabase project setup — create project, configure env vars          | 30min | swift-developer | —         | todo   |
| BE.2 | Edge Function `claude-proxy` — stream-through proxy to Anthropic API | 1h    | swift-developer | BE.1      | todo   |
| BE.3 | Usage table + RLS — rate limiting schema, device_id policy           | 30min | swift-developer | BE.1      | todo   |
| BE.4 | Rate limiting in Edge Function — check + increment per device/day    | 30min | swift-developer | BE.2,BE.3 | todo   |
| BE.5 | ClaudeVisionClient dual mode — proxy (default) + direct (BYOK)       | 1.5h  | swift-developer | BE.2      | todo   |
| BE.6 | Settings UI — remove key requirement, add proxy/BYOK toggle          | 30min | swiftui-pro     | BE.5      | todo   |
| BE.7 | Testing — proxy + streaming + rate limit + fallback                  | 1h    | swift-developer | BE.4-BE.6 | todo   |

**Total: ~5.5h**

---

## Dependencies

```
BE.1 (supabase setup)
  ├── BE.2 (edge function) ──┐
  └── BE.3 (usage table) ───┤
                             ├── BE.4 (rate limiting)
                             │
BE.2 ── BE.5 (dual mode client) ── BE.6 (settings UI)
                                         │
BE.4 + BE.6 ── BE.7 (testing) ──────────┘
```

**Parallel:** BE.2 + BE.3 can run in parallel after BE.1

---

## Architecture

```
┌─────────────┐     ┌───────────────────────────────┐     ┌─────────────────┐
│  Respiro    │     │  Supabase Edge Function        │     │  Anthropic API   │
│  macOS App  │────▶│  claude-proxy                  │────▶│  api.anthropic   │
│             │◀────│  (our API key in env var)       │◀────│  .com/v1/messages│
│  URLSession │ SSE │  + rate limit check            │ SSE │                  │
└─────────────┘     └───────────────────────────────┘     └─────────────────┘
                            │
                    ┌───────▼───────┐
                    │  Supabase DB  │
                    │  usage table  │
                    │  (rate limits)│
                    └───────────────┘
```

---

## Agent Specs — Supabase Setup (BE.1)

Use Supabase MCP tools (available in this project).

1. Create or use existing Supabase project
2. Set environment variable: `ANTHROPIC_API_KEY` in Edge Function secrets
3. Note project URL and anon key for app configuration

```bash
# Via Supabase CLI (if available) or MCP tools:
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
```

---

## Agent Specs — Edge Function (BE.2)

File: `supabase/functions/claude-proxy/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY")!;
const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (req: Request) => {
  // CORS
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers":
          "authorization, x-device-id, content-type",
      },
    });
  }

  try {
    // 1. Get device ID
    const deviceId = req.headers.get("x-device-id");
    if (!deviceId) {
      return new Response(
        JSON.stringify({ error: "Missing x-device-id header" }),
        {
          status: 400,
        },
      );
    }

    // 2. Check rate limit
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const today = new Date().toISOString().split("T")[0];

    const { data: usage } = await supabase
      .from("usage")
      .select("call_count")
      .eq("device_id", deviceId)
      .eq("date", today)
      .single();

    const currentCount = usage?.call_count ?? 0;
    const DAILY_LIMIT = 20;

    if (currentCount >= DAILY_LIMIT) {
      return new Response(
        JSON.stringify({
          error: "Daily limit reached",
          limit: DAILY_LIMIT,
          used: currentCount,
        }),
        { status: 429 },
      );
    }

    // 3. Forward to Anthropic (stream-through)
    const body = await req.text();
    const anthropicResponse = await fetch(ANTHROPIC_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: body,
    });

    // 4. Increment usage (fire-and-forget)
    supabase.rpc("increment_usage", { p_device_id: deviceId }).then(() => {});

    // 5. Stream response back
    return new Response(anthropicResponse.body, {
      status: anthropicResponse.status,
      headers: {
        "Content-Type":
          anthropicResponse.headers.get("Content-Type") ?? "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
    });
  }
});
```

**Key:** The function is a transparent stream-through proxy. Same request format, same response format. The app doesn't know it's talking to a proxy.

---

## Agent Specs — Database (BE.3)

```sql
-- Usage tracking table
CREATE TABLE IF NOT EXISTS public.usage (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  device_id text NOT NULL,
  date date NOT NULL DEFAULT CURRENT_DATE,
  call_count int NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  UNIQUE(device_id, date)
);

-- RLS
ALTER TABLE public.usage ENABLE ROW LEVEL SECURITY;

-- Allow Edge Function (service role) to read/write
-- No RLS policy needed for service_role (bypasses RLS)

-- Increment function (upsert + increment atomically)
CREATE OR REPLACE FUNCTION public.increment_usage(p_device_id text)
RETURNS void AS $$
BEGIN
  INSERT INTO public.usage (device_id, date, call_count)
  VALUES (p_device_id, CURRENT_DATE, 1)
  ON CONFLICT (device_id, date)
  DO UPDATE SET call_count = public.usage.call_count + 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## Agent Specs — ClaudeVisionClient Dual Mode (BE.5)

### Changes to `ClaudeVisionClient.swift`

```swift
struct ClaudeVisionClient: Sendable {
    enum Mode: Sendable {
        case direct(apiKey: String)
        case proxy(supabaseURL: String, anonKey: String, deviceID: String)
    }

    let mode: Mode

    // MARK: - Endpoint Resolution

    private var endpoint: URL {
        switch mode {
        case .direct:
            return URL(string: "https://api.anthropic.com/v1/messages")!
        case .proxy(let url, _, _):
            return URL(string: "\(url)/functions/v1/claude-proxy")!
        }
    }

    private func authHeaders() -> [String: String] {
        switch mode {
        case .direct(let apiKey):
            return [
                "x-api-key": apiKey,
                "anthropic-version": "2023-06-01",
            ]
        case .proxy(_, let anonKey, let deviceID):
            return [
                "Authorization": "Bearer \(anonKey)",
                "x-device-id": deviceID,
            ]
        }
    }

    // MARK: - Init

    /// Proxy mode (default — no API key needed)
    init(supabaseURL: String, anonKey: String, deviceID: String) {
        self.mode = .proxy(supabaseURL: supabaseURL, anonKey: anonKey, deviceID: deviceID)
    }

    /// Direct mode (BYOK)
    init(apiKey: String) {
        self.mode = .direct(apiKey: apiKey)
    }

    /// Auto-detect mode: proxy if available, direct if API key set
    init() throws {
        // Try proxy first (hardcoded Supabase URL)
        let supabaseURL = "https://YOUR_PROJECT.supabase.co"  // TODO: configure
        let anonKey = "YOUR_ANON_KEY"  // TODO: configure
        let deviceID = DeviceID.current

        if !supabaseURL.contains("YOUR_PROJECT") {
            self.mode = .proxy(supabaseURL: supabaseURL, anonKey: anonKey, deviceID: deviceID)
        } else if let key = APIKeyManager.getAPIKey() {
            self.mode = .direct(apiKey: key)
        } else {
            throw ClaudeAPIError.noAPIKey
        }
    }
}
```

### DeviceID Helper

```swift
enum DeviceID {
    static var current: String {
        // Try to get from Keychain first (persistent)
        if let stored = KeychainHelper.get("respiro_device_id") {
            return stored
        }
        // Generate new UUID, store in Keychain
        let id = UUID().uuidString
        KeychainHelper.set("respiro_device_id", value: id)
        return id
    }
}
```

### Minimal Changes to Existing Methods

The key insight: **request body is identical** for both proxy and direct mode. Only the URL and headers change. So:

1. `buildURLRequest(body:)` — use `endpoint` and `authHeaders()` instead of hardcoded values
2. `analyzeScreenshot()` — unchanged
3. `analyzeScreenshotWithTools()` — unchanged
4. `streamAnalysis()` — unchanged (SSE format is pass-through)
5. All parsing logic — unchanged (response format identical)

**Estimated diff: ~30 lines changed in ClaudeVisionClient.swift**

---

## Agent Specs — Settings UI (BE.6)

### Changes to SettingsView

Replace current API key section:

```swift
// BEFORE: mandatory API key input
// AFTER: optional, with proxy as default

private var apiSection: some View {
    VStack(alignment: .leading, spacing: 14) {
        sectionHeader(title: "API", icon: "server.rack")

        // Status indicator
        HStack {
            Circle()
                .fill(isProxyMode ? Color(hex: "#10B981") : Color(hex: "#8BA4B0"))
                .frame(width: 8, height: 8)
            Text(isProxyMode ? "Connected via Respiro servers" : "Using own API key")
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.72))
        }

        // Toggle
        Toggle("Use own API key", isOn: $useOwnKey)
            .font(.system(size: 12))

        // API key input (only shown if toggled)
        if useOwnKey {
            SecureField("API Key", text: $apiKey)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 11))
        }

        // Usage (proxy mode only)
        if isProxyMode {
            Text("\(dailyUsed)/20 analyses today")
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.45))
        }
    }
}
```

---

## Agent Specs — Supabase Config (app-side)

Store in `Info.plist` or hardcode (hackathon speed):

```swift
enum RespiroConfig {
    static let supabaseURL = "https://xxxxx.supabase.co"
    static let supabaseAnonKey = "eyJhbGc..."  // public anon key (safe to embed)
}
```

**Security note:** The anon key is PUBLIC by design (Supabase docs). It only grants access to what RLS policies allow. The actual Anthropic API key is in the Edge Function environment — never in the app.

---

## Sprint Plan

| Phase                | Tasks       | Parallel? | Est   |
| -------------------- | ----------- | --------- | ----- |
| 1. Supabase setup    | BE.1        | —         | 30min |
| 2. Server (parallel) | BE.2 + BE.3 | Yes       | 1h    |
| 3. Rate limiting     | BE.4        | —         | 30min |
| 4. App changes       | BE.5 + BE.6 | Parallel  | 1.5h  |
| 5. Testing           | BE.7        | —         | 1h    |

**Total: ~4.5h wall time**

---

## Key Decisions

1. **Supabase Edge Functions** — free tier, global CDN, already have MCP tools. No need for AWS/Vercel.
2. **Stream-through proxy** — same request/response format. Minimal app changes.
3. **Device ID rate limiting** — simple, no auth required. UUID in Keychain.
4. **Anon key in app is safe** — Supabase design. RLS protects data. Anthropic key in server only.
5. **Dual mode** — proxy default, BYOK fallback. Both work, user chooses.
6. **20 calls/day anonymous** — enough for real usage (screenshots every 5min × 8h = ~96 calls, but adaptive interval makes it ~20-40).

---

## What NOT to Build

- User accounts / Apple Sign-In (later)
- Payment / subscription (later)
- Admin dashboard (later)
- API key rotation (later)
- Multi-region routing (single region fine)
- Usage analytics beyond rate limiting
