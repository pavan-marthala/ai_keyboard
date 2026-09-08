import Cocoa
import FlutterMacOS
import XCTest
@testable import atfix

class RunnerTests: XCTestCase {

    func testCommandPromptDefaultCommands() {
        let commands = CommandPrompt.defaultCommands
        XCTAssertEqual(commands, ["@fix", "@rewrite", "@professional", "@casual", "@short", "@expand"])
        XCTAssertTrue(commands.contains("@professional"))
        XCTAssertTrue(commands.contains("@casual"))
        XCTAssertFalse(commands.contains("@pro"), "@pro must not be present in default commands")
    }

    func testActionLabelForCommands() {
        XCTAssertEqual(CommandPrompt.actionLabel(for: "@fix"), "Fixing...")
        XCTAssertEqual(CommandPrompt.actionLabel(for: "@rewrite"), "Rewriting...")
        XCTAssertEqual(CommandPrompt.actionLabel(for: "@professional"), "Making professional...")
        XCTAssertEqual(CommandPrompt.actionLabel(for: "@casual"), "Making casual...")
        XCTAssertEqual(CommandPrompt.actionLabel(for: "@short"), "Shortening...")
        XCTAssertEqual(CommandPrompt.actionLabel(for: "@expand"), "Expanding...")
        XCTAssertEqual(CommandPrompt.actionLabel(for: "@translate"), "Translating...")
        XCTAssertEqual(CommandPrompt.actionLabel(for: "@translate:es"), "Translating...")
        XCTAssertEqual(CommandPrompt.actionLabel(for: "@pro"), "Transforming...", "@pro must fallback to default")
        XCTAssertEqual(CommandPrompt.actionLabel(for: "@unknown"), "Transforming...")
    }

    func testAiTransformerPromptKeyResolution() {
        let professionalResolved = AiTransformer.resolvePromptKey(for: "@professional")
        XCTAssertEqual(professionalResolved.key, "professional")

        let casualResolved = AiTransformer.resolvePromptKey(for: "@casual")
        XCTAssertEqual(casualResolved.key, "casual")

        let fixResolved = AiTransformer.resolvePromptKey(for: "@fix")
        XCTAssertEqual(fixResolved.key, "fix")

        let rewriteResolved = AiTransformer.resolvePromptKey(for: "@rewrite")
        XCTAssertEqual(rewriteResolved.key, "rewrite")

        let shortResolved = AiTransformer.resolvePromptKey(for: "@short")
        XCTAssertEqual(shortResolved.key, "short")

        let expandResolved = AiTransformer.resolvePromptKey(for: "@expand")
        XCTAssertEqual(expandResolved.key, "expand")
    }

    func testPromptRepositoryProvidesCanonicalPrompts() throws {
        let repo = PromptRepository.shared
        XCTAssertTrue(repo.hasPrompt("professional"), "PromptRepository must have 'professional' prompt")
        XCTAssertTrue(repo.hasPrompt("casual"), "PromptRepository must have 'casual' prompt")
        XCTAssertTrue(repo.hasPrompt("fix"), "PromptRepository must have 'fix' prompt")
        XCTAssertTrue(repo.hasPrompt("rewrite"), "PromptRepository must have 'rewrite' prompt")
        XCTAssertTrue(repo.hasPrompt("short"), "PromptRepository must have 'short' prompt")
        XCTAssertTrue(repo.hasPrompt("expand"), "PromptRepository must have 'expand' prompt")
        XCTAssertTrue(repo.hasPrompt("translate"), "PromptRepository must have 'translate' prompt")

        // Strictly ensure @pro is rejected
        XCTAssertFalse(repo.hasPrompt("@pro"))
        XCTAssertFalse(repo.hasPrompt("pro"))
        XCTAssertNil(repo.command(for: "@pro"))
        XCTAssertNil(repo.command(for: "pro"))

        let proPrompt = try repo.getPrompt("professional")
        XCTAssertFalse(proPrompt.isEmpty)
        XCTAssertTrue(proPrompt.contains("professional tone"))

        let casualPrompt = try repo.getPrompt("casual")
        XCTAssertFalse(casualPrompt.isEmpty)
        XCTAssertTrue(casualPrompt.contains("friendly, conversational tone"))

        // Ensure all default commands resolve to valid, non-empty prompts in PromptRepository
        for cmd in CommandPrompt.defaultCommands {
            let resolved = AiTransformer.resolvePromptKey(for: cmd)
            let prompt = try repo.getPrompt(resolved.key)
            XCTAssertFalse(prompt.isEmpty, "Resolved prompt for \(cmd) must not be empty")
        }
    }

    func testCommandsEnabledByDefaultInConfiguration() {
        let configStore = ConfigurationStore.shared
        XCTAssertTrue(configStore.isCommandEnabled("@professional"))
        XCTAssertTrue(configStore.isCommandEnabled("@casual"))
        XCTAssertTrue(configStore.isCommandEnabled("@fix"))
        XCTAssertTrue(configStore.isCommandEnabled("@rewrite"))
        XCTAssertTrue(configStore.isCommandEnabled("@short"))
        XCTAssertTrue(configStore.isCommandEnabled("@expand"))
    }
}

