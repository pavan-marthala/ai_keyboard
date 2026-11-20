package com.pk.atfix.action

import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.lifecycle.lifecycleScope
import com.pk.atfix.R
import com.pk.atfix.ai.PromptRepository
import kotlinx.coroutines.Job
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

private const val TAG = "ProcessTextActivity"

/**
 * ACTION_PROCESS_TEXT entrypoint. Presents AtFix as a native bottom sheet with
 * three parts: command picker, translate language picker, and result preview.
 */
class ProcessTextActivity : ComponentActivity() {

    companion object {
        /** Test-only: runs @fix immediately on creation so tests need no UI clicks. */
        const val EXTRA_AUTO_FIX_FOR_TESTS = "com.pk.atfix.action.AUTO_FIX_FOR_TESTS"

        /** Test-only seam supplying a deterministic controller. */
        @Volatile
        var controllerFactoryForTests: (() -> ProcessTextController)? = null
    }

    private data class ActionDisplay(
        val id: String,
        val title: String,
        val description: String,
        val iconRes: Int
    )

    private data class LanguageDisplay(
        val code: String,
        val name: String,
        val nativeName: String
    )

    // UI copy only. Command ids/triggers come from the generated definitions.
    private val actionDisplays = mapOf(
        "fix" to ActionDisplay("fix", "Fix Grammar", "Grammar, spelling, punctuation, caps", R.drawable.ic_done),
        "rewrite" to ActionDisplay("rewrite", "Rewrite", "Paraphrase, same meaning", R.drawable.ic_atfix_rewrite),
        "professional" to ActionDisplay("professional", "Professional Tone", "Formal, clear workplace tone", R.drawable.ic_atfix_professional),
        "casual" to ActionDisplay("casual", "Casual Tone", "Friendly, conversational phrasing", R.drawable.ic_atfix_casual),
        "short" to ActionDisplay("short", "Shorten", "Condense into a concise version", R.drawable.ic_atfix_shorten),
        "expand" to ActionDisplay("expand", "Expand", "Add detail and clarity, no new claims", R.drawable.ic_atfix_expand),
        "translate" to ActionDisplay("translate", "Translate", "Choose a target language", R.drawable.ic_atfix_translate)
    )

    private val suggestedLanguages = listOf(
        LanguageDisplay("es", "Spanish", "Español"),
        LanguageDisplay("hi", "Hindi", "हिन्दी"),
        LanguageDisplay("fr", "French", "Français"),
        LanguageDisplay("de", "German", "Deutsch"),
        LanguageDisplay("te", "Telugu", "తెలుగు"),
        LanguageDisplay("ja", "Japanese", "日本語"),
        LanguageDisplay("pt", "Portuguese", "Português")
    )

    private val controller: ProcessTextController =
        controllerFactoryForTests?.invoke() ?: ProcessTextController()

    private var currentRequest: ProcessTextRequest? = null
    private var resultDelivered = false
    private var transformationJob: Job? = null
    private var lastTrigger: String = "@fix"
    private var lastLanguageCode: String? = null
    private var lastTransformedText: String = ""

    private lateinit var sheetDim: View
    private lateinit var sheetContent: FrameLayout
    private lateinit var sheetLoading: LinearLayout
    private lateinit var sheetLoadingText: TextView
    private lateinit var sheetError: LinearLayout
    private lateinit var sheetErrorMessage: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(Activity.RESULT_CANCELED)

        val request = controller.extractRequest(intent)
        if (request == null) {
            deliverCanceledResult()
            return
        }
        currentRequest = request

        setContentView(R.layout.sheet_process_text)
        bindRootViews()
        showActions()

        if (intent.getBooleanExtra(EXTRA_AUTO_FIX_FOR_TESTS, false)) {
            runTransformation("@fix", null)
        }
    }

    private fun bindRootViews() {
        sheetDim = findViewById(R.id.sheetDim)
        sheetContent = findViewById(R.id.sheetContent)
        sheetLoading = findViewById(R.id.sheetLoading)
        sheetLoadingText = findViewById(R.id.sheetLoadingText)
        sheetError = findViewById(R.id.sheetError)
        sheetErrorMessage = findViewById(R.id.sheetErrorMessage)

        sheetDim.setOnClickListener { deliverCanceledResult() }
        findViewById<View>(R.id.sheetRetry).setOnClickListener { retryTransformation() }
        findViewById<View>(R.id.sheetErrorCancel).setOnClickListener { deliverCanceledResult() }
    }

    private fun showScreen(view: View) {
        sheetContent.removeAllViews()
        sheetContent.addView(view)
        sheetContent.visibility = View.VISIBLE
        sheetLoading.visibility = View.GONE
        sheetError.visibility = View.GONE
    }

    private fun showLoading(message: String) {
        sheetContent.visibility = View.GONE
        sheetError.visibility = View.GONE
        sheetLoadingText.text = message
        sheetLoading.visibility = View.VISIBLE
    }

    private fun showError(message: String) {
        Log.w(TAG, "showError: $message")
        sheetContent.visibility = View.GONE
        sheetLoading.visibility = View.GONE
        sheetErrorMessage.text = message
        sheetError.visibility = View.VISIBLE
    }

    private fun showActions() {
        val view = LayoutInflater.from(this)
            .inflate(R.layout.sheet_content_actions, sheetContent, false)
        val selectedText = currentRequest?.selectedText.orEmpty()
        view.findViewById<TextView>(R.id.sheetSelectedText).text = selectedText
        view.findViewById<View>(R.id.sheetReadOnlyNote).visibility =
            if (currentRequest?.isReadOnly == true) View.VISIBLE else View.GONE
        view.findViewById<View>(R.id.sheetClose).setOnClickListener { deliverCanceledResult() }

        val list = view.findViewById<LinearLayout>(R.id.sheetActionList)
        list.removeAllViews()
        val commands = PromptRepository.getInstance(this).getCommands()
        for (definition in commands) {
            val display = actionDisplays[definition.id] ?: continue
            val row = LayoutInflater.from(this)
                .inflate(R.layout.item_sheet_action, list, false)
            row.findViewById<ImageView>(R.id.actionIcon).setImageResource(display.iconRes)
            row.findViewById<TextView>(R.id.actionTitle).text = display.title
            row.findViewById<TextView>(R.id.actionDescription).text = display.description
            row.findViewById<TextView>(R.id.actionCommand).text =
                if (definition.id == "translate") "@translate" else definition.command
            if (list.childCount == 0) {
                row.findViewById<View>(R.id.actionRow).setBackgroundResource(R.drawable.bg_atfix_row_highlighted)
            }
            row.setOnClickListener {
                if (definition.id == "translate") {
                    showLanguages()
                } else {
                    runTransformation(definition.command, null)
                }
            }
            list.addView(row)
        }
        showScreen(view)
    }

    private fun showLanguages() {
        val view = LayoutInflater.from(this)
            .inflate(R.layout.sheet_content_languages, sheetContent, false)
        view.findViewById<View>(R.id.sheetBack).setOnClickListener { showActions() }

        val list = view.findViewById<LinearLayout>(R.id.sheetLanguageList)
        val empty = view.findViewById<TextView>(R.id.sheetNoLanguages)
        val search = view.findViewById<EditText>(R.id.sheetLanguageSearch)

        fun render(query: String) {
            list.removeAllViews()
            val filtered = suggestedLanguages.filter { language ->
                language.name.contains(query, true) ||
                    language.nativeName.contains(query, true) ||
                    language.code.contains(query, true)
            }
            empty.visibility = if (filtered.isEmpty()) View.VISIBLE else View.GONE
            filtered.forEachIndexed { index, language ->
                val row = LayoutInflater.from(this)
                    .inflate(R.layout.item_sheet_language, list, false)
                row.findViewById<TextView>(R.id.languageName).text = language.name
                row.findViewById<TextView>(R.id.languageNative).text = language.nativeName
                row.findViewById<TextView>(R.id.languageCommand).text = "@translate:${language.code}"
                if (index == 0) {
                    row.findViewById<View>(R.id.languageRow).setBackgroundResource(R.drawable.bg_atfix_row_highlighted)
                }
                row.setOnClickListener { runTransformation("@translate", language.code) }
                list.addView(row)
            }
        }

        search.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) = Unit
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) = Unit
            override fun afterTextChanged(s: Editable?) = render(s?.toString().orEmpty())
        })
        render("")
        showScreen(view)
    }

    private fun showResult(text: String, trigger: String, languageCode: String?) {
        Log.i(TAG, "showResult: trigger=$trigger, length=${text.length}")
        lastTransformedText = text
        val view = LayoutInflater.from(this)
            .inflate(R.layout.sheet_content_result, sheetContent, false)
        val display = actionDisplays.values.firstOrNull {
            trigger.equals("@${it.id}", ignoreCase = true)
        }
        view.findViewById<TextView>(R.id.sheetResultTitle).text = display?.title ?: "Result"
        view.findViewById<TextView>(R.id.sheetResultCommand).text =
            if (languageCode != null) "$trigger:$languageCode" else trigger
        view.findViewById<TextView>(R.id.sheetOriginalText).text = currentRequest?.selectedText.orEmpty()
        view.findViewById<TextView>(R.id.sheetCorrectedText).text = text

        view.findViewById<View>(R.id.sheetResultBack).setOnClickListener { showActions() }
        view.findViewById<Button>(R.id.sheetReplace).setOnClickListener {
            if (currentRequest?.isReadOnly == true) {
                copyToClipboard(text)
                Toast.makeText(this, "Copied — this text is read-only", Toast.LENGTH_SHORT).show()
                deliverCanceledResult()
            } else {
                deliverResult(Activity.RESULT_OK, controller.createSuccessResultIntent(text))
            }
        }
        view.findViewById<Button>(R.id.sheetCopy).setOnClickListener {
            copyToClipboard(text)
            Toast.makeText(this, "Copied to clipboard", Toast.LENGTH_SHORT).show()
            deliverCanceledResult()
        }
        view.findViewById<Button>(R.id.sheetTryAgain).setOnClickListener {
            runTransformation(trigger, languageCode)
        }
        showScreen(view)
    }

    private fun runTransformation(trigger: String, languageCode: String?) {
        val request = currentRequest ?: return
        if (resultDelivered || isFinishing) return

        Log.i(TAG, "runTransformation: trigger=$trigger, language=$languageCode")
        lastTrigger = trigger
        lastLanguageCode = languageCode
        transformationJob?.cancel()

        val display = actionDisplays.values.firstOrNull { trigger.equals("@${it.id}", ignoreCase = true) }
        showLoading("${display?.title ?: "Transforming"}…")

        transformationJob = lifecycleScope.launch {
            val result = controller.executeCommand(this@ProcessTextActivity, request, trigger, languageCode)
            if (!isActive || resultDelivered || isFinishing) {
                Log.i(TAG, "Discarding transformation result: activity no longer active")
                return@launch
            }
            when (result) {
                is ProcessTextResult.Success -> showResult(result.transformedText, result.trigger, languageCode)
                is ProcessTextResult.Failure -> showError(result.errorMessage)
            }
        }
    }

    private fun retryTransformation() = runTransformation(lastTrigger, lastLanguageCode)

    private fun copyToClipboard(text: String) {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
        clipboard?.setPrimaryClip(ClipData.newPlainText("AtFix", text))
    }

    /** Delivers at most one result so a late callback cannot replace host text twice. */
    private fun deliverResult(resultCode: Int, data: Intent? = null) {
        if (resultDelivered) return
        resultDelivered = true
        if (data == null) setResult(resultCode) else setResult(resultCode, data)
        finish()
    }

    private fun deliverCanceledResult() = deliverResult(Activity.RESULT_CANCELED)

    override fun onDestroy() {
        transformationJob?.cancel()
        transformationJob = null
        super.onDestroy()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        deliverCanceledResult()
    }
}
