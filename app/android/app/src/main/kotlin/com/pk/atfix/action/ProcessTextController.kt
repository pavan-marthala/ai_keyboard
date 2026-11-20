package com.pk.atfix.action

import android.content.Context
import android.content.Intent
import com.pk.atfix.ai.AiFailure
import com.pk.atfix.ai.AiResult
import com.pk.atfix.ai.PromptRepository
import com.pk.atfix.command.NativeCommandRegistry
import com.pk.atfix.transform.AiTextTransformer

/**
 * Encapsulates an incoming text-processing request received via ACTION_PROCESS_TEXT.
 */
data class ProcessTextRequest(
    val selectedText: String,
    val isReadOnly: Boolean
)

/**
 * Result of executing text transformation.
 */
sealed class ProcessTextResult {
    data class Success(
        val transformedText: String,
        val isReadOnly: Boolean,
        val trigger: String = "@fix"
    ) : ProcessTextResult()

    data class Failure(
        val errorMessage: String
    ) : ProcessTextResult()
}

/**
 * Functional interface abstraction for executing AI text transformations.
 */
fun interface TextTransformExecutor {
    suspend fun transform(text: String, prompt: String): AiResult<String>
}

/**
 * Controller responsible for parsing ACTION_PROCESS_TEXT intents, orchestrating
 * canonical @fix text transformations, and constructing IPC result intents.
 */
class ProcessTextController(
    private val promptRepositoryProvider: (Context) -> PromptRepository = { PromptRepository.getInstance(it) },
    private val transformExecutorFactory: (Context) -> TextTransformExecutor = { context ->
        val transformer = AiTextTransformer(context)
        TextTransformExecutor { text, prompt -> transformer.transformText(text, prompt) }
    }
) {

    /**
     * Extracts and validates the incoming selected text and read-only status from raw values.
     */
    fun extractRequest(action: String?, textExtra: CharSequence?, isReadOnly: Boolean): ProcessTextRequest? {
        if (action != Intent.ACTION_PROCESS_TEXT) {
            return null
        }

        val selectedText = textExtra?.toString() ?: return null
        if (selectedText.isBlank()) {
            return null
        }

        return ProcessTextRequest(selectedText = selectedText, isReadOnly = isReadOnly)
    }

    /**
     * Extracts and validates the incoming selected text and read-only status from an Intent.
     * Returns null if the intent is not ACTION_PROCESS_TEXT or selected text is empty.
     */
    fun extractRequest(intent: Intent?): ProcessTextRequest? {
        if (intent == null) return null
        return extractRequest(
            action = intent.action,
            textExtra = intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT),
            isReadOnly = intent.getBooleanExtra(Intent.EXTRA_PROCESS_TEXT_READONLY, false)
        )
    }

    /**
     * Resolves the canonical @fix system prompt from the given repository.
     */
    fun resolveFixPrompt(repo: PromptRepository): String? = resolvePrompt(repo, "@fix", null)

    /**
     * Resolves the canonical system prompt for any generated command definition.
     * For @translate, [languageCode] is interpolated into the {{language}} placeholder.
     */
    fun resolvePrompt(
        repo: PromptRepository,
        trigger: String,
        languageCode: String? = null
    ): String? {
        val command = repo.getCommand(trigger) ?: return null
        if (!repo.hasPrompt(command.id)) return null

        if (command.id == "translate") {
            val languageName = languageCode
                ?.let { NativeCommandRegistry.supportedLanguages[it.lowercase()] }
                ?: return null
            return repo.getPrompt(command.id, mapOf("language" to languageName))
        }
        return repo.getPrompt(command.id)
    }

    /**
     * Resolves the canonical @fix system prompt from the shared command-definition repository.
     */
    fun resolveFixPrompt(context: Context): String? {
        return resolveFixPrompt(promptRepositoryProvider(context))
    }

    /**
     * Executes a transformation with an explicit repo and executor.
     */
    suspend fun executeCommand(
        request: ProcessTextRequest,
        trigger: String,
        repo: PromptRepository,
        executor: TextTransformExecutor,
        languageCode: String? = null
    ): ProcessTextResult {
        val prompt = resolvePrompt(repo, trigger, languageCode)
            ?: return ProcessTextResult.Failure("Canonical $trigger prompt definition not found.")

        return try {
            when (val result = executor.transform(request.selectedText, prompt)) {
                is AiResult.Success -> ProcessTextResult.Success(
                    transformedText = result.data,
                    isReadOnly = request.isReadOnly,
                    trigger = trigger
                )
                is AiResult.Failure -> ProcessTextResult.Failure(formatErrorMessage(result.failure))
            }
        } catch (e: Exception) {
            ProcessTextResult.Failure("Unexpected error during text transformation: ${e.localizedMessage ?: e.message}")
        }
    }

    /** Backwards-compatible @fix convenience wrapper. */
    suspend fun executeFix(
        request: ProcessTextRequest,
        repo: PromptRepository,
        executor: TextTransformExecutor
    ): ProcessTextResult = executeCommand(request, "@fix", repo, executor)

    /** Executes a transformation using the real pipeline for the given [request]. */
    suspend fun executeCommand(
        context: Context,
        request: ProcessTextRequest,
        trigger: String,
        languageCode: String? = null
    ): ProcessTextResult = executeCommand(
        request = request,
        trigger = trigger,
        repo = promptRepositoryProvider(context),
        executor = transformExecutorFactory(context),
        languageCode = languageCode
    )

    suspend fun executeFix(context: Context, request: ProcessTextRequest): ProcessTextResult =
        executeCommand(context, request, "@fix")

    /**
     * Constructs the standard Android Intent with EXTRA_PROCESS_TEXT to return the
     * transformed text to the originating application.
     */
    fun createSuccessResultIntent(transformedText: String): Intent {
        return Intent().apply {
            putExtra(Intent.EXTRA_PROCESS_TEXT, transformedText)
        }
    }

    /**
     * Maps internal AI failure states to actionable user messages.
     */
    fun formatErrorMessage(failure: AiFailure): String {
        return when (failure) {
            is AiFailure.MissingApiKey -> "No AI API key found. Please open the AtFix application and configure an AI provider."
            is AiFailure.InvalidApiKey -> "Invalid API key. Please check your provider credentials in AtFix settings."
            is AiFailure.NetworkError -> "Network unavailable. Please check your internet connection."
            is AiFailure.Timeout -> "The transformation request timed out. Please try again."
            is AiFailure.HttpError -> "AI provider error (${failure.statusCode}): ${failure.message}"
            is AiFailure.InvalidResponse -> "Received invalid response from the AI provider."
            is AiFailure.ContextChanged -> "Transformation request was cancelled."
        }
    }
}
