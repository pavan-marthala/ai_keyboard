# Design: Harden AI Transformation Prompts

## Context

See `proposal.md` for motivation. `shared/prompts/ai_prompts.json` (version 2) holds the canonical `system` prompt for each command. A Dart generator writes five committed platform artifacts. Current prompts say "Return ONLY the corrected text" but do not explicitly forbid AI-attribution notices, preambles/suffixes, markdown fences, or labels. Runtime response cleanup exists only for surrounding quotes and is explicitly out of scope for this change.

## Goals / Non-Goals

**Goals:**
- Make the output contract unambiguous in every prompt.
- Preserve command semantics and the JSON schema.
- Keep generated artifacts byte-consistent with the JSON.

**Non-Goals:**
- Runtime sanitization of model responses.
- Changing providers, models, request parameters, or UI.

## Decisions

### 1. One shared output-contract block in every prompt
Rather than platform-specific fixes, each `system` string ends with the same explicit contract: return only the transformed text, with no preamble, suffix, labels, AI attribution, explanations, markdown fences, code blocks, or quotes. Existing per-command rules remain.

### 2. No schema or command changes
Keep version 2, the seven command ids/triggers/orders, and `{{language}}` interpolation for `@translate`. The generator validator rejects `@pro` and duplicate triggers, which guards against accidental regressions.

### 3. Regenerate all committed artifacts
Run the existing Dart generator from the repository root and commit the JSON plus all five generated files. The generator's consistency test compares committed files with fresh output, so drift is detectable.

## Risks / Trade-offs

- Stricter prompts reduce but cannot guarantee compliant output from every model → runtime cleanup is deferred to a future change if needed.
- Longer prompts add minor token cost → acceptable for output fidelity.
- Generated file churn is mechanical → verified by generator tests and `git diff`.

## Migration Plan

No user-data migration. Land the JSON, regenerate artifacts, commit all changes together so no platform consumes stale prompts. Rollback reverts the JSON and generated files as one set.
