package com.pk.atfix.action

import android.content.Intent
import com.pk.atfix.ai.AiFailure
import com.pk.atfix.ai.AiResult
import com.pk.atfix.ai.PromptRepository
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

class ProcessTextControllerTest {

    private lateinit var repo: PromptRepository

    @Before
    fun setUp() {
        repo = PromptRepository()
    }

    @Test
    fun testExtractRequestWithValidEditableText() {
        val controller = ProcessTextController()
        val request = controller.extractRequest(
            action = Intent.ACTION_PROCESS_TEXT,
            textExtra = "Sample text to fix",
            isReadOnly = false
        )
        assertNotNull(request)
        assertEquals("Sample text to fix", request?.selectedText)
        assertFalse(request!!.isReadOnly)
    }

    @Test
    fun testExtractRequestWithReadOnlyText() {
        val controller = ProcessTextController()
        val request = controller.extractRequest(
            action = Intent.ACTION_PROCESS_TEXT,
            textExtra = "Read only article excerpt",
            isReadOnly = true
        )
        assertNotNull(request)
        assertEquals("Read only article excerpt", request?.selectedText)
        assertTrue(request!!.isReadOnly)
    }

    @Test
    fun testExtractRequestWithNullIntentReturnsNull() {
        val controller = ProcessTextController()
        assertNull(controller.extractRequest(null))
    }

    @Test
    fun testExtractRequestWithWrongActionReturnsNull() {
        val controller = ProcessTextController()
        val request = controller.extractRequest(
            action = Intent.ACTION_SEND,
            textExtra = "Sample text",
            isReadOnly = false
        )
        assertNull(request)
    }

    @Test
    fun testExtractRequestWithNullTextReturnsNull() {
        val controller = ProcessTextController()
        val request = controller.extractRequest(
            action = Intent.ACTION_PROCESS_TEXT,
            textExtra = null,
            isReadOnly = false
        )
        assertNull(request)
    }

    @Test
    fun testExtractRequestWithEmptyTextReturnsNull() {
        val controller = ProcessTextController()
        val request = controller.extractRequest(
            action = Intent.ACTION_PROCESS_TEXT,
            textExtra = "   ",
            isReadOnly = false
        )
        assertNull(request)
    }

    @Test
    fun testResolveFixPromptReturnsCanonicalPrompt() {
        val controller = ProcessTextController()
        val prompt = controller.resolveFixPrompt(repo)
        assertNotNull(prompt)
        assertTrue("Prompt must contain canonical fix rules", prompt!!.contains("Correct the user's text."))
    }

    @Test
    fun testExecuteFixSuccessEditable() = runBlocking {
        val controller = ProcessTextController()
        val executor = TextTransformExecutor { text, prompt ->
            assertEquals("helo wrld", text)
            assertTrue(prompt.contains("Correct the user's text."))
            AiResult.Success("hello world")
        }

        val request = ProcessTextRequest(selectedText = "helo wrld", isReadOnly = false)
        val result = controller.executeFix(request = request, repo = repo, executor = executor)

        assertTrue(result is ProcessTextResult.Success)
        val success = result as ProcessTextResult.Success
        assertEquals("hello world", success.transformedText)
        assertFalse(success.isReadOnly)
    }

    @Test
    fun testExecuteFixSuccessReadOnly() = runBlocking {
        val controller = ProcessTextController()
        val executor = TextTransformExecutor { _, _ ->
            AiResult.Success("Corrected text")
        }

        val request = ProcessTextRequest(selectedText = "Correted text", isReadOnly = true)
        val result = controller.executeFix(request = request, repo = repo, executor = executor)

        assertTrue(result is ProcessTextResult.Success)
        val success = result as ProcessTextResult.Success
        assertEquals("Corrected text", success.transformedText)
        assertTrue(success.isReadOnly)
    }

    @Test
    fun testExecuteFixFailureMissingApiKey() = runBlocking {
        val controller = ProcessTextController()
        val executor = TextTransformExecutor { _, _ ->
            AiResult.Failure(AiFailure.MissingApiKey)
        }

        val request = ProcessTextRequest(selectedText = "some text", isReadOnly = false)
        val result = controller.executeFix(request = request, repo = repo, executor = executor)

        assertTrue(result is ProcessTextResult.Failure)
        val failure = result as ProcessTextResult.Failure
        assertTrue(failure.errorMessage.contains("API key"))
    }

    @Test
    fun testExecuteFixFailureNetworkError() = runBlocking {
        val controller = ProcessTextController()
        val executor = TextTransformExecutor { _, _ ->
            AiResult.Failure(AiFailure.NetworkError)
        }

        val request = ProcessTextRequest(selectedText = "some text", isReadOnly = false)
        val result = controller.executeFix(request = request, repo = repo, executor = executor)

        assertTrue(result is ProcessTextResult.Failure)
        val failure = result as ProcessTextResult.Failure
        assertTrue(failure.errorMessage.contains("Network"))
    }

    @Test
    fun testFormatErrorMessageMappings() {
        val controller = ProcessTextController()
        assertTrue(controller.formatErrorMessage(AiFailure.MissingApiKey).contains("API key"))
        assertTrue(controller.formatErrorMessage(AiFailure.InvalidApiKey).contains("Invalid API key"))
        assertTrue(controller.formatErrorMessage(AiFailure.NetworkError).contains("Network"))
        assertTrue(controller.formatErrorMessage(AiFailure.Timeout).contains("timed out"))
        assertTrue(controller.formatErrorMessage(AiFailure.HttpError(500, "Server Error")).contains("500"))
        assertTrue(controller.formatErrorMessage(AiFailure.InvalidResponse).contains("invalid response"))
        assertTrue(controller.formatErrorMessage(AiFailure.ContextChanged).contains("cancelled"))
    }
}
