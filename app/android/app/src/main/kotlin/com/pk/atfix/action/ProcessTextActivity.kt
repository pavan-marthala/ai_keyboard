package com.pk.atfix.action

import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.Button
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.lifecycle.lifecycleScope
import com.pk.atfix.R
import kotlinx.coroutines.launch

private const val TAG = "ProcessTextActivity"

/**
 * Android ACTION_PROCESS_TEXT entrypoint activity.
 *
 * Invoked when a user selects text in any application and chooses "AtFix"
 * from the system text-selection floating menu.
 */
class ProcessTextActivity : ComponentActivity() {

    private val controller = ProcessTextController()
    private var currentRequest: ProcessTextRequest? = null

    // UI elements
    private lateinit var tvTitle: TextView
    private lateinit var tvReadOnlyBadge: TextView
    private lateinit var btnClose: ImageButton
    private lateinit var tvSelectedText: TextView
    private lateinit var containerActions: LinearLayout
    private lateinit var btnFix: Button
    private lateinit var containerLoading: LinearLayout
    private lateinit var tvLoadingStatus: TextView
    private lateinit var containerResult: LinearLayout
    private lateinit var tvTransformedResult: TextView
    private lateinit var btnCopyResult: Button
    private lateinit var containerError: LinearLayout
    private lateinit var tvErrorMessage: TextView
    private lateinit var btnRetry: Button
    private lateinit var btnCancelError: Button

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Default result is CANCELED so closing without action preserves original text
        setResult(Activity.RESULT_CANCELED)

        val request = controller.extractRequest(intent)
        if (request == null) {
            finish()
            return
        }
        currentRequest = request

        Log.i(TAG, "onCreate: request = $request")
        setContentView(R.layout.activity_process_text)
        bindViews()
        populateUI(request)
    }

    override fun onStart() {
        super.onStart()
        window?.let { win ->
            val displayMetrics = resources.displayMetrics
            val targetWidth = (displayMetrics.widthPixels * 0.88).toInt().coerceAtMost(
                (420 * displayMetrics.density).toInt()
            )
            win.setLayout(targetWidth, android.view.WindowManager.LayoutParams.WRAP_CONTENT)
        }
    }

    private fun bindViews() {
        tvTitle = findViewById(R.id.tvTitle)
        tvReadOnlyBadge = findViewById(R.id.tvReadOnlyBadge)
        btnClose = findViewById(R.id.btnClose)
        tvSelectedText = findViewById(R.id.tvSelectedText)
        containerActions = findViewById(R.id.containerActions)
        btnFix = findViewById(R.id.btnFix)
        containerLoading = findViewById(R.id.containerLoading)
        tvLoadingStatus = findViewById(R.id.tvLoadingStatus)
        containerResult = findViewById(R.id.containerResult)
        tvTransformedResult = findViewById(R.id.tvTransformedResult)
        btnCopyResult = findViewById(R.id.btnCopyResult)
        containerError = findViewById(R.id.containerError)
        tvErrorMessage = findViewById(R.id.tvErrorMessage)
        btnRetry = findViewById(R.id.btnRetry)
        btnCancelError = findViewById(R.id.btnCancelError)

        btnClose.setOnClickListener {
            Log.i(TAG, "btnClose clicked: cancelling")
            setResult(Activity.RESULT_CANCELED)
            finish()
        }

        btnFix.setOnClickListener {
            Log.i(TAG, "btnFix clicked")
            triggerFixTransformation()
        }

        btnRetry.setOnClickListener {
            Log.i(TAG, "btnRetry clicked")
            triggerFixTransformation()
        }

        btnCancelError.setOnClickListener {
            Log.i(TAG, "btnCancelError clicked: cancelling")
            setResult(Activity.RESULT_CANCELED)
            finish()
        }
    }

    private fun populateUI(request: ProcessTextRequest) {
        tvSelectedText.text = request.selectedText
        if (request.isReadOnly) {
            tvReadOnlyBadge.visibility = View.VISIBLE
        } else {
            tvReadOnlyBadge.visibility = View.GONE
        }
    }

    private fun triggerFixTransformation() {
        val request = currentRequest ?: return
        Log.i(TAG, "triggerFixTransformation: starting @fix for '${request.selectedText}', isReadOnly=${request.isReadOnly}")

        // Switch to loading state
        containerActions.visibility = View.GONE
        containerError.visibility = View.GONE
        containerResult.visibility = View.GONE
        containerLoading.visibility = View.VISIBLE
        tvLoadingStatus.text = "Fixing grammar (@fix)..."

        lifecycleScope.launch {
            val result = controller.executeFix(this@ProcessTextActivity, request)
            Log.i(TAG, "triggerFixTransformation result: $result")
            containerLoading.visibility = View.GONE

            when (result) {
                is ProcessTextResult.Success -> {
                    handleTransformationSuccess(result)
                }
                is ProcessTextResult.Failure -> {
                    handleTransformationFailure(result.errorMessage)
                }
            }
        }
    }

    private fun handleTransformationSuccess(result: ProcessTextResult.Success) {
        Log.i(TAG, "handleTransformationSuccess: transformedText='${result.transformedText}', isReadOnly=${result.isReadOnly}")
        if (!result.isReadOnly) {
            // Editable text: return transformed text to caller for in-place replacement
            val resultIntent = controller.createSuccessResultIntent(result.transformedText)
            setResult(Activity.RESULT_OK, resultIntent)
            Log.i(TAG, "Editable text: setResult(RESULT_OK), finishing activity")
            finish()
        } else {
            // Read-only text: cannot be directly replaced; present result with Copy action
            Log.i(TAG, "Read-only text: displaying result UI")
            containerActions.visibility = View.GONE
            containerError.visibility = View.GONE
            containerResult.visibility = View.VISIBLE
            tvTransformedResult.text = result.transformedText

            btnCopyResult.setOnClickListener {
                Log.i(TAG, "btnCopyResult clicked")
                copyToClipboard(result.transformedText)
                Toast.makeText(this, "Copied to clipboard", Toast.LENGTH_SHORT).show()
                val resultIntent = controller.createSuccessResultIntent(result.transformedText)
                setResult(Activity.RESULT_OK, resultIntent)
                finish()
            }
        }
    }

    private fun handleTransformationFailure(errorMessage: String) {
        Log.w(TAG, "handleTransformationFailure: errorMessage='$errorMessage'")
        containerActions.visibility = View.GONE
        containerResult.visibility = View.GONE
        containerLoading.visibility = View.GONE
        containerError.visibility = View.VISIBLE
        tvErrorMessage.text = errorMessage
    }

    private fun copyToClipboard(text: String) {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
        val clip = ClipData.newPlainText("AtFix", text)
        clipboard?.setPrimaryClip(clip)
    }
}
