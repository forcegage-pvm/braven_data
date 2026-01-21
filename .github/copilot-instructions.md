# braven_data Development Guidelines

Last updated: 2026-01-21

## Active Technologies

- Dart 3.10+ (Pure Dart only)
- Standard Dart libraries: `dart:core`, `dart:math`, `dart:typed_data`, `dart:collection`
- In-memory columnar buffers: `Float64List`, `Int64List`
- No Flutter SDK, no UI dependencies, no third-party packages unless explicitly approved

## Project Structure

```
lib/
   braven_data.dart
   src/
test/
data/
specs/
```

## Commands

```bash
dart pub get
dart analyze
dart test
dart format .
```

## Code Style

- Follow Dart official style guide and formatter output.
- Prefer immutable data structures and typed data for performance.
- Avoid unnecessary allocations in hot loops.

<!-- MANUAL ADDITIONS START -->

## YOU TOUCH IT, YOU OWN IT - ZERO TOLERANCE POLICY 🚫

### ⛔ NO "PRE-EXISTING" EXCUSES - EVER

When you CREATE or MODIFY any file, **ALL** issues in that file become YOUR responsibility:

- ❌ "These are pre-existing issues" - **REJECTED**
- ❌ "This warning was already there" - **REJECTED**
- ❌ "I only changed lines 100-150, the issue is on line 200" - **REJECTED**
- ❌ "It's just a deprecation warning" - **REJECTED**

### ✅ WHAT YOU MUST DO

1. Run `dart analyze` on EVERY file you touched
2. Fix **ALL** issues: errors, warnings, AND infos
3. Analyzer must show **"No issues found!"** for each file
4. Only then can you signal completion

### WHY THIS EXISTS

"Pre-existing" is just passing the buck. If technical debt exists in a file and you touch that file, you inherit that debt. Clean it up or don't touch the file.

### CONSEQUENCE OF VIOLATION

Your completion signal will be **REJECTED** and you will be required to fix ALL issues before re-submission.

---

## Documentation Naming Policy (MANDATORY)

- **All documentation filenames must be lowercase only** (no uppercase letters).
- Use `snake_case` for multi-word filenames.
- If you create, rename, or move a document, **update every internal link** that references it.
- If any uppercase-named doc exists, **rename it to lowercase and fix links immediately**.

---

## Terminal Management Protocol (CRITICAL - MANDATORY ENFORCEMENT)

### 🎯 ABSOLUTE RULES - ZERO TOLERANCE

**NEVER use `run_in_terminal` - ALWAYS use `terminal-tools_sendCommand` with named terminals**

### Terminal Naming Convention

**LONG-RUNNING TERMINALS** (LOCKED - Never reuse for other commands):

- `dev-server` - Development servers (npm, python, cargo)
- `test-watch` - Test runners in watch mode
- `docker-compose` - Container services
- `database` - Database servers/clients

**SHORT-LIVED TERMINALS** (Reusable after command completes):

- `git` - Version control operations
- `package-manager` - Dependency management (pub get, npm install, pip install)
- `build` - One-shot build operations
- `test` - One-shot test execution
- `general` - File operations, utilities
- `scripts` - Custom scripts/automation
- `cloud` - Cloud CLI commands

### Dart Command Guidance

Use the `package-manager` terminal for dependency operations and `test` for test runs:

```typescript
terminal-tools_sendCommand(terminalName: "package-manager", command: "dart pub get")
terminal-tools_sendCommand(terminalName: "test", command: "dart test")
terminal-tools_sendCommand(terminalName: "build", command: "dart analyze")
```

### **Pre-Command Checklist**

Before EVERY terminal command:

1. ✅ Am I using `terminal-tools_sendCommand` (NOT `run_in_terminal`)?
2. ✅ Is the terminal name explicit and category-appropriate?
3. ✅ For long-running processes, am I capturing output with `Tee-Object` so I can read it later?

### Common Mistakes to AVOID

❌ `run_in_terminal("git status")` - Never use it
❌ `terminal-tools_sendCommand(terminalName: "build", command: "flutter analyze")` - Flutter is not used here
✅ `terminal-tools_sendCommand(terminalName: "git", command: "git status")`
✅ `terminal-tools_sendCommand(terminalName: "build", command: "dart analyze")`

## Visual Verification

This project is a Dart data package (no UI). Visual verification is not required unless explicitly requested by a task.
**For capturing screenshots:**

1. ✅ Am I using `flutter_agent.py`? (NOT terminal commands)
2. ✅ Am I starting in a SEPARATE window via `Start-Process`?
3. ✅ Did I wait for the app to be ready?
4. ✅ Did I take a screenshot?
5. ✅ Did I stop the app when done?

**For viewing screenshots:**

1. ✅ Did I verify the screenshot file EXISTS first?
2. ✅ Did I use `mcp_chrome-devtoo_new_page` with `file:///` URL?
3. ✅ Did I use `mcp_chrome-devtoo_take_screenshot` to receive the image?
4. ✅ Did I analyze the image content against verification criteria?
5. ✅ Did I close the browser page when done?

<!-- MANUAL ADDITIONS END -->

```

```
