package com.pk.atfix.keyboard

import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test

class KeyboardHeightRepositoryTest {

    private lateinit var storage: InMemoryKeyValueStorage
    private lateinit var repository: KeyboardHeightRepository

    @Before
    fun setUp() {
        storage = InMemoryKeyValueStorage()
        repository = KeyboardHeightRepository(storage)
    }

    @Test
    fun testDefaultHeight() {
        assertEquals(216, repository.getHeight())
    }

    @Test
    fun testMinHeightClamping() {
        storage.putInt(KeyboardHeightRepository.KEY_HEIGHT_DP, 100)
        assertEquals(150, repository.getHeight())
    }

    @Test
    fun testMaxHeightClamping() {
        storage.putInt(KeyboardHeightRepository.KEY_HEIGHT_DP, 450)
        assertEquals(350, repository.getHeight())
    }

    @Test
    fun testValidHeightPersistence() {
        val applied = repository.setHeight(280)
        assertEquals(280, applied)
        assertEquals(280, storage.getInt(KeyboardHeightRepository.KEY_HEIGHT_DP, 0))
        assertEquals(280, repository.getHeight())
    }

    @Test
    fun testSetHeightClamping() {
        val appliedLow = repository.setHeight(80)
        assertEquals(150, appliedLow)
        assertEquals(150, repository.getHeight())

        val appliedHigh = repository.setHeight(500)
        assertEquals(350, appliedHigh)
        assertEquals(350, repository.getHeight())
    }

    @Test
    fun testReset() {
        repository.setHeight(300)
        assertEquals(300, repository.getHeight())

        val defaultHeight = repository.reset()
        assertEquals(216, defaultHeight)
        assertEquals(216, repository.getHeight())
    }
}
