package com.pk.atfix.gif

import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

class RecentGifRepositoryTest {

    private lateinit var repository: RecentGifRepository

    @Before
    fun setUp() {
        repository = RecentGifRepository(maxItems = 3)
    }

    @Test
    fun testAddRecentDeduplicatesAndLimitsCount() {
        val item1 = GifItem("1", "prev1", "content1", title = "GIF 1")
        val item2 = GifItem("2", "prev2", "content2", title = "GIF 2")
        val item3 = GifItem("3", "prev3", "content3", title = "GIF 3")
        val item4 = GifItem("4", "prev4", "content4", title = "GIF 4")

        repository.addRecent(item1)
        repository.addRecent(item2)
        repository.addRecent(item3)

        assertEquals(3, repository.getItems().size)
        assertEquals("3", repository.getItems()[0].id)

        // Adding duplicate item 1 should move item 1 to top
        repository.addRecent(item1)
        assertEquals(3, repository.getItems().size)
        assertEquals("1", repository.getItems()[0].id)

        // Adding item 4 should drop oldest item (item 2)
        repository.addRecent(item4)
        assertEquals(3, repository.getItems().size)
        assertEquals("4", repository.getItems()[0].id)
        assertFalse(repository.getItems().any { it.id == "2" })
    }

    @Test
    fun testToJsonAndLoadFromJson() {
        val item1 = GifItem("1", "prev1", "content1", title = "GIF 1")
        repository.addRecent(item1)

        val json = repository.toJson()
        assertNotNull(json)

        val newRepo = RecentGifRepository(maxItems = 3)
        newRepo.loadFromJson(json)

        assertEquals(1, newRepo.getItems().size)
        assertEquals("1", newRepo.getItems()[0].id)
        assertEquals("prev1", newRepo.getItems()[0].previewUrl)
    }
}

