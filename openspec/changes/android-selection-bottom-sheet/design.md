# Design: Android Selection Bottom Sheet + All Commands

## Context

See `proposal.md` for motivation. The existing ACTION_PROCESS_TEXT activity uses a dialog-themed centered card and a controller limited to `@fix`. The supplied HTML design specifies a 390×844 bottom sheet with three parts, Roboto typography, and explicit color tokens (accent `#4F46E5`, surface `#FFFFFF`, cards `#F1F2F8`, chips `#EEF0FF`/`#3730A3`).

## Goals / Non-Goals

**Goals:**
- Match the supplied design without adding an Android dependency.
- Drive command/language data from generated definitions and the existing language map.
- Preserve Phase 1 guarantees: single result delivery, cancellation, error preservation.

**Non-Goals:**
- Changing prompt text, generated artifacts, or other platforms' language maps.
- Adding swipe-to-dismiss gestures (the drag handle is visual in the design).

## Decisions

### 1. Custom bottom sheet instead of Material Components
A translucent, full-screen `ComponentActivity` hosts a match-parent layout with a dim view and a bottom-anchored rounded panel, plus slide animations. Material was available but would add a dependency and require theme migration; custom views keep the change self-contained and pixel-controlled.

### 2. Generated definitions drive the command list
`PromptRepository.getInstance(context).getCommands()` supplies ids/triggers. A small UI copy map supplies the design's titles/descriptions/icons. `@pro` from the design is rendered as the canonical `@professional` because `@pro` is rejected everywhere.

### 3. Generalize the controller without breaking `@fix`
`executeCommand(request, trigger, languageCode, …)` resolves any canonical prompt; the existing `executeFix` remains a delegating wrapper. `@translate` interpolates `{{language}}` from `NativeCommandRegistry.supportedLanguages`; Japanese (`ja`) was added to that map.

### 4. Explicit result actions
Editable success no longer auto-applies. Replace returns `RESULT_OK`; Copy and read-only Replace return `RESULT_CANCELED` so the host text is never changed unintentionally.

## Risks / Trade-offs

- Custom sheet requires manual state handling → covered by 10 instrumentation tests including host replacement.
- Headless emulator cannot verify clipboard *content* → documented as a manual-matrix item.
- Design omits loading/error states → retained from the previous flow and restyled with sheet tokens.

## Migration Plan

Additive change. Rollback restores the previous dialog theme/layout. The keyboard IME remains untouched.
