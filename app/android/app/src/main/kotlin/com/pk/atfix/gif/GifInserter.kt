package com.pk.atfix.gif

import android.content.ClipDescription
import android.content.Context
import android.net.Uri
import android.util.Log
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputConnection
import androidx.core.content.FileProvider
import androidx.core.view.inputmethod.EditorInfoCompat
import androidx.core.view.inputmethod.InputConnectionCompat
import androidx.core.view.inputmethod.InputContentInfoCompat
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL

sealed class GifInsertionResult {
    object Success : GifInsertionResult()
    object UnsupportedEditor : GifInsertionResult()
    object Failed : GifInsertionResult()
}

class GifInserter(private val context: Context) {

    companion object {
        private const val TAG = "GifInserter"
    }

    suspend fun insertGif(
        inputConnection: InputConnection?,
        editorInfo: EditorInfo?,
        gifItem: GifItem
    ): GifInsertionResult = withContext(Dispatchers.IO) {
        if (inputConnection == null || editorInfo == null) {
            return@withContext GifInsertionResult.Failed
        }

        // 1. Check if target editor accepts image/gif rich content
        val mimeTypes = EditorInfoCompat.getContentMimeTypes(editorInfo)
        val supportsGif = mimeTypes.any { ClipDescription.compareMimeTypes(it, "image/gif") }
        if (!supportsGif) {
            Log.w(TAG, "Target editor does not accept image/gif rich content")
            return@withContext GifInsertionResult.UnsupportedEditor
        }

        // 2. Download GIF file to cacheDir/gifs/
        val gifFile = downloadGifToCache(gifItem) ?: return@withContext GifInsertionResult.Failed

        // 3. Generate FileProvider URI
        val contentUri: Uri = try {
            FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                gifFile
            )
        } catch (e: Exception) {
            Log.w(TAG, "Failed to generate FileProvider content URI")
            return@withContext GifInsertionResult.Failed
        }

        // 4. Commit rich content to InputConnection
        val description = ClipDescription(gifItem.title ?: "GIF", arrayOf("image/gif"))
        val contentInfo = InputContentInfoCompat(contentUri, description, null)

        var flags = InputConnectionCompat.INPUT_CONTENT_GRANT_READ_URI_PERMISSION
        val committed = try {
            InputConnectionCompat.commitContent(
                inputConnection,
                editorInfo,
                contentInfo,
                flags,
                null
            )
        } catch (e: Exception) {
            Log.w(TAG, "InputConnectionCompat commitContent exception")
            false
        }

        if (committed) {
            // Trigger GIPHY onsend analytics pingback silently
            pingAnalyticsUrl(gifItem.sendAnalyticsUrl)
            GifInsertionResult.Success
        } else {
            GifInsertionResult.Failed
        }
    }

    private fun downloadGifToCache(gifItem: GifItem): File? {
        return try {
            val gifsDir = File(context.cacheDir, "gifs").apply { if (!exists()) mkdirs() }
            val targetFile = File(gifsDir, "gif_${gifItem.id}.gif")

            if (targetFile.exists() && targetFile.length() > 0) {
                return targetFile
            }

            val url = URL(gifItem.contentUrl)
            val connection = (url.openConnection() as HttpURLConnection).apply {
                connectTimeout = 10000
                readTimeout = 10000
                doInput = true
            }

            if (connection.responseCode in 200..299) {
                connection.inputStream.use { input ->
                    FileOutputStream(targetFile).use { output ->
                        input.copyTo(output)
                    }
                }
                targetFile
            } else {
                null
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to download GIF to cache")
            null
        }
    }

    private fun pingAnalyticsUrl(analyticsUrl: String?) {
        if (analyticsUrl.isNullOrBlank()) return
        try {
            val url = URL(analyticsUrl)
            val connection = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "GET"
                connectTimeout = 5000
                readTimeout = 5000
            }
            connection.responseCode
            connection.disconnect()
        } catch (e: Exception) {
            // Ignore analytics ping failures silently
        }
    }
}

