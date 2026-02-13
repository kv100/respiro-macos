---
name: build-verify
description: Build the project and verify code quality
user_invocable: true
---

# Build & Verify

Run the standard build and verification pipeline for Respiro macOS.

## Steps

1. **Build the project:**

```bash
cd /Users/kostiantyn.vlasenko/Projects/respiro-macos && xcodebuild -scheme RespiroDesktop -destination 'platform=macOS' build 2>&1 | tail -20
```

2. **Check for wrong AI models:**

```bash
grep -rE "gpt-[0-9]|openai|sonnet" RespiroDesktop/ --include="*.swift" | grep -v "// " | grep -v "QUICKREF"
```

3. **Check for iOS-only APIs:**

```bash
grep -rE "UIImage|UIScreen|UIKit|UIView" RespiroDesktop/ --include="*.swift"
```

4. **Check for force unwraps:**

```bash
grep -rn "!" RespiroDesktop/ --include="*.swift" | grep -v "IBOutlet" | grep -v "//" | grep -v "\"" | grep -v "try!" | head -20
```

5. **Git status:**

```bash
git diff --stat
```

Report results as:

- BUILD: PASS/FAIL
- AI MODEL: OK/ISSUES
- iOS APIs: OK/ISSUES
- Force unwraps: count
- Changed files: list
