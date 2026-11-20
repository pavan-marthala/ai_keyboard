# Spec Delta

## Purpose

Defines the bottom-sheet experience of AtFix's Android selected-text workflow: choosing any canonical command, selecting a translation language, previewing the transformed text, and deciding whether to replace or copy it.

## ADDED Requirements

### Requirement: Bottom sheet presentation
AtFix SHALL present the selected-text workflow as a bottom sheet anchored to the bottom of the display with a dimmed backdrop, a drag handle, and rounded top corners.

#### Scenario: Invoke from text selection
- **WHEN** the user selects text in a host application and chooses the AtFix action
- **THEN** a bottom sheet opens showing the selected text and the available commands

#### Scenario: Dismiss the sheet
- **WHEN** the user taps the close action, the dimmed backdrop, or the system back action
- **THEN** AtFix returns a canceled result and the host text is unchanged

### Requirement: Command picker
The sheet SHALL list all canonical commands obtained from the generated command definitions and SHALL NOT expose the deprecated `@pro` trigger.

#### Scenario: List canonical commands
- **WHEN** the command picker is shown
- **THEN** it lists `@fix`, `@rewrite`, `@professional`, `@casual`, `@short`, `@expand`, and `@translate`

#### Scenario: Run a non-translate command
- **WHEN** the user selects a command other than `@translate`
- **THEN** AtFix transforms the selected text with that command's canonical prompt

### Requirement: Translate language picker
Selecting `@translate` SHALL open a searchable language picker whose selection is interpolated into the canonical translate prompt.

#### Scenario: Choose a language
- **WHEN** the user selects a language such as Japanese (`ja`)
- **THEN** AtFix builds a `@translate:ja` request and resolves the canonical prompt with that language name

#### Scenario: Filter languages
- **WHEN** the user types a query in the language search field
- **THEN** only languages matching the name, native name, or code are shown

### Requirement: Result preview and actions
A successful transformation SHALL be presented as an ORIGINAL/CORRECTED preview with Replace, Copy, Try again, and back actions.

#### Scenario: Replace editable text
- **WHEN** the user taps Replace for an editable selection
- **THEN** AtFix returns `RESULT_OK` with the transformed text so the host replaces the selection

#### Scenario: Copy without replacing
- **WHEN** the user taps Copy
- **THEN** the transformed text is copied to the clipboard and no `RESULT_OK` replacement is returned

#### Scenario: Read-only replacement request
- **WHEN** the user taps Replace for a read-only selection
- **THEN** AtFix copies the text and returns a canceled result, leaving the origin untouched

#### Scenario: Retry
- **WHEN** the user taps Try again
- **THEN** the same command and language are executed again with the original selection

### Requirement: Result safety
The result behavior of the selected-text workflow SHALL remain safe under cancellation and lifecycle changes.

#### Scenario: Error or recreation
- **WHEN** a transformation fails or the activity is recreated in flight
- **THEN** no stale or duplicate `RESULT_OK` is delivered and the original text is preserved
