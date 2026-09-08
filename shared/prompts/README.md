# Shared AI Prompts & Dynamic Command Definitions

This directory contains the canonical AI system prompt and command definitions for AtFix across all supported platforms.

## Purpose

`ai_prompts.json` serves as the single source of truth for AI command metadata and system prompts. By centralizing these definitions:
- Supported commands, display labels, action/status messages, explicit ordering, and input requirements are driven dynamically.
- All platforms (Flutter, Android, macOS, Windows) discover and render commands dynamically without maintaining hardcoded command lists or duplicating prompts.
- Canonical AI system instructions remain consistent across platforms.

## Architectural Rules

1. **Single Source of Truth**: Only define commands and prompts in `shared/prompts/ai_prompts.json`.
2. **Canonical Command for Professional Tone**: Use `@professional` with internal ID `professional`. There is **NO** `@pro` command or alias.
3. **No Platform Duplication**: Platforms load definitions via their platform `PromptRepository`. Never maintain hardcoded command lists, display labels, or status strings in platform code.
4. **Separation of Semantics and Styling**: The JSON defines command semantics, behavior, ordering, and prompts. Each platform remains solely responsible for its own visual styling and rendering.

---

## JSON Schema (Version 2)

```json
{
  "version": 2,
  "commands": {
    "<id>": {
      "command": "<trigger syntax (e.g. @fix)>",
      "label": "<UI display label (e.g. Fix)>",
      "actionLabel": "<Processing status label (e.g. Fixing...)>",
      "order": <integer sequence starting at 1>,
      "requiresInput": <boolean>,
      "inputType": <null or input type string (e.g. "language")>,
      "system": "<canonical system prompt template>"
    }
  }
}
```

### Fields

| Field | Type | Description |
| --- | --- | --- |
| `<id>` (JSON key) | `string` | Stable internal ID and canonical prompt key (e.g., `fix`, `professional`, `translate`). |
| `command` | `string` | Trigger syntax typed by user or shown on chips (e.g., `@fix`, `@professional`). |
| `label` | `string` | Human-readable display label for keyboard / prompt UI. |
| `actionLabel` | `string` | Status message displayed while the transformation is executing (e.g., `Fixing...`). |
| `order` | `integer` | Positive integer defining the canonical presentation order across all platforms. |
| `requiresInput` | `boolean` | `true` if the command requires additional user interaction/parameter before execution. |
| `inputType` | `string?` | Mechanism identifier when `requiresInput` is true (e.g., `"language"`). `null` otherwise. |
| `system` | `string` | System prompt instructions provided to the AI provider. |

---

### Supported Commands

| ID | Command | Label | Action Label | Order | Requires Input | Input Type | Description |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `fix` | `@fix` | Fix | Fixing... | 1 | `false` | `null` | Correct grammar, spelling, and punctuation |
| `rewrite` | `@rewrite` | Rewrite | Rewriting... | 2 | `false` | `null` | Rewrite text preserving meaning |
| `professional` | `@professional` | Professional | Making professional... | 3 | `false` | `null` | Rewrite text in a clear, professional tone |
| `casual` | `@casual` | Casual | Making casual... | 4 | `false` | `null` | Rewrite text in a natural, friendly tone |
| `short` | `@short` | Shorten | Shortening... | 5 | `false` | `null` | Make text shorter and more concise |
| `expand` | `@expand` | Expand | Expanding... | 6 | `false` | `null` | Expand text for clarity and depth |
| `translate` | `@translate` | Translate | Translating... | 7 | `true` | `"language"` | Translate text into target language |

---

### Variable Interpolation

The `translate` prompt contains a placeholder:
- `{{language}}`: Replaced with the target language display name (e.g. `English`, `Spanish`, `French`, `German`, `Italian`, `Portuguese`, `Hindi`, `Telugu`, `Kannada`, `Tamil`).

---

## Adding a New Command

To add a new command to AtFix:
1. Add an entry under `"commands"` in `shared/prompts/ai_prompts.json` with a unique ID key, `command`, `label`, `actionLabel`, `order`, `requiresInput`, `inputType`, and `system`.
2. All platforms (`PromptRepository` on Android, macOS, Windows, and Flutter) will automatically discover the command, sort it according to `order`, display its `label`, handle its `actionLabel`, and route text transformations to its `system` prompt without requiring platform-specific switch statements.
