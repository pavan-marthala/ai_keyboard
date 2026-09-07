package com.pk.atfix.ai

import com.pk.atfix.command.NativeCommandRegistry
import org.json.JSONException
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

class PromptRepositoryTest {

    private val sampleJson = """
        {
          "version": 1,
          "prompts": {
            "fix": {
              "system": "Correct the user's text."
            },
            "rewrite": {
              "system": "Rewrite the user's text."
            },
            "professional": {
              "system": "Rewrite in professional tone."
            },
            "casual": {
              "system": "Rewrite in casual tone."
            },
            "short": {
              "system": "Make text shorter."
            },
            "expand": {
              "system": "Expand the text."
            },
            "translate": {
              "system": "Translate into {{language}}."
            }
          }
        }
    """.trimIndent()

    @Before
    fun setUp() {
        val repo = PromptRepository.fromJson(sampleJson)
        PromptRepository.setInstance(repo)
    }

    @After
    fun tearDown() {
        PromptRepository.resetInstance()
    }

    @Test
    fun testGetPromptSuccess() {
        val repo = PromptRepository.fromJson(sampleJson)
        assertEquals("Correct the user's text.", repo.getPrompt("fix"))
        assertEquals("Rewrite the user's text.", repo.getPrompt("rewrite"))
        assertEquals("Rewrite in professional tone.", repo.getPrompt("professional"))
        assertEquals("Rewrite in casual tone.", repo.getPrompt("casual"))
        assertEquals("Make text shorter.", repo.getPrompt("short"))
        assertEquals("Expand the text.", repo.getPrompt("expand"))
    }

    @Test
    fun testGetPromptWithVariableSubstitution() {
        val repo = PromptRepository.fromJson(sampleJson)
        val translated = repo.getPrompt("translate", mapOf("language" to "Spanish"))
        assertEquals("Translate into Spanish.", translated)
    }

    @Test(expected = IllegalArgumentException::class)
    fun testGetPromptUnknownKeyThrows() {
        val repo = PromptRepository.fromJson(sampleJson)
        repo.getPrompt("unknown_command")
    }

    @Test(expected = JSONException::class)
    fun testInvalidJsonThrows() {
        PromptRepository.fromJson("""{"version": 1}""")
    }

    @Test
    fun testNativeCommandRegistryResolution() {
        assertEquals("Correct the user's text.", NativeCommandRegistry.getPrompt("@fix", emptyMap()))
        assertEquals("Rewrite the user's text.", NativeCommandRegistry.getPrompt("@rewrite", emptyMap()))
        assertEquals("Rewrite in professional tone.", NativeCommandRegistry.getPrompt("@pro", emptyMap()))
        assertEquals("Rewrite in casual tone.", NativeCommandRegistry.getPrompt("@casual", emptyMap()))
        assertEquals("Make text shorter.", NativeCommandRegistry.getPrompt("@short", emptyMap()))
        assertEquals("Expand the text.", NativeCommandRegistry.getPrompt("@expand", emptyMap()))
        assertEquals("Translate into Spanish.", NativeCommandRegistry.getPrompt("@translate", mapOf("language" to "es")))
        assertNull(NativeCommandRegistry.getPrompt("@translate", mapOf("language" to "unsupported_xyz")))
        assertNull(NativeCommandRegistry.getPrompt("@nonexistent", emptyMap()))
    }
}

