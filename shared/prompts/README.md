# Shared AI Prompts

This directory contains the canonical AI system prompt definitions for AtFix across all supported platforms.

## Purpose

`ai_prompts.json` serves as the single source of truth for AI command system prompts. By centralizing these definitions, all native implementations (Android, macOS, etc.) use identical, consistent system instructions when executing text transformations.

## Rules

1. **Single Source of Truth**: Only modify AI system prompts in `shared/prompts/ai_prompts.json`.
2. **No Platform Duplication**: Platform implementations (Android, macOS, Windows) must load prompts directly from bundled assets/resources via their respective `PromptRepository`. Do not hardcode or duplicate prompt strings in platform code.
3. **No Dynamic Rewriting**: Prompts must not be arbitrarily modified or rewritten on individual platforms unless substituting defined variables.

## JSON Schema

```json
{
  "version": 1,
  "prompts": {
    "<key>": {
      "system": "<prompt text>"
    }
  }
}
```

### Supported Prompt Keys

| Key | Trigger Command | Description | Variables |
| --- | --- | --- | --- |
| `fix` | `@fix` | Fix grammar, spelling, and punctuation | None |
| `rewrite` | `@rewrite` | Rewrite text preserving meaning | None |
| `professional` | `@pro` | Rewrite text in a professional tone | None |
| `casual` | `@casual` | Rewrite text in a casual tone | None |
| `short` | `@short` | Shorten text while preserving meaning | None |
| `expand` | `@expand` | Expand text with clarity | None |
| `translate` | `@translate:<lang>` | Translate text into target language | `{{language}}` |

### Variable Interpolation

The `translate` prompt contains a placeholder:

- `{{language}}`: Replaced with the target language display name (e.g. `English`, `Spanish`, `French`, `German`, `Italian`, `Portuguese`, `Hindi`, `Telugu`, `Kannada`, `Tamil`).
