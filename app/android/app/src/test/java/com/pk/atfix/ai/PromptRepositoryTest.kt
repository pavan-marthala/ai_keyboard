package com.pk.atfix.ai

import com.pk.atfix.command.NativeCommandRegistry
import com.pk.atfix.generated.GeneratedCommandDefinition
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

class PromptRepositoryTest {

    @Before
    fun setUp() {
        val repo = PromptRepository()
        PromptRepository.setInstance(repo)
    }

    @After
    fun tearDown() {
        PromptRepository.resetInstance()
    }

    @Test
    fun testDynamicCommandDiscoveryAndOrdering() {
        val repo = PromptRepository()
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
        assertEquals("Make the tone professional and formal", pro.description)
        assertFalse(pro.requiresInput)

        val translate = repo.getCommand("@translate")
        assertNotNull(translate)
        assertTrue(translate!!.requiresInput)
        assertEquals("language", translate.inputType)
    }

    @Test
    fun testGetPromptSuccess() {
        val repo = PromptRepository()
        assertTrue(repo.getPrompt("fix").contains("Correct the user's text."))
        assertTrue(repo.getPrompt("rewrite").contains("Rewrite the user's text"))
        assertTrue(repo.getPrompt("professional").contains("professional tone"))
        assertTrue(repo.getPrompt("casual").contains("conversational tone"))
        assertTrue(repo.getPrompt("short").contains("concise"))
        assertTrue(repo.getPrompt("expand").contains("more complete"))
    }

    @Test
    fun testGetPromptWithVariableSubstitution() {
        val repo = PromptRepository()
        val translated = repo.getPrompt("translate", mapOf("language" to "Spanish"))
        assertTrue(translated.contains("Spanish"))
        assertFalse(translated.contains("{{language}}"))
    }

    @Test(expected = IllegalArgumentException::class)
    fun testGetPromptUnknownKeyThrows() {
        val repo = PromptRepository()
        repo.getPrompt("unknown_command")
    }

    @Test
    fun testCustomDefinitionsInitialization() {
        val custom = listOf(
            GeneratedCommandDefinition(
                id = "custom",
                command = "@custom",
                label = "Custom",
                actionLabel = "Customizing...",
                description = "Custom command",
                order = 1,
                requiresInput = false,
                inputType = null,
                system = "Custom prompt"
            )
        )
        val repo = PromptRepository(custom)
        assertEquals(1, repo.getCommands().size)
        assertEquals("@custom", repo.getCommands()[0].command)
        assertEquals("Custom prompt", repo.getPrompt("custom"))
    }

    @Test
    fun testNativeCommandRegistryResolution() {
        assertTrue(NativeCommandRegistry.getPrompt("@fix", emptyMap())!!.contains("Correct the user's text."))
        assertTrue(NativeCommandRegistry.getPrompt("@rewrite", emptyMap())!!.contains("Rewrite the user's text"))
        assertTrue(NativeCommandRegistry.getPrompt("@professional", emptyMap())!!.contains("professional tone"))
        assertNull("Obsolete @pro must be rejected", NativeCommandRegistry.getPrompt("@pro", emptyMap()))
        assertTrue(NativeCommandRegistry.getPrompt("@casual", emptyMap())!!.contains("conversational tone"))
        assertTrue(NativeCommandRegistry.getPrompt("@short", emptyMap())!!.contains("concise"))
        assertTrue(NativeCommandRegistry.getPrompt("@expand", emptyMap())!!.contains("more complete"))
        assertTrue(NativeCommandRegistry.getPrompt("@translate", mapOf("language" to "es"))!!.contains("Spanish"))
        assertNull(NativeCommandRegistry.getPrompt("@translate", mapOf("language" to "unsupported_xyz")))
        assertNull(NativeCommandRegistry.getPrompt("@nonexistent", emptyMap()))

        assertEquals("✨ Making professional...", NativeCommandRegistry.getStatusMessage("@professional", emptyMap()))
        assertEquals("✨ Translating to Spanish...", NativeCommandRegistry.getStatusMessage("@translate", mapOf("language" to "es")))
    }
}

