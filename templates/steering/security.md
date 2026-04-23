# STEERING: Security Requirements
# Static template — project-agnostic rules
# Read by: Security Analyst, Architect, Backend Developer, Frontend Developer

---

## NON-NEGOTIABLE RULES

1. No credentials in code — always environment variables
2. No sensitive data in API responses (passwords, full tokens)
3. All user input must be validated server-side — client validation is UX only
4. No string concatenation in database queries — use parameterized queries or ORM
5. No `eval()` or equivalent without explicit sanitization
6. API endpoints must validate request body shape before processing
7. Failed auth must not reveal whether username or password was wrong

## AUTHENTICATION

- Session tokens: secure httpOnly cookies — never localStorage
- Token expiry must be enforced server-side
- Refresh token rotation must be implemented if used

## INPUT VALIDATION

- Validate type, length, format for all user inputs
- Reject requests with unexpected extra fields
- File uploads: validate type and size server-side

## DATA EXPOSURE

- API responses must include only fields the client needs
- Never return password hashes, internal tokens, or system metadata
- Paginate list responses — never return unbounded arrays

## SEVERITY LEVELS

| Level  | Action |
|--------|--------|
| HIGH   | Must fix before sprint closes — sprint is BLOCKED |
| MEDIUM | Should fix now, does not block |
| LOW    | Log as tech debt in completed-sprints.md |

---

NOTE: Project-specific security rules (compliance requirements, specific libraries,
known vulnerabilities) should be added to `.agent-squad/steering/security.md`
in the project after initialization.
