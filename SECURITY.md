# Security Policy

## Security Policy Statement
We take the security of AI Keyboard seriously. This document outlines our security policies and procedures for reporting vulnerabilities.

## Reporting Vulnerabilities
If you discover a security vulnerability in this project, please report it privately.

**Do NOT disclose vulnerabilities publicly via GitHub Issues.**

Instead, please send an email to: **mgpavank@gmail.com**

Please include the following information in your report:
- A detailed description of the vulnerability.
- Steps to reproduce the issue.
- An assessment of the potential impact.

Expected response time: Best effort. Please keep in mind that this is an open-source project maintained by volunteers.

## API Key Handling
- Users provide their own AI provider API keys.
- Keys are securely stored using platform-specific secure storage (Android KeyStore / iOS Keychain).
- Keys are **NEVER** committed to version control.
- Contributors must ensure they never hardcode secrets or API keys in the source code.

## Data Handling
- AI text transformations are processed by sending data to third-party API endpoints configured by the user.
- Users should be aware that their text is transmitted to their chosen AI provider for processing.
- No telemetry, analytics, or usage data is collected by the AI Keyboard app.

## Responsible Disclosure Guidance
We ask that you follow responsible disclosure guidelines. Please give us a reasonable amount of time to investigate and patch the vulnerability before disclosing it publicly. We will work with you to resolve the issue as quickly as possible.
