package com.pk.ai_keyboard.clipboard

import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

class ClipboardHistoryRepositoryTest {

    private lateinit var repository: ClipboardHistoryRepository

    @Before
    fun setUp() {
        repository = ClipboardHistoryRepository(maxItems = 20)
    }

    @Test
    fun `addClip adds new text item and places newest first`() {
        repository.addClip("First clip")
        repository.addClip("Second clip")

        val items = repository.getItems()
        assertEquals(2, items.size)
        assertEquals("Second clip", items[0])
        assertEquals("First clip", items[1])
    }

    @Test
    fun `addClip ignores empty or blank strings`() {
        assertFalse(repository.addClip(""))
        assertFalse(repository.addClip("   "))
        assertEquals(0, repository.getItems().size)
    }

    @Test
    fun `addClip deduplicates existing item and moves it to top`() {
        repository.addClip("Alpha")
        repository.addClip("Beta")
        repository.addClip("Gamma")
        assertEquals(3, repository.getItems().size)
        assertEquals("Gamma", repository.getItems()[0])

        // Add "Alpha" again
        repository.addClip("Alpha")
        val items = repository.getItems()
        assertEquals(3, items.size)
        assertEquals("Alpha", items[0])
        assertEquals("Gamma", items[1])
        assertEquals("Beta", items[2])
    }

    @Test
    fun `addClip enforces maximum 20 items capacity limit`() {
        for (i in 1..25) {
            repository.addClip("Clip $i")
        }

        val items = repository.getItems()
        assertEquals(20, items.size)
        assertEquals("Clip 25", items[0])
        assertEquals("Clip 6", items[19])
    }

    @Test
    fun `clear removes all history entries`() {
        repository.addClip("Item 1")
        repository.addClip("Item 2")
        assertEquals(2, repository.getItems().size)

        repository.clear()
        assertEquals(0, repository.getItems().size)
    }

    @Test
    fun `toJson and loadFromJson correctly serialize and deserialize entries`() {
        repository.addClip("First entry")
        repository.addClip("Second entry with \"quotes\" & \n newlines")

        val jsonStr = repository.toJson()
        assertNotNull(jsonStr)
        assertTrue(jsonStr.startsWith("["))

        val newRepo = ClipboardHistoryRepository(maxItems = 20)
        newRepo.loadFromJson(jsonStr)

        val restoredItems = newRepo.getItems()
        assertEquals(2, restoredItems.size)
        assertEquals("Second entry with \"quotes\" & \n newlines", restoredItems[0])
        assertEquals("First entry", restoredItems[1])
    }
}

