package com.pk.ai_keyboard.ui.aosp.morekeys

import org.junit.Assert.*
import org.junit.Test

class MoreKeySpecTest {

    @Test
    fun `parseMoreKeys correctly parses comma separated single alternatives`() {
        val (specs, hasNoPanelAuto) = MoreKeySpec.parseMoreKeys("1")
        assertFalse(hasNoPanelAuto)
        assertEquals(1, specs.size)
        assertEquals("1", specs[0].label)
        assertEquals("1"[0].code, specs[0].code)
    }

    @Test
    fun `parseMoreKeys correctly parses multiple alternatives`() {
        val (specs, hasNoPanelAuto) = MoreKeySpec.parseMoreKeys("1,¹,₁")
        assertFalse(hasNoPanelAuto)
        assertEquals(3, specs.size)
        assertEquals("1", specs[0].label)
        assertEquals("¹", specs[1].label)
        assertEquals("₁", specs[2].label)
    }

    @Test
    fun `parseMoreKeys detects noPanelAutoMoreKey flag`() {
        val (specs, hasNoPanelAuto) = MoreKeySpec.parseMoreKeys("!noPanelAutoMoreKey!,1")
        assertTrue(hasNoPanelAuto)
        assertEquals(1, specs.size)
        assertEquals("1", specs[0].label)
    }

    @Test
    fun `parseMoreKeys correctly parses escaped characters`() {
        // Escaped comma: "\,"
        val (specs, _) = MoreKeySpec.parseMoreKeys("a,\\,,b")
        assertEquals(3, specs.size)
        assertEquals("a", specs[0].label)
        assertEquals(",", specs[1].label)
        assertEquals("b", specs[2].label)
    }

    @Test
    fun `parseMoreKeys handles full comma key special characters set`() {
        val spec = ". , ? , ! , : , ; , ' , \" , - , _ , ( , ) , [ , ] , { , } , / , \\\\ , @ , # , $ , % , & , * , + , = , < , > , ~ , ^ , | , € , £ , ¥ , ₹"
        val (specs, hasNoPanelAuto) = MoreKeySpec.parseMoreKeys(spec)
        assertFalse(hasNoPanelAuto)
        assertEquals(34, specs.size)

        // Verify key punctuation
        assertEquals(".", specs[0].label)
        assertEquals("?", specs[1].label)
        assertEquals("!", specs[2].label)
        assertEquals("\\", specs[16].label)
        assertEquals("@", specs[17].label)
        assertEquals("€", specs[30].label)
        assertEquals("₹", specs[33].label)
    }

    @Test
    fun `parseMoreKeys deduplicates identical alternatives`() {
        val (specs, _) = MoreKeySpec.parseMoreKeys("1,1,1,2,2")
        assertEquals(2, specs.size)
        assertEquals("1", specs[0].label)
        assertEquals("2", specs[1].label)
    }
}

