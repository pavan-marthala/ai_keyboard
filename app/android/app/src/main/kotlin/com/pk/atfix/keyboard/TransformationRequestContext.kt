package com.pk.atfix.keyboard

import java.util.UUID

data class TransformationRequestContext(
    val requestId: String = UUID.randomUUID().toString(),
    val sessionId: Long,
    val submittedText: String,
    val isSelectionTransform: Boolean = false,
    val selectionStart: Int = 0,
    val selectionEnd: Int = 0
)

