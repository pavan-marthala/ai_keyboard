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
          "version": 2,
          "commands": {
            "fix": {
              "command": "@fix",
              "label": "Fix",
              "actionLabel": "Fixing...",
              "order": 1,
              "requiresInput": false,
              "inputType": null,
              "system": "Correct the user's text."
            },
            "rewrite": {
              "command": "@rewrite",
              "label": "Rewrite",
              "actionLabel": "Rewriting...",
              "order": 2,
              "requiresInput": false,
              "inputType": null,
              "system": "Rewrite the user's text."
            },
            "professional": {
              "command": "@professional",
              "label": "Professional",
              "actionLabel": "Making professional...",
              "order": 3,
              "requiresInput": false,
              "inputType": null,
              "system": "Rewrite in professional tone."
            },
            "casual": {
              "command": "@casual",
              "label": "Casual",
              "actionLabel": "Making casual...",
              "order": 4,
              "requiresInput": false,
              "inputType": null,
              "system": "Rewrite in casual tone."
            },
            "short": {
              "command": "@short",
              "label": "Shorten",
              "actionLabel": "Shortening...",
              "order": 5,
              "requiresInput": false,
              "inputType": null,
              "system": "Make text shorter."
            },
            "expand": {
              "command": "@expand",
              "label": "Expand",
              "actionLabel": "Expanding...",
              "order": 6,
              "requiresInput": false,
              "inputType": null,
              "system": "Expand the text."
            },
            "translate": {
              "command": "@translate",
              "label": "Translate",
              "actionLabel": "Translating...",
              "order": 7,
              "requiresInput": true,
              "inputType": "language",
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
    fun testDynamicCommandDiscoveryAndOrdering() {
        val repo = PromptRepository.fromJson(sampleJson)
        val commands = repo.getCommands()
        assertEquals(7, commands.size)

        val triggers = commands.map { it.command }
        assertEquals(
            listOf("@fix", "@rewrite", "@professional", "@casual", "@short", "@expand", "@translate"),
            triggers
        )

        val pro = repo.getCommand("@professional")
        assertNotNull(pro)
        assertEquals("professional", pro!!.id)
        assertEquals("Professional", pro.label)
        assertEquals("Making professional...", pro.actionLabel)
        assertFalse(pro.requiresInput)

        val translate = repo.getCommand("@translate")
        assertNotNull(translate)
        assertTrue(translate!!.requiresInput)
        assertEquals("language", translate.inputType)
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
        PromptRepository.fromJson("""{"version": 2}""")
    }

    @Test(expected = IllegalArgumentException::class)
    fun testProCommandRejectedByPromptRepository() {
        val badJson = """
            {
              "version": 2,
              "commands": {
                "pro": {
                  "command": "@pro",
                  "label": "Pro",
                  "actionLabel": "Fixing...",
                  "order": 1,
                  "requiresInput": false,
                  "inputType": null,
                  "system": "Pro prompt"
                }
              }
            }
        """.trimIndent()
        PromptRepository.fromJson(badJson)
    }

    @Test
    fun testNativeCommandRegistryResolution() {
        assertEquals("Correct the user's text.", NativeCommandRegistry.getPrompt("@fix", emptyMap()))
        assertEquals("Rewrite the user's text.", NativeCommandRegistry.getPrompt("@rewrite", emptyMap()))
        assertEquals("Rewrite in professional tone.", NativeCommandRegistry.getPrompt("@professional", emptyMap()))
        assertNull("Obsolete @pro must be rejected", NativeCommandRegistry.getPrompt("@pro", emptyMap()))
        assertEquals("Rewrite in casual tone.", NativeCommandRegistry.getPrompt("@casual", emptyMap()))
        assertEquals("Make text shorter.", NativeCommandRegistry.getPrompt("@short", emptyMap()))
        assertEquals("Expand the text.", NativeCommandRegistry.getPrompt("@expand", emptyMap()))
        assertEquals("Translate into Spanish.", NativeCommandRegistry.getPrompt("@translate", mapOf("language" to "es")))
        assertNull(NativeCommandRegistry.getPrompt("@translate", mapOf("language" to "unsupported_xyz")))
        assertNull(NativeCommandRegistry.getPrompt("@nonexistent", emptyMap()))

        assertEquals("✨ Making professional...", NativeCommandRegistry.getStatusMessage("@professional", emptyMap()))
        assertEquals("✨ Translating to Spanish...", NativeCommandRegistry.getStatusMessage("@translate", mapOf("language" to "es")))
    }
}
