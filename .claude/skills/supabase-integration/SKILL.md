---
name: supabase-integration
description: Best practices for Supabase database integration including schema design, Row Level Security (RLS), auth, real-time subscriptions, and TypeScript types. Use when working with Supabase PostgreSQL database.
---

# Supabase Integration Skill

This skill provides patterns and best practices for working with Supabase in the Daily Micro-Coach project.

## Core Principles

1. **Security First**: Always use Row Level Security (RLS)
2. **Type Safety**: Generate TypeScript types from schema
3. **Connection Management**: Reuse client instances
4. **Error Handling**: Graceful degradation
5. **Performance**: Use indexes, pagination, caching

## Setup & Configuration

### Client Initialization (Backend)

```typescript
// backend/lib/supabase.ts
import { createClient } from "@supabase/supabase-js";
import type { Database } from "../types/database";

// Use service role key for admin operations
const supabaseAdmin = createClient<Database>(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  },
);

// Use anon key for user operations
const supabaseClient = createClient<Database>(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_ANON_KEY!,
);

export { supabaseAdmin, supabaseClient };
```

### Client Initialization (Mobile)

```typescript
// mobile-app/src/services/supabase.ts
import AsyncStorage from "@react-native-async-storage/async-storage";
import { createClient } from "@supabase/supabase-js";
import type { Database } from "../types/database";

const supabase = createClient<Database>(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_ANON_KEY!,
  {
    auth: {
      storage: AsyncStorage,
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: false,
    },
  },
);

export default supabase;
```

## Schema Design

### Table Definitions

```sql
-- users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_type TEXT NOT NULL CHECK (auth_type IN ('apple', 'anonymous')),
  apple_id TEXT UNIQUE,

  -- Onboarding data
  gender TEXT CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
  age INTEGER CHECK (age >= 13 AND age <= 120),
  goals TEXT[],

  -- Subscription (mock in free tier)
  subscription_status TEXT NOT NULL DEFAULT 'free'
    CHECK (subscription_status IN ('free', 'premium_mock')),

  -- Usage tracking
  daily_message_count INTEGER DEFAULT 0,
  last_message_date DATE,

  -- Notifications (mock)
  notification_enabled BOOLEAN DEFAULT false,
  notification_time TEXT, -- HH:MM format

  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- Indexes
CREATE INDEX idx_users_auth_type ON users(auth_type);
CREATE INDEX idx_users_apple_id ON users(apple_id);
CREATE INDEX idx_users_created_at ON users(created_at DESC);
```

### daily_insights table

```sql
CREATE TABLE daily_insights (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  card_id TEXT NOT NULL,
  insight_date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- One insight per user per day
  UNIQUE(user_id, insight_date)
);

-- Indexes
CREATE INDEX idx_daily_insights_user_date ON daily_insights(user_id, insight_date DESC);
CREATE INDEX idx_daily_insights_created ON daily_insights(created_at);

-- Auto-cleanup old insights (>7 days)
CREATE OR REPLACE FUNCTION cleanup_old_insights()
RETURNS void AS $$
BEGIN
  DELETE FROM daily_insights
  WHERE insight_date < CURRENT_DATE - INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql;
```

### chat_messages table

```sql
CREATE TABLE chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL CHECK (LENGTH(content) <= 2000),
  selected_card_ids TEXT[], -- For assistant messages
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_chat_messages_user ON chat_messages(user_id, created_at DESC);

-- Auto-cleanup old messages (>30 days)
CREATE OR REPLACE FUNCTION cleanup_old_messages()
RETURNS void AS $$
BEGIN
  DELETE FROM chat_messages
  WHERE created_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;
```

## Row Level Security (RLS)

### Enable RLS

```sql
-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
```

### Users Policies

```sql
-- Users can read their own data
CREATE POLICY "Users can read own data"
  ON users FOR SELECT
  USING (auth.uid() = id);

-- Users can update their own data
CREATE POLICY "Users can update own data"
  ON users FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Service role can do anything (for admin operations)
CREATE POLICY "Service role full access"
  ON users FOR ALL
  USING (auth.jwt()->>'role' = 'service_role');
```

### Daily Insights Policies

```sql
-- Users can read their own insights
CREATE POLICY "Users can read own insights"
  ON daily_insights FOR SELECT
  USING (auth.uid() = user_id);

-- Service role can insert insights
CREATE POLICY "Service role can insert insights"
  ON daily_insights FOR INSERT
  WITH CHECK (auth.jwt()->>'role' = 'service_role');

-- Service role can delete old insights
CREATE POLICY "Service role can delete insights"
  ON daily_insights FOR DELETE
  USING (auth.jwt()->>'role' = 'service_role');
```

### Chat Messages Policies

```sql
-- Users can read their own messages
CREATE POLICY "Users can read own messages"
  ON chat_messages FOR SELECT
  USING (auth.uid() = user_id);

-- Service role can insert messages
CREATE POLICY "Service role can insert messages"
  ON chat_messages FOR INSERT
  WITH CHECK (auth.jwt()->>'role' = 'service_role');
```

## Authentication

### Anonymous Auth

```typescript
// Create anonymous user
const createAnonymousUser = async () => {
  // Sign in anonymously with Supabase
  const { data: authData, error: authError } =
    await supabase.auth.signInAnonymously();

  if (authError) throw authError;

  // Create user record
  const { data: userData, error: userError } = await supabaseAdmin
    .from("users")
    .insert({
      id: authData.user.id,
      auth_type: "anonymous",
    })
    .select()
    .single();

  if (userError) throw userError;

  return { user: userData, session: authData.session };
};
```

### Apple Sign-In

```typescript
// Authenticate with Apple
const signInWithApple = async (appleIdToken: string, appleUserId: string) => {
  // Verify Apple token with Supabase
  const { data: authData, error: authError } =
    await supabase.auth.signInWithIdToken({
      provider: "apple",
      token: appleIdToken,
    });

  if (authError) throw authError;

  // Check if user exists
  const { data: existingUser } = await supabaseAdmin
    .from("users")
    .select("*")
    .eq("apple_id", appleUserId)
    .single();

  if (existingUser) {
    // Update last active
    await supabaseAdmin
      .from("users")
      .update({ last_active_at: new Date().toISOString() })
      .eq("id", existingUser.id);

    return { user: existingUser, isNewUser: false };
  }

  // Create new user
  const { data: newUser, error: userError } = await supabaseAdmin
    .from("users")
    .insert({
      id: authData.user.id,
      auth_type: "apple",
      apple_id: appleUserId,
    })
    .select()
    .single();

  if (userError) throw userError;

  return { user: newUser, isNewUser: true };
};
```

## CRUD Operations

### Create

```typescript
// Insert daily insight
const createDailyInsight = async (userId: string, cardId: string) => {
  const { data, error } = await supabaseAdmin
    .from("daily_insights")
    .insert({
      user_id: userId,
      card_id: cardId,
      insight_date: new Date().toISOString().split("T")[0], // YYYY-MM-DD
    })
    .select()
    .single();

  if (error) {
    // Handle duplicate (user already has insight for today)
    if (error.code === "23505") {
      throw new Error("INSIGHT_ALREADY_EXISTS");
    }
    throw error;
  }

  return data;
};
```

### Read (with pagination)

```typescript
// Get chat history with pagination
const getChatHistory = async (
  userId: string,
  limit: number = 50,
  offset: number = 0,
) => {
  const { data, error, count } = await supabase
    .from("chat_messages")
    .select("*", { count: "exact" })
    .eq("user_id", userId)
    .order("created_at", { ascending: false })
    .range(offset, offset + limit - 1);

  if (error) throw error;

  return { messages: data, total: count };
};
```

### Update

```typescript
// Update user profile
const updateUserProfile = async (
  userId: string,
  updates: Partial<Database["public"]["Tables"]["users"]["Update"]>,
) => {
  const { data, error } = await supabaseAdmin
    .from("users")
    .update(updates)
    .eq("id", userId)
    .select()
    .single();

  if (error) throw error;

  return data;
};
```

### Delete (with cascade)

```typescript
// Delete user (cascades to all related data)
const deleteUser = async (userId: string) => {
  const { error } = await supabaseAdmin.from("users").delete().eq("id", userId);

  if (error) throw error;

  return { success: true };
};
```

## Real-time Subscriptions (Optional)

```typescript
// Subscribe to new messages in chat
const subscribeToMessages = (
  userId: string,
  callback: (message: any) => void,
) => {
  const subscription = supabase
    .channel("chat-messages")
    .on(
      "postgres_changes",
      {
        event: "INSERT",
        schema: "public",
        table: "chat_messages",
        filter: `user_id=eq.${userId}`,
      },
      (payload) => {
        callback(payload.new);
      },
    )
    .subscribe();

  return () => {
    subscription.unsubscribe();
  };
};
```

## Error Handling

```typescript
// Wrapper for Supabase operations
const handleSupabaseError = (error: any) => {
  // PostgreSQL error codes
  const ERROR_CODES = {
    "23505": "DUPLICATE_KEY",
    "23503": "FOREIGN_KEY_VIOLATION",
    "23502": "NOT_NULL_VIOLATION",
    "23514": "CHECK_VIOLATION",
  };

  if (error.code in ERROR_CODES) {
    return {
      type: ERROR_CODES[error.code as keyof typeof ERROR_CODES],
      message: error.message,
    };
  }

  // Network errors
  if (error.message?.includes("Failed to fetch")) {
    return {
      type: "NETWORK_ERROR",
      message: "Could not connect to database",
    };
  }

  // Generic error
  return {
    type: "DATABASE_ERROR",
    message: error.message,
  };
};

// Usage
try {
  const user = await createUser(data);
} catch (error) {
  const { type, message } = handleSupabaseError(error);

  if (type === "DUPLICATE_KEY") {
    // Handle duplicate user
  } else if (type === "NETWORK_ERROR") {
    // Handle network issue
  } else {
    // Generic error
  }
}
```

## TypeScript Type Generation

```bash
# Generate types from Supabase schema
npx supabase gen types typescript --project-id <project-id> > types/database.ts
```

```typescript
// types/database.ts (auto-generated)
export type Database = {
  public: {
    Tables: {
      users: {
        Row: {
          id: string;
          auth_type: "apple" | "anonymous";
          // ... all fields
        };
        Insert: {
          id?: string;
          auth_type: "apple" | "anonymous";
          // ... all fields (some optional)
        };
        Update: {
          id?: string;
          // ... all fields optional
        };
      };
      // ... other tables
    };
  };
};
```

## Performance Optimization

### Use Indexes

```sql
-- Always index foreign keys
CREATE INDEX idx_daily_insights_user_id ON daily_insights(user_id);

-- Index frequently filtered columns
CREATE INDEX idx_users_subscription_status ON users(subscription_status);

-- Composite indexes for common queries
CREATE INDEX idx_chat_messages_user_role ON chat_messages(user_id, role, created_at DESC);
```

### Connection Pooling

```typescript
// Reuse client instances (don't create new ones per request)
// ✅ Good: Single instance
const supabase = createClient(...);

// ❌ Bad: New instance per request
function handler(req, res) {
  const supabase = createClient(...); // Don't do this!
}
```

### Pagination

```typescript
// Always paginate large result sets
const PAGE_SIZE = 50;

const getMessages = async (page: number = 0) => {
  const { data, error } = await supabase
    .from("chat_messages")
    .select("*")
    .range(page * PAGE_SIZE, (page + 1) * PAGE_SIZE - 1);

  return data;
};
```

## Common Patterns

### Upsert (Insert or Update)

```typescript
// Update or insert daily insight
const upsertDailyInsight = async (userId: string, cardId: string) => {
  const { data, error } = await supabaseAdmin
    .from("daily_insights")
    .upsert(
      {
        user_id: userId,
        card_id: cardId,
        insight_date: new Date().toISOString().split("T")[0],
      },
      {
        onConflict: "user_id,insight_date",
      },
    )
    .select()
    .single();

  if (error) throw error;
  return data;
};
```

### Transactions (via RPC)

```sql
-- Create stored procedure for atomic operations
CREATE OR REPLACE FUNCTION create_user_with_profile(
  p_auth_type TEXT,
  p_apple_id TEXT DEFAULT NULL
)
RETURNS users AS $$
DECLARE
  v_user users;
BEGIN
  -- Insert user
  INSERT INTO users (auth_type, apple_id)
  VALUES (p_auth_type, p_apple_id)
  RETURNING * INTO v_user;

  -- Insert default settings (if needed)
  -- INSERT INTO user_settings ...

  RETURN v_user;
END;
$$ LANGUAGE plpgsql;
```

```typescript
// Call from code
const { data, error } = await supabaseAdmin.rpc("create_user_with_profile", {
  p_auth_type: "apple",
  p_apple_id: appleUserId,
});
```

## Quality Checklist

- [ ] All tables have RLS enabled
- [ ] All policies tested (can't access other users' data)
- [ ] Indexes on all foreign keys
- [ ] Indexes on frequently filtered columns
- [ ] TypeScript types generated from schema
- [ ] Error handling for all operations
- [ ] Connection pooling (reuse clients)
- [ ] Pagination for large queries
- [ ] Triggers for updated_at columns
- [ ] Constraints for data validation
- [ ] Cleanup functions for old data

## Common Mistakes

❌ **Don't:**

- Disable RLS for convenience
- Use service role key in frontend
- Create new client per request
- Forget indexes on foreign keys
- Return 1000+ rows without pagination
- Store sensitive data in plain text
- Skip TypeScript types

✅ **Do:**

- Always use RLS
- Use anon key in frontend, service key in backend
- Reuse client instances
- Index all foreign keys and filtered columns
- Paginate large result sets
- Encrypt sensitive data
- Generate and use TypeScript types

## Resources

- **Supabase Docs:** https://supabase.com/docs
- **RLS Guide:** https://supabase.com/docs/guides/auth/row-level-security
- **Type Generation:** https://supabase.com/docs/guides/api/generating-types
- **Best Practices:** https://supabase.com/docs/guides/database/best-practices

## When to Use This Skill

Use when:

- Creating database schema
- Writing RLS policies
- Implementing CRUD operations
- Setting up authentication
- Optimizing queries
- Handling errors
- Generating TypeScript types
