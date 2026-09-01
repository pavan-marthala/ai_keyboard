package com.pk.ai_keyboard.ai

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

open class OpenAiProvider : AiProvider {

    override suspend fun transform(
        text: String,
        prompt: String,
        model: String,
        apiKey: String,
        baseUrl: String?
    ): AiResult<String> = withContext(Dispatchers.IO) {
        if (apiKey.isBlank()) {
            return@withContext AiResult.Failure(AiFailure.MissingApiKey)
        }

        val endpointUrl = if (!baseUrl.isNullOrBlank()) baseUrl else "https://api.openai.com/v1/chat/completions"

        val jsonPayload = JSONObject().apply {
            put("model", model.ifBlank { "gpt-4o-mini" })
            put("temperature", 0.0)
            put("max_tokens", 1024)
            val messages = JSONArray().apply {
                put(JSONObject().apply {
                    put("role", "system")
                    put("content", prompt)
                })
                put(JSONObject().apply {
                    put("role", "user")
                    put("content", text)
                })
            }
            put("messages", messages)
        }

        var connection: HttpURLConnection? = null
        try {
            val url = URL(endpointUrl)
            connection = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                connectTimeout = 15000
                readTimeout = 20000
                doOutput = true
                setRequestProperty("Content-Type", "application/json; charset=UTF-8")
                setRequestProperty("Authorization", "Bearer $apiKey")
            }

            OutputStreamWriter(connection.outputStream, "UTF-8").use { writer ->
                writer.write(jsonPayload.toString())
                writer.flush()
            }

            val statusCode = connection.responseCode
            if (statusCode == 200) {
                val reader = BufferedReader(InputStreamReader(connection.inputStream, "UTF-8"))
                val responseString = reader.readText()
                reader.close()

                val jsonResponse = JSONObject(responseString)
                val choices = jsonResponse.optJSONArray("choices")
                if (choices != null && choices.length() > 0) {
                    val firstChoice = choices.getJSONObject(0)
                    val message = firstChoice.optJSONObject("message")
                    val content = message?.optString("content")?.trim()

                    if (!content.isNullOrBlank()) {
                        val cleanedContent = content.removePrefix("\"").removeSuffix("\"").trim()
                        return@withContext AiResult.Success(cleanedContent)
                    }
                }
                return@withContext AiResult.Failure(AiFailure.InvalidResponse)
            } else if (statusCode == 401) {
                return@withContext AiResult.Failure(AiFailure.InvalidApiKey)
            } else {
                val errorStream = connection.errorStream
                val errorMsg = if (errorStream != null) {
                    BufferedReader(InputStreamReader(errorStream, "UTF-8")).use { it.readText() }
                } else {
                    "HTTP $statusCode Error"
                }
                return@withContext AiResult.Failure(AiFailure.HttpError(statusCode, errorMsg))
            }
        } catch (e: java.net.SocketTimeoutException) {
            return@withContext AiResult.Failure(AiFailure.Timeout)
        } catch (e: java.io.IOException) {
            return@withContext AiResult.Failure(AiFailure.NetworkError)
        } catch (e: Exception) {
            return@withContext AiResult.Failure(AiFailure.InvalidResponse)
        } finally {
            connection?.disconnect()
        }
    }
}

