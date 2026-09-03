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

#include "defines.h"
#include <jni.h>
#include <string>
#include <vector>
#include <memory>
#include "dictionary/structure/dictionary_structure_with_buffer_policy_factory.h"
#include "suggest/core/dictionary/dictionary.h"
#include "suggest/core/session/dic_traverse_session.h"
#include "suggest/core/layout/proximity_info.h"
#include "suggest/core/result/suggestion_results.h"
#include "suggest/core/result/suggested_word.h"
#include "dictionary/property/ngram_context.h"
#include "suggest/core/suggest_options.h"
#include "utils/char_utils.h"

extern "C" {

JNIEXPORT jlong JNICALL
Java_com_pk_ai_1keyboard_suggestion_aosp_NativeBinaryDictionary_openNative(
    JNIEnv *env, jclass clazz, jstring path, jlong offset, jlong length) {
    const char *pathStr = path ? env->GetStringUTFChars(path, nullptr) : "";
    AKLOGI("[AOSP-REAL] JNI openNative called path: %s", pathStr);
    
    auto policy = latinime::DictionaryStructureWithBufferPolicyFactory::newPolicyForExistingDictFile(
        pathStr, static_cast<int>(offset), static_cast<int>(length), false);
    
    if (path) env->ReleaseStringUTFChars(path, pathStr);

    if (!policy) {
        AKLOGE("[AOSP-REAL] JNI openNative failed to create policy for %s", pathStr);
        return 0L;
    }

    auto *dictionary = new latinime::Dictionary(env, std::move(policy));
    AKLOGI("[AOSP-REAL] JNI openNative created AOSP Dictionary successfully");
    return reinterpret_cast<jlong>(dictionary);
}

JNIEXPORT jboolean JNICALL
Java_com_pk_ai_1keyboard_suggestion_aosp_NativeBinaryDictionary_isValidWordNative(
    JNIEnv *env, jclass clazz, jlong dictPtr, jstring word) {
    if (!dictPtr || !word) return JNI_FALSE;
    auto *dictionary = reinterpret_cast<latinime::Dictionary *>(dictPtr);
    const char *wordStr = env->GetStringUTFChars(word, nullptr);
    
    std::vector<int> codePoints;
    latinime::CharUtils::attachIntArray(wordStr, &codePoints);
    env->ReleaseStringUTFChars(word, wordStr);

    int prob = dictionary->getProbability(latinime::CodePointArrayView(codePoints.data(), codePoints.size()));
    return (prob != NOT_A_PROBABILITY) ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT jobjectArray JNICALL
Java_com_pk_ai_1keyboard_suggestion_aosp_NativeBinaryDictionary_getSuggestionsNative(
    JNIEnv *env, jclass clazz, jlong dictPtr, jlong proximityPtr, jstring input, jstring prevWord,
    jintArray touchXArray, jintArray touchYArray) {
    if (!dictPtr || !input) return nullptr;

    auto *dictionary = reinterpret_cast<latinime::Dictionary *>(dictPtr);
    auto *proximity = reinterpret_cast<latinime::ProximityInfo *>(proximityPtr);

    const char *inputStr = env->GetStringUTFChars(input, nullptr);
    const char *prevStr = prevWord ? env->GetStringUTFChars(prevWord, nullptr) : "";

    std::vector<int> inputCodePoints;
    latinime::CharUtils::attachIntArray(inputStr, &inputCodePoints);

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

    std::vector<int> times(touchXs.size(), 0);
    std::vector<int> pointerIds(touchXs.size(), 0);

    latinime::DicTraverseSession session(env, env->NewStringUTF("en"), 1024 * 1024);
    std::vector<int> prevCodePoints;
    if (prevStr && strlen(prevStr) > 0) {
        latinime::CharUtils::attachIntArray(prevStr, &prevCodePoints);
    }
    const latinime::NgramContext ngramContext = prevCodePoints.empty()
            ? latinime::NgramContext()
            : latinime::NgramContext(
                    prevCodePoints.data(), static_cast<int>(prevCodePoints.size()),
                    false /* isBeginningOfSentence */);

    latinime::SuggestOptions options(nullptr, 0);
    latinime::SuggestionResults suggestionResults(MAX_RESULTS);

    dictionary->getSuggestions(
        proximity,
        &session,
        touchXs.data(),
        touchYs.data(),
        times.data(),
        pointerIds.data(),
        inputCodePoints.data(),
        static_cast<int>(inputCodePoints.size()),
        &ngramContext,
        &options,
        1.0f,
        &suggestionResults
    );

    env->ReleaseStringUTFChars(input, inputStr);
    if (prevWord) env->ReleaseStringUTFChars(prevWord, prevStr);

    std::vector<std::pair<std::string, int>> outputCandidates;
    std::vector<latinime::SuggestedWord> words = suggestionResults.getSuggestedWordsVector();
    for (const auto &sw : words) {
        std::string wordUtf8;
        latinime::CharUtils::attachString(
                latinime::CodePointArrayView(sw.getCodePoint(), sw.getCodePointCount()),
                &wordUtf8);
        outputCandidates.push_back({wordUtf8, sw.getScore()});
    }

    jclass stringClass = env->FindClass("java/lang/String");
    jobjectArray resultArray = env->NewObjectArray(outputCandidates.size() * 3, stringClass, nullptr);

    for (size_t i = 0; i < outputCandidates.size(); ++i) {
        jstring w = env->NewStringUTF(outputCandidates[i].first.c_str());
        jstring s = env->NewStringUTF(std::to_string(outputCandidates[i].second).c_str());
        jstring k = env->NewStringUTF("0");

        env->SetObjectArrayElement(resultArray, i * 3, w);
        env->SetObjectArrayElement(resultArray, i * 3 + 1, s);
        env->SetObjectArrayElement(resultArray, i * 3 + 2, k);

        env->DeleteLocalRef(w);
        env->DeleteLocalRef(s);
        env->DeleteLocalRef(k);
    }

    AKLOGI("[AOSP-REAL] JNI getSuggestionsNative returning %zu candidates from AOSP engine", outputCandidates.size());
    return resultArray;
}

JNIEXPORT void JNICALL
Java_com_pk_ai_1keyboard_suggestion_aosp_NativeBinaryDictionary_closeNative(
    JNIEnv *env, jclass clazz, jlong dictPtr) {
    if (dictPtr) {
        auto *dictionary = reinterpret_cast<latinime::Dictionary *>(dictPtr);
        delete dictionary;
        AKLOGI("[AOSP-REAL] NativeBinaryDictionary AOSP Dictionary closed successfully.");
    }
}

JNIEXPORT jlong JNICALL
Java_com_pk_ai_1keyboard_suggestion_aosp_NativeProximityInfo_setProximityInfoNative(
    JNIEnv *env, jclass clazz, jint displayWidth, jint displayHeight, jint gridWidth, jint gridHeight,
    jint keyWidth, jint keyHeight, jintArray keyCodes, jintArray keyLefts, jintArray keyTops,
    jintArray keyWidths, jintArray keyHeights) {

    jsize keyCount = keyCodes ? env->GetArrayLength(keyCodes) : 0;
    
    std::vector<int> proxChars(gridWidth * gridHeight * 16, 0);
    jintArray jProxChars = env->NewIntArray(proxChars.size());
    env->SetIntArrayRegion(jProxChars, 0, proxChars.size(), proxChars.data());

    std::vector<float> sweetSpots(keyCount * 3, 0.0f);
    jfloatArray jSweetSpotsX = env->NewFloatArray(keyCount);
    jfloatArray jSweetSpotsY = env->NewFloatArray(keyCount);
    jfloatArray jSweetSpotsR = env->NewFloatArray(keyCount);

    auto *proximity = new latinime::ProximityInfo(
        env, displayWidth, displayHeight, gridWidth, gridHeight,
        keyWidth, keyHeight, jProxChars, keyCount,
        keyLefts, keyTops, keyWidths, keyHeights, keyCodes,
        jSweetSpotsX, jSweetSpotsY, jSweetSpotsR
    );

    AKLOGI("[AOSP-REAL] ProximityInfo created natively keyCount=%d", static_cast<int>(keyCount));
    return reinterpret_cast<jlong>(proximity);
}

JNIEXPORT void JNICALL
Java_com_pk_ai_1keyboard_suggestion_aosp_NativeProximityInfo_releaseProximityInfoNative(
    JNIEnv *env, jclass clazz, jlong proximityPtr) {
    if (proximityPtr) {
        auto *proximity = reinterpret_cast<latinime::ProximityInfo *>(proximityPtr);
        delete proximity;
        AKLOGI("[AOSP-REAL] ProximityInfo released natively.");
    }
}

} // extern "C"
