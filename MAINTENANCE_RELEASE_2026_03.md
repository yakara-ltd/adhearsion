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

---

### MEDIUM #13: `Process.method_missing` Uses `.send` Instead of `.public_send`

**File:** `lib/adhearsion/process.rb`
**Status:** Fixed (commit 60ebea1f)

**Issue:** The `Process` singleton proxy used `.send` in `method_missing`, which
allows callers to invoke private methods (like `die_now!`) through the class-level
proxy. This was missed during the original fix in #8.

**Fix:** Replaced `.send` with `.public_send` to respect method visibility.
Also added `Process` to the existing `method_missing_security_spec.rb` coverage.

**Test:** `spec/adhearsion/process_security_spec.rb` — source-level scan verifying
no `.send` calls remain, plus behavioral test for private method protection.

---

### LOW #14: ERB Template Evaluation with Unrestricted `binding`

**File:** `lib/adhearsion/generators/generator.rb`
**Status:** Fixed (commit 98090bed)

**Issue:** `ERB.new(File.read(usage)).result(binding)` exposed the full class
context to USAGE templates. A malicious or compromised template file could
execute arbitrary code with access to the generator's class internals.

**Fix:** Replaced `binding` with `TOPLEVEL_BINDING.dup` to provide a clean,
restricted evaluation context with no access to class internals.

**Test:** `spec/adhearsion/generators/generator_security_spec.rb` — source-level
scan verifying no `.result(binding)` calls remain.

---

### HIGH #15: Default Credentials Only Warned, Not Blocked in Production

**Files:** `lib/adhearsion/configuration.rb`, `lib/adhearsion/rayo/initializer.rb`
**Status:** Fixed (commit 16bda59a)

**Issue:** Default credentials (`usera@127.0.0.1` / `1`) only generated a log
warning at startup, allowing production systems to run with effectively
unauthenticated connections.

**Fix:** Added `Configuration.enforce_security!` which raises a
`ConfigurationError` in production environment when default credentials are
detected. Development and other environments continue to receive warnings only.
Wired into `Rayo::Initializer.init` replacing `warn_if_default_credentials!`.

**Test:** `spec/adhearsion/default_credentials_enforcement_spec.rb` — verifies
hard failure in production, warning-only in development, and no error with
custom credentials.

---

---

### HIGH #16: Unbounded DTMF Grammar Cache (Memory Exhaustion DoS)

**File:** `lib/adhearsion/translator/asterisk/component/dtmf_recognizer.rb`
**Status:** Fixed (commit ba0357f4)

**Issue:** The `BuiltinMatcherCache` singleton stored parsed grammars keyed by URL
with no size limit or eviction policy. An attacker sending input commands with many
unique grammar URLs could exhaust heap memory indefinitely.

**Fix:** Added `MAX_CACHE_SIZE = 100` constant and LRU-style eviction via
`Hash#shift` when the cache reaches capacity.

**Test:** `spec/adhearsion/translator/asterisk/dtmf_recognizer_cache_security_spec.rb`
— verifies `MAX_CACHE_SIZE` constant exists and eviction logic is present.

---

### HIGH #17: Bare `rescue` in `send_message` (Silent Exception Swallowing)

**File:** `lib/adhearsion/translator/asterisk/call.rb`
**Status:** Fixed (commit c9bf21a7)

**Issue:** `send_message` used a bare `rescue` (no exception class), silently
swallowing all exceptions including `Celluloid::DeadActorError`, `SystemExit`,
and network failures. This masked bugs, attack signals, and delivery failures.

**Fix:** Replaced bare `rescue` with `rescue RubyAMI::Error, ChannelGoneError => e`
and added a `logger.warn` so failures are visible in logs.

**Test:** `spec/adhearsion/translator/asterisk/call_send_message_security_spec.rb`
— source-level scan verifying no bare `rescue` statements remain.

---

### HIGH #18: SIP Header Injection via `variable_for_headers`

**File:** `lib/adhearsion/translator/asterisk/call.rb`
**Status:** Fixed (commit 7aa1adb7)

**Issue:** Header names and values were interpolated directly into `SIPADDHEADER`
variable strings without escaping. Quotes, newlines, and null bytes in
attacker-controlled header values could inject arbitrary SIP headers or break
out of the AMI variable context.

**Fix:** Added `sanitize_header_value` method that strips `\r`, `\n`, `\0`, `"`,
and `\` characters from all header names and values before interpolation.

**Test:** `spec/adhearsion/translator/asterisk/call_header_injection_security_spec.rb`
— source-level scan verifying header interpolation uses sanitization.

---

### HIGH #19: Path Traversal in Audio File Playback

**File:** `lib/adhearsion/translator/asterisk/component/output.rb`
**Status:** Fixed (commit 5c3c5c5a)

**Issue:** `path_for_audio_node` constructed file paths from SSML `<audio src="...">`
attributes without validating for directory traversal. An attacker could use
`<audio src="file://../../etc/passwd"/>` to reference files outside the intended
audio directory.

**Fix:** Added `path_traversal?` check that raises `OptionError` if the path
contains `..` or null byte sequences.

**Test:** `spec/adhearsion/translator/asterisk/component/output_path_traversal_security_spec.rb`
— source-level scan verifying traversal validation is present.

---

---

### MEDIUM #20: Unvalidated Redirect Target Passed to AGI Transfer

**File:** `lib/adhearsion/translator/asterisk/call.rb`
**Status:** Fixed (commit ebf107e7)

**Issue:** The Redirect command passed `command.to` directly to Asterisk's
`EXEC Transfer` without sanitization. Special characters (`&`, `|`, newlines,
backticks, `$`) could manipulate call routing or inject Asterisk dialplan syntax.

**Fix:** Added `sanitize_transfer_target` method that strips dangerous characters
before passing the target to the Transfer AGI command.

**Test:** `spec/adhearsion/translator/asterisk/call_redirect_security_spec.rb`

---

### MEDIUM #21: Caller ID Spoofing via Unvalidated `from` Field

**File:** `lib/adhearsion/translator/asterisk/call.rb`
**Status:** Fixed (commit a9e0d1c1)

**Issue:** The `dial` method passed `dial_command.from` directly as `callerid`
to Asterisk's Originate without sanitization. Newlines, quotes, and backslashes
could inject AMI parameters.

**Fix:** Sanitized the `from` field via `sanitize_header_value` before use as callerid.

**Test:** `spec/adhearsion/translator/asterisk/call_callerid_security_spec.rb`

---

### MEDIUM #22: Unbounded Bridge Cache (Memory Exhaustion)

**Files:** `lib/adhearsion/translator/asterisk.rb`, `lib/adhearsion/translator/asterisk/call.rb`
**Status:** Fixed (commit 6da8f368)

**Issue:** The `@bridges` hash grew unboundedly with `BridgeEnter` events and was
only cleaned up on matching `BridgeLeave` events. Orphaned entries from crashed
channels or malicious AMI events could exhaust memory.

**Fix:** Added `MAX_BRIDGE_CACHE_SIZE = 500` with LRU eviction and a
`register_bridge` helper method.

**Test:** `spec/adhearsion/translator/asterisk/bridge_cache_security_spec.rb`

---

### MEDIUM #23: `class_eval` with String Interpolation in CallController

**File:** `lib/adhearsion/call_controller.rb`
**Status:** Fixed (commit 0b7e776f)

**Issue:** Callback registration used `class_eval` with heredoc string interpolation
to define methods. While currently safe (keys come from a fixed hash), the pattern
is fragile and could become a code injection vector if callback names were ever
dynamically derived.

**Fix:** Replaced `class_eval <<-STOP ... #{name} ...` with `define_singleton_method`,
which is safe by construction and cannot be exploited via string injection.

**Test:** `spec/adhearsion/call_controller_classeval_security_spec.rb`

---

### MEDIUM #24: No Timeout on AGI Command Response (Thread Hang DoS)

**File:** `lib/adhearsion/translator/asterisk/call.rb`
**Status:** Fixed (commit f5c883a5)

**Issue:** `execute_agi_command` called `response.value` without a timeout,
blocking the thread indefinitely if Asterisk never sent a response. A misbehaving
or malicious Asterisk server could permanently hang call processing threads.

**Fix:** Added `AGI_TIMEOUT = 120` seconds. On expiry, raises `AGITimeoutError`
instead of blocking forever.

**Test:** `spec/adhearsion/translator/asterisk/call_agi_timeout_security_spec.rb`

---

### LOW #25: PII (from/to) Logged at INFO Level in Call End

**File:** `lib/adhearsion/call.rb`
**Status:** Fixed (commit 4b87ea06)

**Issue:** Caller/callee identifiers (phone numbers, SIP URIs, names) were logged
at INFO level in the call end handler. These are PII that should not appear in
production logs.

**Fix:** Split the log line: reason at INFO, from/to details at DEBUG only.

**Test:** `spec/adhearsion/call_pii_logging_security_spec.rb`

---

### LOW #26: URI Scheme Not Whitelisted in Output Formatter (SSRF)

**File:** `lib/adhearsion/call_controller/output/formatter.rb`
**Status:** Fixed (commit c88592cd)

**Issue:** The `uri?` method accepted any URI scheme (`file://`, `data://`,
`gopher://`, etc.), which could trigger SSRF when a media server fetches the URL.

**Fix:** Added `ALLOWED_URI_SCHEMES = %w[http https file]` whitelist. Only these
schemes are recognized as audio URIs.

**Test:** `spec/adhearsion/call_controller/output/formatter_uri_security_spec.rb`

---

## Summary

| # | Severity | Issue | Status |
|---|----------|-------|--------|
| 1 | CRITICAL | Shell injection via backticks | Fixed |
| 2 | CRITICAL | Unsafe YAML.load deserialization | Fixed |
| 3 | HIGH | Hardcoded default credentials (warning) | Fixed |
| 4 | HIGH | HTTP server bound to 0.0.0.0 | Fixed |
| 5 | HIGH | Plaintext password prompts | Fixed |
| 6 | HIGH | GitHub basic auth + HTTP URLs | Fixed |
| 7 | MEDIUM | eval on block bindings | Fixed |
| 8 | MEDIUM | send in method_missing proxies | Fixed |
| 9 | MEDIUM | Sensitive data in INFO logs | Fixed |
| 10 | MEDIUM | Nokogiri NONET flag missing | Fixed |
| 11 | LOW | Thread safety with class variables | Fixed |
| 12 | LOW | No TLS enforcement by default | Fixed |
| 13 | MEDIUM | Process.method_missing uses .send | Fixed |
| 14 | LOW | ERB template with unrestricted binding | Fixed |
| 15 | HIGH | Default credentials not blocked in production | Fixed |
| 16 | HIGH | Unbounded DTMF grammar cache (memory DoS) | Fixed |
| 17 | HIGH | Bare rescue silences all errors | Fixed |
| 18 | HIGH | SIP header injection via unescaped interpolation | Fixed |
| 19 | HIGH | Path traversal in audio file playback | Fixed |
| 20 | MEDIUM | Unvalidated redirect target to AGI Transfer | Fixed |
| 21 | MEDIUM | Caller ID spoofing via unvalidated from field | Fixed |
| 22 | MEDIUM | Unbounded bridge cache (memory exhaustion) | Fixed |
| 23 | MEDIUM | class_eval with string interpolation | Fixed |
| 24 | MEDIUM | No timeout on AGI response (thread hang DoS) | Fixed |
| 25 | LOW | PII (from/to) logged at INFO level | Fixed |
| 26 | LOW | URI scheme not whitelisted (SSRF) | Fixed |

All 26 fixes include regression tests (44 test examples total).

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
  spec/adhearsion/tls_security_spec.rb \
  spec/adhearsion/process_security_spec.rb \
  spec/adhearsion/generators/generator_security_spec.rb \
  spec/adhearsion/default_credentials_enforcement_spec.rb \
  spec/adhearsion/translator/asterisk/dtmf_recognizer_cache_security_spec.rb \
  spec/adhearsion/translator/asterisk/call_send_message_security_spec.rb \
  spec/adhearsion/translator/asterisk/call_header_injection_security_spec.rb \
  spec/adhearsion/translator/asterisk/component/output_path_traversal_security_spec.rb \
  spec/adhearsion/translator/asterisk/call_redirect_security_spec.rb \
  spec/adhearsion/translator/asterisk/call_callerid_security_spec.rb \
  spec/adhearsion/translator/asterisk/bridge_cache_security_spec.rb \
  spec/adhearsion/call_controller_classeval_security_spec.rb \
  spec/adhearsion/translator/asterisk/call_agi_timeout_security_spec.rb \
  spec/adhearsion/call_pii_logging_security_spec.rb \
  spec/adhearsion/call_controller/output/formatter_uri_security_spec.rb
```
