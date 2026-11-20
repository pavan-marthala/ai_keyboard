package com.pk.atfix.action

import android.app.Activity
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import android.widget.EditText
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Test-only host activity used by instrumentation to behave like a standard editable
 * PROCESS_TEXT host: it selects its own text, launches AtFix, and applies the returned
 * text to the selection. It is registered in the manifest with no intent filter and
 * exported=false, so it is never reachable in normal app usage.
 */
class ProcessTextHostTestActivity : Activity() {

    lateinit var editText: EditText
        private set

    var lastResultCode: Int? = null
        private set

    private var resultLatch = CountDownLatch(1)
    private var applyReplacement = true

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        editText = EditText(this).apply { id = android.R.id.edit }
        setContentView(editText)
    }

    fun launchAtFix(text: String, readOnly: Boolean, applyReplacement: Boolean = true) {
        editText.setText(text)
        editText.setSelection(0, text.length)
        resultLatch = CountDownLatch(1)
        lastResultCode = null
        this.applyReplacement = applyReplacement

        val intent = Intent(Intent.ACTION_PROCESS_TEXT).apply {
            type = "text/plain"
            component = ComponentName(
                "com.pk.atfix",
                "com.pk.atfix.action.ProcessTextActivity"
            )
            putExtra(Intent.EXTRA_PROCESS_TEXT, text)
            putExtra(Intent.EXTRA_PROCESS_TEXT_READONLY, readOnly)
            putExtra(ProcessTextActivity.EXTRA_AUTO_FIX_FOR_TESTS, true)
        }
        @Suppress("DEPRECATION")
        startActivityForResult(intent, REQUEST_CODE)
    }

    fun awaitResult(timeoutSeconds: Long = 15): Boolean =
        resultLatch.await(timeoutSeconds, TimeUnit.SECONDS)

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_CODE) return

        lastResultCode = resultCode
        if (resultCode == Activity.RESULT_OK) {
            val replacement = data?.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
            if (applyReplacement && !replacement.isNullOrEmpty()) {
                val start = editText.selectionStart.coerceAtLeast(0)
                val end = editText.selectionEnd.coerceAtLeast(0)
                editText.text.replace(start, end, replacement)
            }
        }
        resultLatch.countDown()
    }

    companion object {
        private const val REQUEST_CODE = 42
    }
}
