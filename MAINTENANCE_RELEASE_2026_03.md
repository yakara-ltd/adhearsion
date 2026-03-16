# Maintenance Release - March 2026

## Security Fixes

This document tracks the security remediation work performed on 2026-03-16,
addressing critical and high severity findings from the security review.

---

### CRITICAL #1: Shell Injection in `plugin_command.rb`

**File:** `lib/adhearsion/cli_commands/plugin_command.rb`
**Status:** Fixed (commit a5d75b4f)

**Issue:** Environment variables `RUBYGEM_AUTH` and `RUBYGEM_NAME` were interpolated
directly into a shell command executed via backticks. A malicious value like
`'; rm -rf / #` would execute arbitrary commands.

**Fix:** Replaced backtick shell execution with `Net::HTTP` POST request.
Also updated the RubyGems webhook callback URL from `http://` to `https://`.

**Test:** `spec/adhearsion/cli_commands/plugin_command_spec.rb` — verifies
`Kernel#\`` is never called and Net::HTTP is used instead.

---

### CRITICAL #2: Unsafe YAML Deserialization in `i18n.rb`

**File:** `lib/adhearsion/tasks/i18n.rb`
**Status:** Fixed (commit 6304b247)

**Issue:** `YAML.load` can instantiate arbitrary Ruby objects, enabling remote code
execution if locale files come from an untrusted source.

**Fix:** Replaced both `YAML.load` calls with `YAML.safe_load` with
`permitted_classes: [Symbol]`.

**Test:** `spec/adhearsion/tasks/i18n_task_security_spec.rb` — source-level scan
verifying no `YAML.load` calls remain and `YAML.safe_load` is present.

---

### HIGH #3: Hardcoded Default Credentials

**File:** `lib/adhearsion/configuration.rb`, `lib/adhearsion/rayo/initializer.rb`
**Status:** Fixed (commit 9ce4de1d)

**Issue:** Default username `usera@127.0.0.1` and password `1` ship with the library.
Operators who deploy without changing these have an effectively unauthenticated connection.

**Fix:** Added `Configuration.warn_if_default_credentials!` which emits a prominent
warning at startup (during Rayo initialization) when defaults are detected.

**Test:** `spec/adhearsion/configuration_security_spec.rb` — verifies warning is
emitted with defaults and suppressed with custom credentials.

---

### HIGH #4: HTTP Server Binds to 0.0.0.0

**File:** `lib/adhearsion/configuration.rb`
**Status:** Fixed (commit ed428d53)

**Issue:** The HTTP server listened on all interfaces (`0.0.0.0`) by default, exposing
the Rack application to the network without authentication.

**Fix:** Changed default bind address to `127.0.0.1`. Operators who need external
access can explicitly set `config.core.http.host = "0.0.0.0"`.

**Test:** `spec/adhearsion/http_server_security_spec.rb` — verifies default is
`127.0.0.1`.

---

### HIGH #5: Plaintext Password Handling in CLI

**File:** `lib/adhearsion/cli_commands/plugin_command.rb`
**Status:** Fixed (commit 6b7873bc)

**Issue:** Passwords collected via `ask()` with no input masking and stored in ENV,
visible on screen, in shell history, and via `/proc/*/environ`.

**Fix:** Added `ask_secret` method using `$stdin.noecho` for masked input. All
password/token/auth prompts now use this method.

**Test:** `spec/adhearsion/cli_commands/plugin_command_spec.rb` — source-level scan
verifying no `ask` calls are used for sensitive prompts.

---

### HIGH #6: GitHub Basic Auth + HTTP Webhook URL

**File:** `lib/adhearsion/cli_commands/plugin_command.rb`
**Status:** Fixed (commit 6b7873bc, same commit as #5)

**Issue:** Used deprecated GitHub password-based basic auth. Webhook config URL used
plain HTTP (`http://ahnhub.com/github`), leaking events over cleartext.

**Fix:** Switched from `basic_auth` with username+password to token-based
`Authorization: token <PAT>` header. Renamed `GITHUB_PASSWORD` env var to
`GITHUB_TOKEN`. Webhook URL changed to `https://ahnhub.com/github`.

**Test:** `spec/adhearsion/cli_commands/plugin_command_spec.rb` — verifies
Authorization header uses `token ` prefix and webhook URL starts with `https://`.

---

## Summary

| # | Severity | Issue | Status |
|---|----------|-------|--------|
| 1 | CRITICAL | Shell injection via backticks | Fixed |
| 2 | CRITICAL | Unsafe YAML.load deserialization | Fixed |
| 3 | HIGH | Hardcoded default credentials | Fixed |
| 4 | HIGH | HTTP server bound to 0.0.0.0 | Fixed |
| 5 | HIGH | Plaintext password prompts | Fixed |
| 6 | HIGH | GitHub basic auth + HTTP URLs | Fixed |

All fixes include regression tests. Run the full security test suite with:

```
bundle exec rspec spec/adhearsion/cli_commands/plugin_command_spec.rb \
  spec/adhearsion/tasks/i18n_task_security_spec.rb \
  spec/adhearsion/configuration_security_spec.rb \
  spec/adhearsion/http_server_security_spec.rb
```
