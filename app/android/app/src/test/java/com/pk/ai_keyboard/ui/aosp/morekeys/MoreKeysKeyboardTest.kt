package com.pk.ai_keyboard.ui.aosp.morekeys

import org.junit.Assert.*
import org.junit.Test

class MoreKeysKeyboardTest {

    @Test
    fun `MoreKeysKeyboard builds single row when keys fit in max columns`() {
        val (specs, _) = MoreKeySpec.parseMoreKeys("1,²,³")
        val parentKey = AospKey(x = 100, y = 200, width = 80, height = 100)

        val keyboard = MoreKeysKeyboard.Builder(
            parentKey = parentKey,
            moreKeysSpecs = specs,
            keyboardWidth = 1080,
            defaultKeyWidth = 80,
            defaultRowHeight = 100,
            maxColumns = 8
        ).build()

        assertEquals(3, keyboard.keys.size)
        assertEquals(240, keyboard.occupiedWidth)
        assertEquals(100, keyboard.occupiedHeight)

        // All keys on row 0
        assertEquals(0, keyboard.keys[0].y)
        assertEquals(0, keyboard.keys[1].y)
        assertEquals(0, keyboard.keys[2].y)

        // Verify sequential X
        assertEquals(0, keyboard.keys[0].x)
        assertEquals(80, keyboard.keys[1].x)
        assertEquals(160, keyboard.keys[2].x)
    }

    @Test
    fun `MoreKeysKeyboard builds multi-row grid when keys exceed max columns`() {
        val spec = ". , ? , ! , : , ; , ' , \" , - , _ , ( , ) , [ , ] , { , } , /"
        val (specs, _) = MoreKeySpec.parseMoreKeys(spec)
        assertEquals(16, specs.size)

        val parentKey = AospKey(x = 900, y = 500, width = 80, height = 100)

        val keyboard = MoreKeysKeyboard.Builder(
            parentKey = parentKey,
            moreKeysSpecs = specs,
            keyboardWidth = 1080,
            defaultKeyWidth = 80,
            defaultRowHeight = 100,
            maxColumns = 8
        ).build()

        assertEquals(16, keyboard.keys.size)
        // 16 keys with 8 maxColumns -> 2 rows of 8
        assertEquals(640, keyboard.occupiedWidth)
        assertEquals(200, keyboard.occupiedHeight)

        // Bottom row (row from bottom = 0 -> y = 100)
        assertEquals(100, keyboard.keys[0].y)
        // Top row (row from bottom = 1 -> y = 0)
        assertEquals(0, keyboard.keys[8].y)
    }

    @Test
    fun `MoreKeysKeyboard clamps within screen boundaries at right edge`() {
        val (specs, _) = MoreKeySpec.parseMoreKeys("1,2,3,4,5")
        // Parent key at the far right edge of screen
        val parentKey = AospKey(x = 1000, y = 200, width = 80, height = 100)
        val keyboardWidth = 1080

        val keyboard = MoreKeysKeyboard.Builder(
            parentKey = parentKey,
            moreKeysSpecs = specs,
            keyboardWidth = keyboardWidth,
            defaultKeyWidth = 80,
            defaultRowHeight = 100,
            maxColumns = 8
        ).build()

        // Total popup width = 5 * 80 = 400
        assertEquals(400, keyboard.occupiedWidth)
        // Check that popup fits within keyboard bounds:
        // Clamping logic: if left + 400 > 1080 -> left = 1080 - 400 = 680
        // defaultCoordX = parentCenterX - left = 1040 - 680 = 360
        assertEquals(360, keyboard.defaultCoordX)
    }

    @Test
    fun `MoreKeysKeyboard clamps within screen boundaries at left edge`() {
        val (specs, _) = MoreKeySpec.parseMoreKeys("1,2,3,4,5")
        // Parent key at the far left edge of screen
        val parentKey = AospKey(x = 0, y = 200, width = 80, height = 100)
        val keyboardWidth = 1080

        val keyboard = MoreKeysKeyboard.Builder(
            parentKey = parentKey,
            moreKeysSpecs = specs,
            keyboardWidth = keyboardWidth,
            defaultKeyWidth = 80,
            defaultRowHeight = 100,
            maxColumns = 8
        ).build()

        assertEquals(400, keyboard.occupiedWidth)
        // parentCenterX = 40. left = 40 - 200 = -160 -> clamped to 0.
        // defaultCoordX = 40 - 0 = 40.
        assertEquals(40, keyboard.defaultCoordX)
    }
}

