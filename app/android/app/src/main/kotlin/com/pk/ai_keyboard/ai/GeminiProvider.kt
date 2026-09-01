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

class GeminiProvider : AiProvider {

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

        val modelId = if (model.isBlank()) "gemini-1.5-flash" else model
        val endpointUrl = if (!baseUrl.isNullOrBlank()) {
            baseUrl
        } else {
            "https://generativelanguage.googleapis.com/v1beta/models/$modelId:generateContent?key=$apiKey"
        }

        val jsonPayload = JSONObject().apply {
            val parts = JSONArray().apply {
                put(JSONObject().apply {
                    put("text", "$prompt\n\nUser Input:\n$text")
                })
            }
            val contents = JSONArray().apply {
                put(JSONObject().apply {
                    put("parts", parts)
                })
            }
            put("contents", contents)
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
                val candidates = jsonResponse.optJSONArray("candidates")
                if (candidates != null && candidates.length() > 0) {
                    val firstCandidate = candidates.getJSONObject(0)
                    val contentObj = firstCandidate.optJSONObject("content")
                    val parts = contentObj?.optJSONArray("parts")
                    if (parts != null && parts.length() > 0) {
                        val textResult = parts.getJSONObject(0).optString("text").trim()
                        if (!textResult.isNullOrBlank()) {
                            val cleaned = textResult.removePrefix("\"").removeSuffix("\"").trim()
                            return@withContext AiResult.Success(cleaned)
                        }
                    }
                }
                return@withContext AiResult.Failure(AiFailure.InvalidResponse)
            } else if (statusCode == 400 || statusCode == 403) {
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

