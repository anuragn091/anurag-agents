# Security (technology agnostic)

Applies to every PR on every stack. Framework-specific enforcement lives in the platform checklists, but the questions here do not change with the language.

## Authentication and authorization
- Is identity verified correctly, and is the default deny?
- **Is authorization enforced at the trusted boundary**, meaning the server, not the UI?
- Object-level, resource-level and tenant-level permissions all checked, not just "is logged in".
- Can a user reach another user's data by guessing an identifier? Filter at the source, do not fetch then check.
- Least privilege: does this code, token, role or service account have more access than the task needs?
- Can a revoked or expired credential still be used? Where is that checked?
- Sensitive actions (password change, payout, role change, export) protected by re-authentication or a second factor.

## Input and output handling
- Every external input treated as untrusted: body, query, headers, cookies, webhooks, deep links, file names, third-party responses.
- Type, length, range, format and allowed values validated. Allowlist over denylist.
- Injection prevented at every destination: SQL, shell, template, path traversal, LDAP, header injection.
- Output encoded for where it lands. HTML, attribute, URL and JSON contexts each need different encoding.
- Uploads validated by size, declared type and **actual content**. Never trust the extension or the client-sent MIME type.
- URLs validated before a redirect or a server-side request. Open redirect and SSRF both start here.
- No unsafe deserialization of user-controlled data.

## Data protection
- Sensitive data collected and retained only where it is needed.
- Protected in transit and at rest.
- Could it leak through a response, a log line, a URL, an analytics event, a crash report or an error message?
- Secrets kept out of source, config committed to the repo, and anything shipped to a client.
- Caches and backups handled according to the sensitivity of what they hold.
- Tenant data isolated across every query and every join.
- Removed when it is no longer required.

## Sessions and credentials
- Sessions created, stored, rotated and invalidated correctly.
- Cookies and tokens configured securely: `HttpOnly`, `Secure`, `SameSite`, sane expiry, rotation on privilege change.
- Credential recovery and reset flows protected against enumeration and token reuse.
- Replay considered: can a captured request be sent again to useful effect?
- If one token leaks, how much does it expose and for how long?
- Logout invalidates sensitive state on both sides, including cached and persisted data.
- Credentials never in logs or telemetry.

## Abuse and business logic
- Can requests be replayed, reordered, or submitted concurrently to break an invariant?
- Can a user skip a workflow step by calling the later endpoint directly?
- **Mass assignment:** can a restricted field (role, price, status, owner) be set through a normal update?
- Rate limiting on expensive and sensitive operations.
- Can automation or enumeration reveal protected information, including through timing or error-message differences?
- Financial, quota, inventory and permission invariants enforced server side, in the database where possible.
- Administrative actions auditable, with who, what and when.

## Dependencies and integrations
- Is the new dependency necessary, maintained, and appropriately sized? What does it pull in?
- Known vulnerabilities checked, versions pinned or locked.
- Webhook signatures verified, with replay protection.
- Outbound requests restricted to expected destinations.
- External calls authenticated and timed out.
- Third-party failure handled without leaking internals into an error surfaced to the user.

## Deployment and observability
- Security-relevant actions logged, without recording the secret itself.
- Suspicious behavior detectable and investigable after the fact.
- Configuration defaults secure. Debug modes, verbose errors and dev-only routes disabled in production.
- The change can be disabled or rolled back quickly.
- Migration and deployment ordering safe.
- **Failure defaults to a secure state.** An error in the permission check must deny, never allow.
