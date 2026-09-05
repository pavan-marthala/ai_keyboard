package com.pk.atfix.ui.aosp.morekeys

import org.junit.Assert.*
import org.junit.Test

class MoreKeysDetectorTest {

    @Test
    fun `detectHitKey directly detects key when touch is inside key bounds`() {
        val (specs, _) = MoreKeySpec.parseMoreKeys("A,B,C")
        val parentKey = AospKey(x = 100, y = 200, width = 80, height = 100)

        val keyboard = MoreKeysKeyboard.Builder(
            parentKey = parentKey,
            moreKeysSpecs = specs,
            keyboardWidth = 1080,
            defaultKeyWidth = 80,
            defaultRowHeight = 100,
            maxColumns = 8
        ).build()

        val detector = MoreKeysDetector()
        detector.setKeyboard(keyboard)

        // Key 0: x in [0, 80], y in [0, 100]
        val hitKey0 = detector.detectHitKey(40, 50)
        assertNotNull(hitKey0)
        assertEquals("A", hitKey0?.label)

        // Key 1: x in [80, 160], y in [0, 100]
        val hitKey1 = detector.detectHitKey(120, 50)
        assertNotNull(hitKey1)
        assertEquals("B", hitKey1?.label)
    }

    @Test
    fun `detectHitKey projects touch from below popup onto bottom row`() {
        // Multi-row grid: 16 keys in 2 rows of 8
        val spec = ". , ? , ! , : , ; , ' , \" , - , _ , ( , ) , [ , ] , { , } , /"
        val (specs, _) = MoreKeySpec.parseMoreKeys(spec)
        val parentKey = AospKey(x = 500, y = 600, width = 80, height = 100)

        val keyboard = MoreKeysKeyboard.Builder(
            parentKey = parentKey,
            moreKeysSpecs = specs,
            keyboardWidth = 1080,
            defaultKeyWidth = 80,
            defaultRowHeight = 100,
            maxColumns = 8
        ).build()

        val detector = MoreKeysDetector()
        detector.setKeyboard(keyboard)

        // Bottom row has keys 0..7 at y = 100
        // Touch below popup: y = 250 (which is > occupiedHeight of 200)
        // x = 40 (column 0)
        val hitKey = detector.detectHitKey(40, 250)
        assertNotNull(hitKey)
        assertEquals(".", hitKey?.label)
        assertEquals(100, hitKey?.y)
    }

    @Test
    fun `detectHitKey tracks horizontal sliding across bottom row`() {
        val (specs, _) = MoreKeySpec.parseMoreKeys("1,2,3,4,5")
        val parentKey = AospKey(x = 500, y = 600, width = 80, height = 100)

        val keyboard = MoreKeysKeyboard.Builder(
            parentKey = parentKey,
            moreKeysSpecs = specs,
            keyboardWidth = 1080,
            defaultKeyWidth = 80,
            defaultRowHeight = 100,
            maxColumns = 8
        ).build()

        val detector = MoreKeysDetector()
        detector.setKeyboard(keyboard)

        // Touch is below popup at y = 150 (occupiedHeight = 100)
        // Slide to x = 40 (col 0) -> "1"
        assertEquals("1", detector.detectHitKey(40, 150)?.label)

        // Slide to x = 120 (col 1) -> "2"
        assertEquals("2", detector.detectHitKey(120, 150)?.label)

        // Slide to x = 200 (col 2) -> "3"
        assertEquals("3", detector.detectHitKey(200, 150)?.label)

        // Slide to x = 280 (col 3) -> "4"
        assertEquals("4", detector.detectHitKey(280, 150)?.label)

        // Slide to x = 360 (col 4) -> "5"
        assertEquals("5", detector.detectHitKey(360, 150)?.label)
    }

    @Test
    fun `detectHitKey tracks sliding up into higher rows`() {
        val spec = ". , ? , ! , : , ; , ' , \" , - , _ , ( , ) , [ , ] , { , } , /"
        val (specs, _) = MoreKeySpec.parseMoreKeys(spec)
        val parentKey = AospKey(x = 500, y = 600, width = 80, height = 100)

        val keyboard = MoreKeysKeyboard.Builder(
            parentKey = parentKey,
            moreKeysSpecs = specs,
            keyboardWidth = 1080,
            defaultKeyWidth = 80,
            defaultRowHeight = 100,
            maxColumns = 8
        ).build()

        val detector = MoreKeysDetector()
        detector.setKeyboard(keyboard)

        // Slide up into top row (y in [0, 100]) at column 0 (x = 40)
        // Index 8 is the first key in the top row
        val topRowKey = detector.detectHitKey(40, 50)
        assertNotNull(topRowKey)
        assertEquals(0, topRowKey?.y)
        assertEquals("_", topRowKey?.label)
    }

    @Test
    fun `detectHitKey returns null when dragged far outside boundaries`() {
        val (specs, _) = MoreKeySpec.parseMoreKeys("A,B,C")
        val parentKey = AospKey(x = 100, y = 200, width = 80, height = 100)

        val keyboard = MoreKeysKeyboard.Builder(
            parentKey = parentKey,
            moreKeysSpecs = specs,
            keyboardWidth = 1080,
            defaultKeyWidth = 80,
            defaultRowHeight = 100,
            maxColumns = 8
        ).build()

        val detector = MoreKeysDetector()
        detector.setKeyboard(keyboard)

        // Far to the left
        assertNull(detector.detectHitKey(-200, 50))
        // Far to the right (occupiedWidth = 240)
        assertNull(detector.detectHitKey(600, 50))
        // Far below
        assertNull(detector.detectHitKey(40, 800))
        // Far above
        assertNull(detector.detectHitKey(40, -300))
    }
}

