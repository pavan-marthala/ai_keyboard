package com.pk.atfix.action

import android.app.Activity
import android.content.ComponentName
import android.content.Intent
import android.os.SystemClock
import android.view.View
import android.widget.TextView
import androidx.test.core.app.ActivityScenario
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.runner.AndroidJUnit4
import androidx.test.runner.lifecycle.ActivityLifecycleMonitorRegistry
import androidx.test.runner.lifecycle.Stage
import com.pk.atfix.R
import com.pk.atfix.ai.AiFailure
import com.pk.atfix.ai.AiResult
import com.pk.atfix.ai.PromptRepository
import kotlinx.coroutines.CompletableDeferred
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

@RunWith(AndroidJUnit4::class)
class ProcessTextEndToEndTest {

    private val transformations = mapOf(
        "helo wrld" to "Hello world",
        "speling eror" to "spelling error"
    )

    @Before
    fun setUp() {
        installDeterministicController()
    }

    @After
    fun tearDown() {
        ProcessTextActivity.controllerFactoryForTests = null
    }

    private fun installDeterministicController(
        failure: AiFailure? = null,
        beforeResult: (suspend () -> Unit)? = null
    ) {
        ProcessTextActivity.controllerFactoryForTests = {
            ProcessTextController(
                promptRepositoryProvider = { PromptRepository() },
                transformExecutorFactory = {
                    TextTransformExecutor { text, _ ->
                        beforeResult?.invoke()
                        if (failure != null) {
                            AiResult.Failure(failure)
                        } else {
                            AiResult.Success(transformations[text] ?: "transformed: $text")
                        }
                    }
                }
            )
        }
    }

    private fun processTextIntent(text: String, readOnly: Boolean, autoFix: Boolean = false): Intent =
        Intent(Intent.ACTION_PROCESS_TEXT).apply {
            type = "text/plain"
            component = ComponentName("com.pk.atfix", "com.pk.atfix.action.ProcessTextActivity")
            putExtra(Intent.EXTRA_PROCESS_TEXT, text)
            putExtra(Intent.EXTRA_PROCESS_TEXT_READONLY, readOnly)
            putExtra(ProcessTextActivity.EXTRA_AUTO_FIX_FOR_TESTS, autoFix)
        }

    private fun launchHost(): ActivityScenario<ProcessTextHostTestActivity> =
        ActivityScenario.launch(ProcessTextHostTestActivity::class.java)

    @Test
    fun commandPickerShowsAllCanonicalCommands() {
        val scenario = ActivityScenario.launch<ProcessTextActivity>(
            processTextIntent("helo wrld", false)
        )
        scenario.onActivity {
            val list = it.findViewById<android.widget.LinearLayout>(R.id.sheetActionList)
            assertEquals(7, list.childCount)
            val chips = (0 until list.childCount).map { i ->
                list.getChildAt(i).findViewById<TextView>(R.id.actionCommand).text.toString()
            }
            assertTrue(chips.contains("@professional"))
            assertFalse(chips.contains("@pro"))
            assertTrue(chips.contains("@translate"))
        }
        scenario.close()
    }

    @Test
    fun editableSelectionIsReplacedAfterExplicitReplaceTap() {
        val scenario = launchHost()
        lateinit var host: ProcessTextHostTestActivity
        scenario.onActivity {
            host = it
            it.launchAtFix("helo wrld", readOnly = false)
        }

        waitForVisibleOnSheet(R.id.sheetReplace)
        clickButton(R.id.sheetReplace)

        assertTrue("Host never received a result", host.awaitResult())
        assertEquals(Activity.RESULT_OK, host.lastResultCode)
        assertEquals("Hello world", host.editText.text.toString())
        scenario.close()
    }

    @Test
    fun sheetShowsSelectedTextAndReadOnlyNote() {
        val scenario = ActivityScenario.launch<ProcessTextActivity>(
            processTextIntent("speling eror", true)
        )
        scenario.onActivity {
            assertEquals("speling eror", it.findViewById<TextView>(R.id.sheetSelectedText).text.toString())
            assertEquals(View.VISIBLE, it.findViewById<View>(R.id.sheetReadOnlyNote).visibility)
        }
        scenario.close()
    }

    @Test
    fun errorStateIsShownWhenTransformationFails() {
        installDeterministicController(AiFailure.MissingApiKey)
        val scenario = ActivityScenario.launch<ProcessTextActivity>(
            processTextIntent("helo wrld", false, autoFix = true)
        )
        waitForVisibleInScenario(scenario, R.id.sheetError)
        scenario.close()
    }

    @Test
    fun translateLanguagePickerRunsTranslation() {
        val scenario = ActivityScenario.launch<ProcessTextActivity>(
            processTextIntent("helo wrld", false)
        )
        scenario.onActivity {
            val list = it.findViewById<android.widget.LinearLayout>(R.id.sheetActionList)
            val translateRow = (0 until list.childCount).map { list.getChildAt(it) }
                .first { row -> row.findViewById<TextView>(R.id.actionCommand).text == "@translate" }
            translateRow.performClick()
        }
        scenario.onActivity {
            val list = it.findViewById<android.widget.LinearLayout>(R.id.sheetLanguageList)
            assertTrue(list.childCount > 0)
            val japanese = (0 until list.childCount).map { i -> list.getChildAt(i) }
                .first { row -> row.findViewById<TextView>(R.id.languageCommand).text == "@translate:ja" }
            japanese.performClick()
        }
        waitForVisibleInScenario(scenario, R.id.sheetCorrectedText)
        scenario.onActivity {
            assertEquals("@translate:ja", it.findViewById<TextView>(R.id.sheetResultCommand).text.toString())
        }
        scenario.close()
    }

    @Test
    fun readOnlyCopyDoesNotReturnReplacementText() {
        val scenario = ActivityScenario.launchActivityForResult<ProcessTextActivity>(
            processTextIntent("speling eror", true, autoFix = true)
        )

        waitForVisibleInScenario(scenario, R.id.sheetCopy)
        scenario.onActivity { it.findViewById<View>(R.id.sheetCopy).performClick() }

        val result = scenario.getResult()
        assertEquals(Activity.RESULT_CANCELED, result.resultCode)
        assertFalse(result.resultData?.hasExtra(Intent.EXTRA_PROCESS_TEXT) == true)
        scenario.close()
    }

    @Test
    fun cancelPreservesOriginalText() {
        val scenario = ActivityScenario.launchActivityForResult<ProcessTextActivity>(
            processTextIntent("helo wrld", false)
        )
        scenario.onActivity { it.findViewById<View>(R.id.sheetClose).performClick() }

        val result = scenario.getResult()
        assertEquals(Activity.RESULT_CANCELED, result.resultCode)
        assertFalse(result.resultData?.hasExtra(Intent.EXTRA_PROCESS_TEXT) == true)
        scenario.close()
    }

    @Test
    fun dimDismissalPreservesOriginalText() {
        val scenario = ActivityScenario.launchActivityForResult<ProcessTextActivity>(
            processTextIntent("helo wrld", false)
        )
        scenario.onActivity { it.findViewById<View>(R.id.sheetDim).performClick() }

        val result = scenario.getResult()
        assertEquals(Activity.RESULT_CANCELED, result.resultCode)
        assertFalse(result.resultData?.hasExtra(Intent.EXTRA_PROCESS_TEXT) == true)
        scenario.close()
    }

    @Test
    fun errorCancelPreservesOriginalText() {
        installDeterministicController(AiFailure.NetworkError)
        val scenario = ActivityScenario.launchActivityForResult<ProcessTextActivity>(
            processTextIntent("helo wrld", false, autoFix = true)
        )
        waitForVisibleInScenario(scenario, R.id.sheetErrorCancel)
        scenario.onActivity { it.findViewById<View>(R.id.sheetErrorCancel).performClick() }

        val result = scenario.getResult()
        assertEquals(Activity.RESULT_CANCELED, result.resultCode)
        assertFalse(result.resultData?.hasExtra(Intent.EXTRA_PROCESS_TEXT) == true)
        scenario.close()
    }

    @Test
    fun recreationDuringTransformationDoesNotApplyStaleResult() {
        val release = CompletableDeferred<Unit>()
        installDeterministicController(beforeResult = { release.await() })

        val scenario = ActivityScenario.launchActivityForResult<ProcessTextActivity>(
            processTextIntent("helo wrld", false, autoFix = true)
        )
        scenario.onActivity { it.recreate() }
        release.complete(Unit)

        scenario.onActivity {
            assertFalse("A stale result must not finish the activity after recreation", it.isFinishing)
        }
        scenario.close()
    }

    private fun waitForVisibleInScenario(
        scenario: ActivityScenario<ProcessTextActivity>,
        id: Int
    ) {
        val deadline = SystemClock.uptimeMillis() + 15_000
        while (SystemClock.uptimeMillis() < deadline) {
            var visible = false
            scenario.onActivity {
                visible = it.findViewById<View>(id)?.visibility == View.VISIBLE
            }
            if (visible) return
            Thread.sleep(100)
        }
        throw AssertionError("View $id did not become visible")
    }

    private fun resumedProcessTextActivity(): ProcessTextActivity? {
        var result: ProcessTextActivity? = null
        InstrumentationRegistry.getInstrumentation().runOnMainSync {
            result = ActivityLifecycleMonitorRegistry.getInstance()
                .getActivitiesInStage(Stage.RESUMED)
                .firstOrNull { it is ProcessTextActivity } as? ProcessTextActivity
        }
        return result
    }

    private fun waitForVisibleOnSheet(id: Int) {
        val deadline = SystemClock.uptimeMillis() + 15_000
        while (SystemClock.uptimeMillis() < deadline) {
            val activity = resumedProcessTextActivity()
            if (activity != null) {
                var visible = false
                InstrumentationRegistry.getInstrumentation().runOnMainSync {
                    visible = activity.findViewById<View>(id)?.visibility == View.VISIBLE
                }
                if (visible) return
            }
            Thread.sleep(100)
        }
        throw AssertionError("Sheet view $id did not become visible")
    }

    private fun clickButton(id: Int) {
        val activity = resumedProcessTextActivity()
            ?: throw AssertionError("ProcessTextActivity was not resumed")
        activity.runOnUiThread { activity.findViewById<View>(id)?.performClick() }
    }
}
