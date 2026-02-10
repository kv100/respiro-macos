# Supabase Integration - Quick Reference

## Client Setup

```typescript
// Backend (service role for admin ops)
import { createClient } from "@supabase/supabase-js";

const supabaseAdmin = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
  { auth: { autoRefreshToken: false, persistSession: false } },
);

// Mobile (anon key for user ops)
import AsyncStorage from "@react-native-async-storage/async-storage";

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_ANON_KEY!,
  { auth: { storage: AsyncStorage, autoRefreshToken: true } },
);
```

## CRUD Operations

```typescript
// CREATE
const { data, error } = await supabaseAdmin
  .from("daily_insights")
  .insert({ user_id: userId, card_id: cardId })
  .select()
  .single();

// READ
const { data, error } = await supabase
  .from("chat_messages")
  .select("*")
  .eq("user_id", userId)
  .order("created_at", { ascending: false })
  .limit(50);

// UPDATE
const { data, error } = await supabaseAdmin
  .from("users")
  .update({ notification_enabled: true })
  .eq("id", userId)
  .select()
  .single();

// DELETE
const { error } = await supabaseAdmin.from("users").delete().eq("id", userId);
```

## Row Level Security (RLS)

```sql
-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Users read own data
CREATE POLICY "Users can read own data"
  ON users FOR SELECT
  USING (auth.uid() = id);

-- Service role full access
CREATE POLICY "Service role full access"
  ON users FOR ALL
  USING (auth.jwt()->>'role' = 'service_role');
```

## Authentication

```typescript
// Anonymous sign-in
const { data, error } = await supabase.auth.signInAnonymously();

// Apple sign-in
const { data, error } = await supabase.auth.signInWithIdToken({
  provider: "apple",
  token: appleIdToken,
});

// Get current user
const {
  data: { user },
} = await supabase.auth.getUser(token);
```

## Error Handling

```typescript
try {
  const { data, error } = await supabase.from('table').insert({...});

  if (error) {
    // Duplicate key
    if (error.code === '23505') throw new Error('ALREADY_EXISTS');
    // Foreign key violation
    if (error.code === '23503') throw new Error('INVALID_REFERENCE');
    throw error;
  }
} catch (error: any) {
  if (error.message?.includes('Failed to fetch')) {
    return { error: 'NETWORK_ERROR' };
  }
  throw error;
}
```

## Full Reference

See `SKILL.md` for schema design, indexes, real-time subscriptions, transactions.
