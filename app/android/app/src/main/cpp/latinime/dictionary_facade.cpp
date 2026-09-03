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

#include "dictionary_facade.h"
#include "char_utils.h"
#include <algorithm>
#include <cmath>

namespace latinime {

static int editDistance(const std::string& s1, const std::string& s2) {
    size_t len1 = s1.length();
    size_t len2 = s2.length();
    std::vector<int> col(len2 + 1);
    std::vector<int> prevCol(len2 + 1);
    for (size_t i = 0; i <= len2; ++i) prevCol[i] = static_cast<int>(i);

    for (size_t i = 0; i < len1; ++i) {
        col[0] = static_cast<int>(i + 1);
        for (size_t j = 0; j < len2; ++j) {
            int cost = (s1[i] == s2[j]) ? 0 : 1;
            col[j + 1] = std::min({prevCol[j + 1] + 1, col[j] + 1, prevCol[j] + cost});
        }
        prevCol = col;
    }
    return prevCol[len2];
}

DictionaryFacade::DictionaryFacade() : mDictBuffers(std::make_unique<V4DictBuffers>()) {}

DictionaryFacade::~DictionaryFacade() {}

bool DictionaryFacade::openDictionary(const char* dictPath, long offset, long length) {
    return mDictBuffers->openDict(dictPath, offset, length);
}

bool DictionaryFacade::isValidWord(const std::string& word) const {
    if (!mDictBuffers || !mDictBuffers->isValid()) return false;
    std::string clean = word;
    std::transform(clean.begin(), clean.end(), clean.begin(), ::tolower);
    for (const auto& node : mDictBuffers->getNodes()) {
        if (node.word == clean) return true;
    }
    return false;
}

std::vector<SuggestedWordNative> DictionaryFacade::getSuggestions(
    const std::string& input,
    const std::string& prevWord,
    const std::vector<int>& touchXs,
    const std::vector<int>& touchYs,
    const ProximityInfo* proximityInfo
) const {
    std::vector<SuggestedWordNative> results;
    if (input.empty() || !mDictBuffers || !mDictBuffers->isValid()) return results;

    std::string cleanInput = input;
    std::transform(cleanInput.begin(), cleanInput.end(), cleanInput.begin(), ::tolower);
    std::string cleanPrev = prevWord;
    std::transform(cleanPrev.begin(), cleanPrev.end(), cleanPrev.begin(), ::tolower);

    const auto& nodes = mDictBuffers->getNodes();

    // 1. Exact typed word match
    if (isValidWord(cleanInput)) {
        int baseProb = 1000;
        for (const auto& n : nodes) {
            if (n.word == cleanInput) {
                baseProb = n.probability + 1000;
                break;
            }
        }
        results.push_back({input, baseProb, 0, false, true});
    }

    // 2. Prefix completion candidates
    std::vector<std::pair<std::string, int>> prefixCandidates;
    for (const auto& node : nodes) {
        if (node.word.rfind(cleanInput, 0) == 0 && node.word != cleanInput) {
            prefixCandidates.push_back({node.word, node.probability});
        }
    }
    std::sort(prefixCandidates.begin(), prefixCandidates.end(), [](const auto& a, const auto& b) {
        return a.second > b.second;
    });

    for (const auto& pc : prefixCandidates) {
        if (results.size() >= 5) break;
        results.push_back({pc.first, pc.second, 2, false, false});
    }

    // 3. Spatial Proximity & Typo Correction
    if (!isValidWord(cleanInput) && cleanInput.length() >= 3 && results.size() < 5) {
        std::string bestCorrection = "";
        int highestScore = -1;

        for (const auto& node : nodes) {
            int dist = editDistance(cleanInput, node.word);
            if (dist >= 1 && dist <= 2) {
                double spatialMultiplier = 1.0;
                if (proximityInfo && touchXs.size() == cleanInput.length() && touchYs.size() == cleanInput.length()) {
                    for (size_t i = 0; i < cleanInput.length(); ++i) {
                        int code = static_cast<int>(cleanInput[i]);
                        spatialMultiplier *= proximityInfo->getSpatialDistanceScore(code, touchXs[i], touchYs[i]);
                    }
                }
                int score = static_cast<int>(node.probability * spatialMultiplier) + (1000 - dist * 200);
                if (score > highestScore) {
                    highestScore = score;
                    bestCorrection = node.word;
                }
            }
        }

        if (!bestCorrection.empty()) {
            results.insert(results.begin() + std::min<size_t>(1, results.size()),
                           {bestCorrection, highestScore, 1, true, false});
        }
    }

    return results;
}

} // namespace latinime

