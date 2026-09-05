import Cocoa

/// Independent execution context for an asynchronous command execution.
/// Guarantees that each command retains its immutable target, element,
/// range, and cancellation status across async boundaries.
final class CommandExecutionContext {
    let id: UUID
    let command: String
    let targetApp: NSRunningApplication
    let targetPid: pid_t
    let targetElement: AXUIElement
    let selectedText: String
    let selectedRange: CFRange
    var isCancelled: Bool = false

    init(
        id: UUID = UUID(),
        command: String,
        targetApp: NSRunningApplication,
        targetPid: pid_t,
        targetElement: AXUIElement,
        selectedText: String,
        selectedRange: CFRange
    ) {
        self.id = id
        self.command = command
        self.targetApp = targetApp
        self.targetPid = targetPid
        self.targetElement = targetElement
        self.selectedText = selectedText
        self.selectedRange = selectedRange
    }
}

/// Dispatches selected desktop commands (@fix, @rewrite, @short, @expand) to
/// the native AI transformer, coordinates asynchronous execution and cancellation,
/// updates prompt feedback, and triggers text replacement on success.
final class CommandDispatcher {

    static let shared = CommandDispatcher()

    private let textReplacementService: TextReplacementService

    private var activeExecutions: [UUID: CommandExecutionContext] = [:]
    private var activeTasks: [UUID: Task<Void, Never>] = [:]

    init(textReplacementService: TextReplacementService = .shared) {
        self.textReplacementService = textReplacementService
    }

    var runningCommands: [String] {
        return activeExecutions.values.filter { !$0.isCancelled }.map { $0.command }
    }

    // MARK: - Dispatch

    func dispatch(
        command: String,
        targetApp: NSRunningApplication,
        targetPid: pid_t,
        targetElement: AXUIElement,
        selectedText: String,
        selectedRange: CFRange,
        prompt: CommandPrompt
    ) {
        let execution = CommandExecutionContext(
            command: command,
            targetApp: targetApp,
            targetPid: targetPid,
            targetElement: targetElement,
            selectedText: selectedText,
            selectedRange: selectedRange
        )

        activeExecutions[execution.id] = execution
        prompt.updateLoadingState(runningCommands: runningCommands)

        NSLog("[CommandDispatcher] COMMAND SELECTED = \(command) [execId: \(execution.id.uuidString.prefix(8))]")

        let task = Task {
            do {
                let transformedText = try await AiTransformer.shared.transform(
                    command: execution.command,
                    text: execution.selectedText
                )

                await MainActor.run {
                    guard !execution.isCancelled else {
                        NSLog("[CommandDispatcher] Execution \(execution.id.uuidString.prefix(8)) was cancelled. Skipping replacement.")
                        self.cleanupExecution(execution.id)
                        return
                    }

                    NSLog("[CommandDispatcher] REAL AI TRANSFORMED [\(execution.command)] = '\(transformedText)'")
                    let success = self.textReplacementService.replaceSelectedText(
                        transformedText: transformedText,
                        targetApp: execution.targetApp,
                        targetPid: execution.targetPid,
                        targetElement: execution.targetElement,
                        expectedSelectedText: execution.selectedText,
                        expectedSelectedRange: execution.selectedRange
                    )

                    self.cleanupExecution(execution.id)

                    if success {
                        if self.activeExecutions.isEmpty {
                            prompt.close()
                        } else {
                            prompt.updateLoadingState(runningCommands: self.runningCommands)
                        }
                    } else {
                        prompt.showError(command: execution.command, message: "Replacement failed in target application.")
                    }
                }
            } catch {
                await MainActor.run {
                    guard !execution.isCancelled else {
                        self.cleanupExecution(execution.id)
                        return
                    }

                    NSLog("[CommandDispatcher] REAL AI FAILURE for \(execution.command): \(error.localizedDescription)")
                    self.cleanupExecution(execution.id)

                    // Strictly NO mock fallback. Display error and keep prompt open.
                    prompt.showError(command: execution.command, message: error.localizedDescription)
                }
            }
        }
        activeTasks[execution.id] = task
    }

    // MARK: - Cancellation & Cleanup

    func cancelAll() {
        for (id, execution) in activeExecutions {
            execution.isCancelled = true
            activeTasks[id]?.cancel()
        }
        activeExecutions.removeAll()
        activeTasks.removeAll()
    }

    private func cleanupExecution(_ id: UUID) {
        activeExecutions.removeValue(forKey: id)
        activeTasks.removeValue(forKey: id)
    }
}
