# Maintenance Release - March 2026

## Security Fixes

This document tracks the security remediation work performed on 2026-03-16,
addressing all findings from the security review.

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

### MEDIUM #7: Dynamic `eval` on Block Bindings

**Files:** `lib/adhearsion/call_controller/input/menu_builder.rb`, `lib/adhearsion/call_controller.rb`
**Status:** Fixed (commit dade9b70)

**Issue:** `eval "self", block.binding` is fragile and could become an RCE vector
if untrusted strings are ever passed.

**Fix:** Replaced with `block.binding.receiver` (safe, direct Ruby API since 2.6+).

**Test:** `spec/adhearsion/eval_security_spec.rb` — source-level scan verifying
no `eval "self"` calls remain.

---

### MEDIUM #8: `method_missing` + `send` Proxy Pattern

**Files:** `call_controller.rb`, `menu_builder.rb`, `calls.rb`, `console.rb`, `events.rb`, `thread_safety.rb`, `configuration.rb`
**Status:** Fixed (commit 1bcddf44)

**Issue:** Unconstrained `send` in `method_missing` proxies allows calling
private/protected methods on the target object.

**Fix:** Replaced `.send` with `.public_send` across all 7 files.

**Test:** `spec/adhearsion/method_missing_security_spec.rb` — source-level scan
of all 7 files verifying no `.send` calls remain (excluding `public_send`/`__send__`).

---

### MEDIUM #9: Sensitive Data in INFO Logs

**File:** `lib/adhearsion/call_controller/input/menu_builder.rb`
**Status:** Fixed (commit 40b3f041)

**Issue:** User utterances (DTMF digits, speech) logged at INFO level. If users
enter PINs, credit card numbers, or SSNs, these end up in plaintext production logs.

**Fix:** Split the log line: status at INFO, utterance/interpretation at DEBUG only.

**Test:** `spec/adhearsion/log_redaction_security_spec.rb` — verifies no
utterance/interpretation data is logged at INFO level.

---

### MEDIUM #10: Nokogiri XML Parsing — NONET Flag

**File:** `lib/adhearsion/rayo/component/input.rb`
**Status:** Fixed (commit 44108eb4)

**Issue:** Nokogiri XML parsing used only `NOBLANKS` without `NONET`, allowing
potential network requests during parsing (XXE defense-in-depth).

**Fix:** Added `NONET` flag alongside `NOBLANKS` to prevent network access.

**Test:** `spec/adhearsion/nokogiri_security_spec.rb` — verifies NONET flag
is present in all Nokogiri::XML.parse calls.

---

### LOW #11: Thread Safety with Class Variables

**File:** `lib/adhearsion/plugin.rb`
**Status:** Fixed (commit 86a486b4)

**Issue:** `@@rake_tasks` class variable modified without synchronization, creating
a race condition if plugins are loaded from multiple threads.

**Fix:** Added `@@rake_tasks_mutex` to protect all reads and writes to `@@rake_tasks`.

**Test:** `spec/adhearsion/plugin_thread_safety_spec.rb` — verifies mutex is present.

---

### LOW #12: No TLS Enforcement by Default

**File:** `lib/adhearsion/configuration.rb`, `lib/adhearsion/rayo/initializer.rb`
**Status:** Fixed (commit ab69a38f)

**Issue:** `certs_directory` defaults to `nil`, meaning connections to Asterisk/XMPP
servers are unencrypted unless explicitly configured.

**Fix:** Added `Configuration.warn_if_no_tls!` which emits a warning at startup
when TLS is not configured. Called during Rayo initialization.

**Test:** `spec/adhearsion/tls_security_spec.rb` — verifies warning is emitted
when certs_directory is nil and suppressed when configured.

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
| 7 | MEDIUM | eval on block bindings | Fixed |
| 8 | MEDIUM | send in method_missing proxies | Fixed |
| 9 | MEDIUM | Sensitive data in INFO logs | Fixed |
| 10 | MEDIUM | Nokogiri NONET flag missing | Fixed |
| 11 | LOW | Thread safety with class variables | Fixed |
| 12 | LOW | No TLS enforcement by default | Fixed |

All 12 fixes include regression tests (23 test examples total).

Run the full security test suite with:

```
bundle exec rspec \
  spec/adhearsion/cli_commands/plugin_command_spec.rb \
  spec/adhearsion/tasks/i18n_task_security_spec.rb \
  spec/adhearsion/configuration_security_spec.rb \
  spec/adhearsion/http_server_security_spec.rb \
  spec/adhearsion/eval_security_spec.rb \
  spec/adhearsion/method_missing_security_spec.rb \
  spec/adhearsion/log_redaction_security_spec.rb \
  spec/adhearsion/nokogiri_security_spec.rb \
  spec/adhearsion/plugin_thread_safety_spec.rb \
  spec/adhearsion/tls_security_spec.rb
```
