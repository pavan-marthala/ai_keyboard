# Security Policy

## Supported Versions

The AI Keyboard project is currently in active pre-release development. As an early-stage open-source milestone, formal version support matrices and backported security releases are not currently maintained. Security fixes are applied directly to the `master` branch.

| Branch / Version | Supported |
| :--- | :--- |
| `master` | :white_check_mark: |
| Historical commits / tags | :x: |

---

## Reporting a Vulnerability

If you discover a security vulnerability or sensitive flaw within this repository, please disclose it responsibly.

> [!CAUTION]
> **Do NOT disclose security vulnerabilities publicly via GitHub Issues, Discussions, or Pull Requests.**

### Private Reporting Channel

Please report all security vulnerabilities via email to:
**`mgpavank@gmail.com`**

### What to Include in Your Report

To help us triage and investigate the issue efficiently, please provide:

1. **Description:** A detailed summary of the vulnerability and its potential severity.
2. **Reproduction Steps:** Step-by-step instructions, minimal proof-of-concept (PoC) code, or payload examples.
3. **Affected Components:** The relevant platform (Android, iOS, or Flutter app shell) and source files involved.
4. **Impact Assessment:** The potential risk (e.g. credential exposure, unauthorized network transmission, denial of service).

### Response & Handling Timeline

- **Acknowledgment:** We aim to acknowledge receipt of security reports within 48 to 72 hours on a best-effort basis.
- **Investigation:** The maintainers will investigate and validate the report.
- **Remediation:** If validated, a fix will be prepared and merged into `master`.

---

## Responsible Disclosure Policy

We kindly ask reporters to:

- Allow reasonable time for investigation and remediation before publicly disclosing details.
- Avoid accessing, destroying, or modifying user data without authorization during testing.
- Not perform denial-of-service (DoS) attacks against third-party AI provider endpoints.

For technical details regarding on-device cryptographic storage and data transmission, refer to our [Security & Privacy Specification](docs/security.md).
