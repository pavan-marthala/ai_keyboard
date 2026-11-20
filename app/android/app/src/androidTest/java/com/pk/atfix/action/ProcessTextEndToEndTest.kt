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
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import kotlinx.coroutines.CompletableDeferred
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

    private fun processTextIntent(text: String, readOnly: Boolean): Intent =
        Intent(Intent.ACTION_PROCESS_TEXT).apply {
            type = "text/plain"
            component = ComponentName("com.pk.atfix", "com.pk.atfix.action.ProcessTextActivity")
            putExtra(Intent.EXTRA_PROCESS_TEXT, text)
            putExtra(Intent.EXTRA_PROCESS_TEXT_READONLY, readOnly)
        }

    private fun launchHost(): ActivityScenario<ProcessTextHostTestActivity> =
        ActivityScenario.launch(ProcessTextHostTestActivity::class.java)

    @Test
    fun editableSelectionIsReplacedInHostField() {
        val scenario = launchHost()
        lateinit var host: ProcessTextHostTestActivity
        scenario.onActivity {
            host = it
            it.launchAtFix("helo wrld", readOnly = false)
        }

        assertTrue("Host never received a result", host.awaitResult())
        assertEquals(Activity.RESULT_OK, host.lastResultCode)
        assertEquals("Hello world", host.editText.text.toString())
        scenario.close()
    }

    @Test
    fun dialogShowsSelectedTextAndReadOnlyBadge() {
        val scenario = ActivityScenario.launch<ProcessTextActivity>(processTextIntent("speling eror", true))
        scenario.onActivity {
            assertEquals("speling eror", it.findViewById<TextView>(R.id.tvSelectedText).text.toString())
            assertEquals(View.VISIBLE, it.findViewById<View>(R.id.tvReadOnlyBadge).visibility)
        }
        scenario.close()
    }

    @Test
    fun errorStateIsShownWhenTransformationFails() {
        installDeterministicController(AiFailure.MissingApiKey)
        val scenario = ActivityScenario.launch<ProcessTextActivity>(processTextIntent("helo wrld", false))
        scenario.onActivity { it.findViewById<View>(R.id.btnFix).performClick() }
        scenario.onActivity {
            assertEquals(View.VISIBLE, it.findViewById<View>(R.id.containerError).visibility)
        }
        scenario.close()
    }

    @Test
    fun readOnlyResultCanBeCopiedWithoutModifyingOrigin() {
        val scenario = ActivityScenario.launchActivityForResult<ProcessTextActivity>(
            processTextIntent("speling eror", true).apply {
                putExtra(ProcessTextActivity.EXTRA_AUTO_FIX_FOR_TESTS, true)
            }
        )

        waitForVisibleInScenario(scenario, R.id.containerResult)
        scenario.onActivity { it.findViewById<View>(R.id.btnCopyResult).performClick() }

        val result = scenario.getResult()
        assertEquals(Activity.RESULT_OK, result.resultCode)
        assertEquals("spelling error", result.resultData?.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT).toString())
        // Clipboard *content* cannot be asserted reliably from an instrumented,
        // headless context (Android restricts clipboard writes to foreground
        // user-initiated contexts). The copy action's result is asserted above;
        // clipboard contents are covered by the manual matrix.
        scenario.close()
    }

    @Test
    fun cancelPreservesOriginalText() {
        val scenario = ActivityScenario.launchActivityForResult<ProcessTextActivity>(processTextIntent("helo wrld", false))
        scenario.onActivity { it.findViewById<View>(R.id.btnClose).performClick() }

        val result = scenario.getResult()
        assertEquals(Activity.RESULT_CANCELED, result.resultCode)
        assertFalse(result.resultData?.hasExtra(Intent.EXTRA_PROCESS_TEXT) == true)
        scenario.close()
    }

    @Test
    fun dismissalPreservesOriginalText() {
        val scenario = ActivityScenario.launchActivityForResult<ProcessTextActivity>(
            processTextIntent("helo wrld", false)
        )
        scenario.onActivity { it.finish() }

        val result = scenario.getResult()
        assertEquals(Activity.RESULT_CANCELED, result.resultCode)
        assertFalse(result.resultData?.hasExtra(Intent.EXTRA_PROCESS_TEXT) == true)
        scenario.close()
    }

    @Test
    fun errorCancelPreservesOriginalText() {
        installDeterministicController(AiFailure.NetworkError)
        val scenario = ActivityScenario.launchActivityForResult<ProcessTextActivity>(processTextIntent("helo wrld", false))
        scenario.onActivity { it.findViewById<View>(R.id.btnFix).performClick() }
        scenario.onActivity { it.findViewById<View>(R.id.btnCancelError).performClick() }

        val result = scenario.getResult()
        assertEquals(Activity.RESULT_CANCELED, result.resultCode)
        assertFalse(result.resultData?.hasExtra(Intent.EXTRA_PROCESS_TEXT) == true)
        scenario.close()
    }

    @Test
    fun recreationDuringTransformationDoesNotApplyStaleResult() {
        val started = CountDownLatch(1)
        val release = CompletableDeferred<Unit>()
        installDeterministicController(beforeResult = {
            started.countDown()
            release.await()
        })

        val scenario = ActivityScenario.launchActivityForResult<ProcessTextActivity>(processTextIntent("helo wrld", false))
        scenario.onActivity { it.findViewById<View>(R.id.btnFix).performClick() }
        assertTrue(started.await(5, TimeUnit.SECONDS))

        scenario.onActivity { it.recreate() }
        release.complete(Unit)

        // A stale result would have finished the activity with RESULT_OK.
        waitForVisibleInScenario(scenario, R.id.containerActions)
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
                visible = it.findViewById<View>(id).visibility == View.VISIBLE
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

    private fun clickButton(id: Int) {
        val activity = resumedProcessTextActivity()
            ?: throw AssertionError("ProcessTextActivity was not resumed")
        activity.runOnUiThread { activity.findViewById<View>(id).performClick() }
    }

}
