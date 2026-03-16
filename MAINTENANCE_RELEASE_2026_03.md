# Maintenance Release - March 2026

## Security Fixes

This document tracks the security remediation work performed in March 2026,
addressing critical and high severity findings from the security review.

---

### CRITICAL #1: Shell Injection in `plugin_command.rb`

**File:** `lib/adhearsion/cli_commands/plugin_command.rb:29-32`
**Status:** In Progress

**Issue:** Environment variables `RUBYGEM_AUTH` and `RUBYGEM_NAME` are interpolated
directly into a shell command executed via backticks. A malicious value like
`'; rm -rf / #` would execute arbitrary commands.

**Fix:** Replace backtick shell execution with `Net::HTTP` (already used elsewhere
in the same file for the GitHub webhook).

---

### CRITICAL #2: Unsafe YAML Deserialization in `i18n.rb`

**File:** `lib/adhearsion/tasks/i18n.rb:16,61`
**Status:** Pending

**Issue:** `YAML.load` can instantiate arbitrary Ruby objects, enabling remote code
execution if locale files come from an untrusted source.

**Fix:** Replace `YAML.load` with `YAML.safe_load` with `permitted_classes` as needed.

---

### HIGH #3: Hardcoded Default Credentials

**File:** `lib/adhearsion/configuration.rb:72-73`
**Status:** Pending

**Issue:** Default username `usera@127.0.0.1` and password `1` ship with the library.
Operators who deploy without changing these have an effectively unauthenticated connection.

**Fix:** Emit a prominent warning at startup when default credentials are detected in
production environments.

---

### HIGH #4: HTTP Server Binds to 0.0.0.0

**File:** `lib/adhearsion/configuration.rb:114`
**Status:** Pending

**Issue:** The HTTP server listens on all interfaces by default, exposing the Rack
application to the network without authentication.

**Fix:** Change default bind address to `127.0.0.1`.

---

### HIGH #5: Plaintext Password Handling in CLI

**File:** `lib/adhearsion/cli_commands/plugin_command.rb:45,50`
**Status:** Pending

**Issue:** Passwords collected via `ask()` with no input masking and stored in ENV,
visible to child processes and `/proc/*/environ`.

**Fix:** Use `IO.console.getpass` for password/secret prompts.

---

### HIGH #6: GitHub Basic Auth + HTTP Webhook URL

**File:** `lib/adhearsion/cli_commands/plugin_command.rb:65-73`
**Status:** Pending

**Issue:** Uses deprecated GitHub password-based basic auth. Webhook config URL uses
plain HTTP (`http://ahnhub.com/github`), leaking events over cleartext.

**Fix:** Switch to token-based auth and HTTPS webhook URL.
