/*
 * Copyright (C) 2011 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.pk.atfix.ui.aosp.morekeys

import android.content.Context
import android.graphics.*
import android.util.AttributeSet
import android.util.TypedValue
import android.view.HapticFeedbackConstants
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import com.pk.atfix.ui.theme.KeyboardTheme
import kotlin.math.max
import kotlin.math.min

/**
 * A custom view that renders virtual keys in a [MoreKeysKeyboard] popup panel.
 * Handles Canvas-based drawing, dragging motion detection, real-time highlighting,
 * and release-to-commit selection.
 *
 * Adapted directly from AOSP LatinIME [MoreKeysKeyboardView.java].
 */
class MoreKeysKeyboardView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr), MoreKeysPanel {

    private var keyboard: MoreKeysKeyboard? = null
    private val keyDetector = MoreKeysDetector(slideAllowance = dpToPx(24f))
    private var controller: MoreKeysPanel.Controller = MoreKeysPanel.EMPTY_CONTROLLER
    private var listener: KeyboardActionListener? = null

    private var originX: Int = 0
    private var originY: Int = 0
    private var currentKey: AospKey? = null
    private var activePointerId: Int = -1

    private var theme: KeyboardTheme = KeyboardTheme.current(context)

    // Drawing resources
    private val panelPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val panelShadowPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val keyNormalPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val keyHighlightPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val textHighlightPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val dividerPaint = Paint(Paint.ANTI_ALIAS_FLAG)

    private val panelRect = RectF()
    private val keyRect = RectF()

    init {
        updateTheme(theme)
        val padH = dpToPx(6f).toInt()
        val padV = dpToPx(6f).toInt()
        setPadding(padH, padV, padH, padV)
    }

    fun updateTheme(newTheme: KeyboardTheme) {
        this.theme = newTheme

        // Panel background
        panelPaint.color = theme.backgroundColor
        panelPaint.style = Paint.Style.FILL

        panelShadowPaint.color = Color.argb(60, 0, 0, 0)
        panelShadowPaint.style = Paint.Style.STROKE
        panelShadowPaint.strokeWidth = dpToPx(1f)

        // Key states
        keyNormalPaint.color = theme.keyColor
        keyNormalPaint.style = Paint.Style.FILL

        keyHighlightPaint.color = theme.accentColor
        keyHighlightPaint.style = Paint.Style.FILL

        // Text
        textPaint.color = theme.textColor
        textPaint.textAlign = Paint.Align.CENTER
        textPaint.textSize = dpToPx(18f)
        textPaint.typeface = Typeface.create("sans-serif", Typeface.NORMAL)

        textHighlightPaint.color = Color.WHITE
        textHighlightPaint.textAlign = Paint.Align.CENTER
        textHighlightPaint.textSize = dpToPx(19f)
        textHighlightPaint.typeface = Typeface.create("sans-serif-medium", Typeface.BOLD)

        // Divider
        dividerPaint.color = Color.argb(40, 128, 128, 128)
        dividerPaint.style = Paint.Style.STROKE
        dividerPaint.strokeWidth = dpToPx(0.8f)

        invalidate()
    }

    fun setKeyboard(moreKeysKeyboard: MoreKeysKeyboard) {
        this.keyboard = moreKeysKeyboard
        keyDetector.setKeyboard(moreKeysKeyboard)
        requestLayout()
        invalidate()
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val kb = keyboard
        if (kb != null) {
            val width = kb.occupiedWidth + paddingLeft + paddingRight
            val height = kb.occupiedHeight + paddingTop + paddingBottom
            setMeasuredDimension(width, height)
        } else {
            super.onMeasure(widthMeasureSpec, heightMeasureSpec)
        }
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val kb = keyboard ?: return

        // 1. Draw rounded outer bubble panel
        val radius = dpToPx(12f)
        panelRect.set(0f, 0f, width.toFloat(), height.toFloat())
        canvas.drawRoundRect(panelRect, radius, radius, panelPaint)
        canvas.drawRoundRect(panelRect, radius, radius, panelShadowPaint)

        // 2. Draw each key inside the popup
        val textBaselineOffset = (textPaint.descent() + textPaint.ascent()) / 2f
        val keyCornerRadius = dpToPx(8f)

        for (key in kb.keys) {
            val left = (key.x + paddingLeft + dpToPx(2f))
            val top = (key.y + paddingTop + dpToPx(2f))
            val right = (key.x + key.width + paddingLeft - dpToPx(2f))
            val bottom = (key.y + key.height + paddingTop - dpToPx(2f))

            keyRect.set(left, top, right, bottom)

            val isSelected = (key == currentKey)
            val paint = if (isSelected) keyHighlightPaint else keyNormalPaint
            canvas.drawRoundRect(keyRect, keyCornerRadius, keyCornerRadius, paint)

            // Draw text label
            val currentTextPaint = if (isSelected) textHighlightPaint else textPaint
            val centerX = keyRect.centerX()
            val centerY = keyRect.centerY() - textBaselineOffset
            canvas.drawText(key.label, centerX, centerY, currentTextPaint)
        }
    }

    override fun showMoreKeysPanel(
        parentView: View,
        controller: MoreKeysPanel.Controller,
        pointX: Int,
        pointY: Int,
        listener: KeyboardActionListener
    ) {
        this.controller = controller
        this.listener = listener

        val kb = keyboard ?: return
        val panelWidth = kb.occupiedWidth + paddingLeft + paddingRight
        val panelHeight = kb.occupiedHeight + paddingTop + paddingBottom

        // Measure view if needed
        measure(
            MeasureSpec.makeMeasureSpec(panelWidth, MeasureSpec.EXACTLY),
            MeasureSpec.makeMeasureSpec(panelHeight, MeasureSpec.EXACTLY)
        )
        layout(0, 0, panelWidth, panelHeight)

        // Position popup horizontally centered over pointX, clamped within parentView width
        val parentWidth = parentView.width
        val minX = dpToPx(4f).toInt()
        val maxX = max(minX, parentWidth - panelWidth - dpToPx(4f).toInt())
        val idealX = pointX - kb.defaultCoordX - paddingLeft
        val clampedX = max(minX, min(maxX, idealX))

        // Position vertically directly above the parent key
        val idealY = pointY - panelHeight - dpToPx(6f).toInt()
        val clampedY = max(dpToPx(4f).toInt(), idealY)

        x = clampedX.toFloat()
        y = clampedY.toFloat()

        originX = clampedX + paddingLeft
        originY = clampedY + paddingTop

        controller.onShowMoreKeysPanel(this)
    }

    override fun onDownEvent(x: Int, y: Int, pointerId: Int, eventTime: Long) {
        activePointerId = pointerId
        currentKey = detectKey(x, y)
    }

    override fun onMoveEvent(x: Int, y: Int, pointerId: Int, eventTime: Long) {
        if (activePointerId != pointerId) return
        val oldKey = currentKey
        val newKey = detectKey(x, y)

        if (oldKey != null && newKey == null) {
            // Touch moved too far outside allowable slide bounds
            controller.onCancelMoreKeysPanel()
        }
    }

    override fun onUpEvent(x: Int, y: Int, pointerId: Int, eventTime: Long) {
        if (activePointerId != pointerId) return
        val selectedKey = detectKey(x, y) ?: currentKey

        if (selectedKey != null) {
            performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
            onKeyInput(selectedKey)
            currentKey = null
        }
        dismissMoreKeysPanel()
    }

    private fun detectKey(x: Int, y: Int): AospKey? {
        val oldKey = currentKey
        val newKey = keyDetector.detectHitKey(x, y)

        if (newKey != oldKey) {
            oldKey?.onReleased()
            newKey?.onPressed()
            currentKey = newKey
            if (newKey != null) {
                performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
            }
            invalidate()
        }
        return newKey
    }

    private fun onKeyInput(key: AospKey) {
        val currentListener = listener ?: return
        if (!key.outputText.isNullOrEmpty()) {
            currentListener.onTextInput(key.outputText)
        } else if (key.code != 0) {
            currentListener.onCodeInput(key.code, key.x, key.y, false)
        }
    }

    override fun dismissMoreKeysPanel() {
        if (!isShowingInParent()) return
        currentKey?.onReleased()
        currentKey = null
        controller.onDismissMoreKeysPanel()
    }

    override fun translateX(x: Int): Int = x - originX

    override fun translateY(y: Int): Int = y - originY

    override fun showInParent(parentView: ViewGroup) {
        removeFromParent()
        parentView.addView(this)
    }

    override fun removeFromParent() {
        val currentParent = parent as? ViewGroup
        currentParent?.removeView(this)
    }

    override fun isShowingInParent(): Boolean = parent != null

    private fun dpToPx(dp: Float): Float {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp,
            context.resources.displayMetrics
        )
    }
}

