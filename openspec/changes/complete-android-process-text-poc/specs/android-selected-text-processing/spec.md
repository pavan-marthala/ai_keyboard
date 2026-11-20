# Spec Delta

## Purpose

Defines the behavior of AtFix's Android selected-text workflow: how it is invoked from the native text-selection menu, how it obtains and transforms selected text, and how it returns a result to the host application without requiring special permissions or disturbing the user's keyboard.

## ADDED Requirements

### Requirement: Selection-menu invocation
AtFix SHALL appear as an action in Android's native text-selection menu whenever selectable text is present, and choosing it SHALL open AtFix's floating selected-text dialog showing the selected text.

#### Scenario: Invoke on a text selection
- **WHEN** the user selects text in an application that exposes the platform text-processing menu and chooses the AtFix action
- **THEN** AtFix opens a floating dialog that displays the selected text and offers the transformation action

#### Scenario: No usable selection
- **WHEN** AtFix is launched with no selected text, null text, or blank text
- **THEN** AtFix SHALL NOT run a transformation and SHALL close without returning a transformed-text result

### Requirement: Selected text and editability capture
AtFix SHALL receive the selected text together with the host field's read-only state and SHALL base its result behavior on that state.

#### Scenario: Editable selection
- **WHEN** the host reports an editable text field
- **THEN** AtFix treats the selection as replaceable and does not present a read-only indicator

#### Scenario: Read-only selection
- **WHEN** the host reports a read-only text container
- **THEN** AtFix presents a read-only indication and does not attempt in-place replacement

### Requirement: Canonical command transformation
AtFix SHALL transform the selected text using the canonical `@fix` definition from the shared command definitions and the existing AI provider pipeline, without duplicating prompt text.

#### Scenario: Successful transformation
- **WHEN** the user triggers the transformation on a valid selection
- **THEN** AtFix returns the transformed text produced by the configured AI provider using the canonical `@fix` prompt

#### Scenario: Prompt definition unavailable
- **WHEN** the canonical `@fix` definition cannot be resolved
- **THEN** AtFix SHALL NOT run a transformation and SHALL surface an error without returning a transformed-text result

### Requirement: Editable result delivery
For an editable selection, a successful transformation SHALL be returned to the host application as a positive result carrying the transformed text, so the host can replace the selected text.

#### Scenario: In-place replacement in an editable field
- **WHEN** a transformation succeeds for an editable selection and AtFix returns the transformed-text result
- **THEN** the host application's selected text is replaced by the transformed text, and this replacement is observable in the host field

#### Scenario: Host does not support replacement
- **WHEN** a host application reports an editable field but does not apply the returned transformed-text result
- **THEN** AtFix's result is still valid and the original text remains under the host application's control

### Requirement: Read-only result fallback
For a read-only selection, a successful transformation SHALL present the result for manual copying and SHALL leave the originating text untouched.

#### Scenario: Copy transformed result
- **WHEN** a transformation succeeds for a read-only selection
- **THEN** AtFix displays the transformed text with a copy-to-clipboard action, and the originating text is not modified in place

### Requirement: Cancellation and error safety
Cancellation, dismissal, malformed input, or a transformation failure SHALL leave the user's original text unchanged.

#### Scenario: User cancels or dismisses
- **WHEN** the user closes the dialog, taps outside it, or otherwise cancels before a result is delivered
- **THEN** AtFix returns a canceled result and no transformed text is applied

#### Scenario: Transformation fails
- **WHEN** the AI transformation fails, including when no API key is configured
- **THEN** AtFix shows an error with retry and cancel options and returns no transformed-text result

#### Scenario: Malformed invocation
- **WHEN** AtFix receives an invocation without the expected action or text payload
- **THEN** AtFix closes without running a transformation and without returning transformed text

### Requirement: Input robustness
AtFix SHALL handle long selections, Unicode, multiline text, and special characters without corrupting the input or the result.

#### Scenario: Complex text selection
- **WHEN** the selected text is long, multiline, Unicode, or contains special characters
- **THEN** AtFix passes the text to the transformation pipeline intact and returns the transformed text without truncation or corruption introduced by AtFix

#### Scenario: Surrounding whitespace
- **WHEN** the selected text begins or ends with whitespace
- **THEN** AtFix's trimming behavior is defined and documented and SHALL NOT be relied upon to preserve that whitespace

### Requirement: Lifecycle resilience
AtFix SHALL remain safe across activity lifecycle events so that no stale or duplicate result is applied to the host text.

#### Scenario: Recreated during transformation
- **WHEN** the dialog is destroyed and recreated while a transformation is in progress
- **THEN** AtFix SHALL NOT apply more than one result to the host text and a canceled or failed path SHALL preserve the original text

### Requirement: Permission-free, keyboard-independent operation
AtFix's selected-text workflow SHALL NOT require accessibility permissions, overlay permissions, or continuous background monitoring, and SHALL NOT depend on AtFix being the active keyboard.

#### Scenario: Third-party keyboard active
- **WHEN** the user's preferred keyboard is any keyboard other than AtFix
- **THEN** the AtFix selection action remains available and functions through the platform text-processing mechanism

#### Scenario: No elevated permissions
- **WHEN** the user has granted neither Accessibility nor overlay permission
- **THEN** the selected-text transformation workflow remains available
