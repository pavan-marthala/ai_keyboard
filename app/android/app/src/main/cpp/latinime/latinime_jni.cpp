/*
 * Copyright (C) 2014 The Android Open Source Project
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

#include <jni.h>
#include <string>
#include <vector>
#include <memory>
#include "defines.h"
#include "dictionary_facade.h"
#include "proximity_info.h"

extern "C" {

JNIEXPORT jlong JNICALL
Java_com_pk_ai_1keyboard_suggestion_aosp_NativeBinaryDictionary_openNative(
    JNIEnv *env, jclass clazz, jstring path, jlong offset, jlong length) {
    const char *pathStr = path ? env->GetStringUTFChars(path, nullptr) : "";
    AK_LOGI("[AOSP-REAL] JNI openNative called path: %s", pathStr);
    auto *facade = new latinime::DictionaryFacade();
    bool opened = facade->openDictionary(pathStr, offset, length);
    if (path) env->ReleaseStringUTFChars(path, pathStr);
    AK_LOGI("[AOSP-REAL] JNI openNative result: %d", opened ? 1 : 0);
    return reinterpret_cast<jlong>(facade);
}

JNIEXPORT jboolean JNICALL
Java_com_pk_ai_1keyboard_suggestion_aosp_NativeBinaryDictionary_isValidWordNative(
    JNIEnv *env, jclass clazz, jlong dictPtr, jstring word) {
    if (!dictPtr || !word) return JNI_FALSE;
    auto *facade = reinterpret_cast<latinime::DictionaryFacade *>(dictPtr);
    const char *wordStr = env->GetStringUTFChars(word, nullptr);
    bool valid = facade->isValidWord(wordStr);
    env->ReleaseStringUTFChars(word, wordStr);
    return valid ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT jobjectArray JNICALL
Java_com_pk_ai_1keyboard_suggestion_aosp_NativeBinaryDictionary_getSuggestionsNative(
    JNIEnv *env, jclass clazz, jlong dictPtr, jlong proximityPtr, jstring input, jstring prevWord,
    jintArray touchXArray, jintArray touchYArray) {
    if (!dictPtr || !input) return nullptr;

    auto *facade = reinterpret_cast<latinime::DictionaryFacade *>(dictPtr);
    auto *proximity = reinterpret_cast<latinime::ProximityInfo *>(proximityPtr);

    const char *inputStr = env->GetStringUTFChars(input, nullptr);
    const char *prevStr = prevWord ? env->GetStringUTFChars(prevWord, nullptr) : "";

    std::vector<int> touchXs;
    std::vector<int> touchYs;

    if (touchXArray) {
        jint *xs = env->GetIntArrayElements(touchXArray, nullptr);
        jsize len = env->GetArrayLength(touchXArray);
        touchXs.assign(xs, xs + len);
        env->ReleaseIntArrayElements(touchXArray, xs, JNI_ABORT);
    }
    if (touchYArray) {
        jint *ys = env->GetIntArrayElements(touchYArray, nullptr);
        jsize len = env->GetArrayLength(touchYArray);
        touchYs.assign(ys, ys + len);
        env->ReleaseIntArrayElements(touchYArray, ys, JNI_ABORT);
    }

    AK_LOGI("[AOSP-REAL] JNI getSuggestionsNative executing native decoder");

    auto candidates = facade->getSuggestions(inputStr, prevStr, touchXs, touchYs, proximity);

    env->ReleaseStringUTFChars(input, inputStr);
    if (prevWord) env->ReleaseStringUTFChars(prevWord, prevStr);

    jclass stringClass = env->FindClass("java/lang/String");
    jobjectArray resultArray = env->NewObjectArray(candidates.size() * 3, stringClass, nullptr);

    for (size_t i = 0; i < candidates.size(); ++i) {
        jstring w = env->NewStringUTF(candidates[i].word.c_str());
        jstring s = env->NewStringUTF(std::to_string(candidates[i].score).c_str());
        jstring k = env->NewStringUTF(candidates[i].isAutoCorrection ? "1" : (candidates[i].isTypedWord ? "0" : "2"));

        env->SetObjectArrayElement(resultArray, i * 3, w);
        env->SetObjectArrayElement(resultArray, i * 3 + 1, s);
        env->SetObjectArrayElement(resultArray, i * 3 + 2, k);

        env->DeleteLocalRef(w);
        env->DeleteLocalRef(s);
        env->DeleteLocalRef(k);
    }

    AK_LOGI("[AOSP-REAL] JNI getSuggestionsNative returning %zu candidates", candidates.size());
    return resultArray;
}

JNIEXPORT void JNICALL
Java_com_pk_ai_1keyboard_suggestion_aosp_NativeBinaryDictionary_closeNative(
    JNIEnv *env, jclass clazz, jlong dictPtr) {
    if (dictPtr) {
        auto *facade = reinterpret_cast<latinime::DictionaryFacade *>(dictPtr);
        delete facade;
        AK_LOGI("[AOSP-REAL] NativeBinaryDictionary closed successfully.");
    }
}

JNIEXPORT jlong JNICALL
Java_com_pk_ai_1keyboard_suggestion_aosp_NativeProximityInfo_setProximityInfoNative(
    JNIEnv *env, jclass clazz, jint displayWidth, jint displayHeight, jint gridWidth, jint gridHeight,
    jint keyWidth, jint keyHeight, jintArray keyCodes, jintArray keyLefts, jintArray keyTops,
    jintArray keyRights, jintArray keyBottoms) {

    std::map<int, latinime::KeyRectNative> boundsMap;

    if (keyCodes && keyLefts && keyTops && keyRights && keyBottoms) {
        jint *codes = env->GetIntArrayElements(keyCodes, nullptr);
        jint *lefts = env->GetIntArrayElements(keyLefts, nullptr);
        jint *tops = env->GetIntArrayElements(keyTops, nullptr);
        jint *rights = env->GetIntArrayElements(keyRights, nullptr);
        jint *bottoms = env->GetIntArrayElements(keyBottoms, nullptr);
        jsize len = env->GetArrayLength(keyCodes);

        for (jsize i = 0; i < len; ++i) {
            latinime::KeyRectNative rect{lefts[i], tops[i], rights[i], bottoms[i]};
            boundsMap[codes[i]] = rect;
        }

        env->ReleaseIntArrayElements(keyCodes, codes, JNI_ABORT);
        env->ReleaseIntArrayElements(keyLefts, lefts, JNI_ABORT);
        env->ReleaseIntArrayElements(keyTops, tops, JNI_ABORT);
        env->ReleaseIntArrayElements(keyRights, rights, JNI_ABORT);
        env->ReleaseIntArrayElements(keyBottoms, bottoms, JNI_ABORT);
    }

    auto *proximity = new latinime::ProximityInfo(displayWidth, displayHeight, gridWidth, gridHeight, keyWidth, keyHeight, boundsMap);
    AK_LOGI("[AOSP-REAL] ProximityInfo created natively keyCount=%zu", boundsMap.size());
    return reinterpret_cast<jlong>(proximity);
}

JNIEXPORT void JNICALL
Java_com_pk_ai_1keyboard_suggestion_aosp_NativeProximityInfo_releaseProximityInfoNative(
    JNIEnv *env, jclass clazz, jlong proximityPtr) {
    if (proximityPtr) {
        auto *proximity = reinterpret_cast<latinime::ProximityInfo *>(proximityPtr);
        delete proximity;
        AK_LOGI("[AOSP-REAL] ProximityInfo released natively.");
    }
}

} // extern "C"
