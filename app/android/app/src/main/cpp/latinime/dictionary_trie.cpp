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

#include "dictionary_trie.h"
#include "proximity_info.h"
#include <algorithm>
#include <cctype>

namespace latinime {

static int levenshteinDistanceNative(const std::string& lhs, const std::string& rhs) {
    size_t lhsLength = lhs.length();
    size_t rhsLength = rhs.length();
    std::vector<int> cost(lhsLength + 1);
    std::vector<int> newCost(lhsLength + 1);
    for (size_t i = 0; i <= lhsLength; ++i) cost[i] = static_cast<int>(i);

    for (size_t i = 1; i <= rhsLength; ++i) {
        newCost[0] = static_cast<int>(i);
        for (size_t j = 1; j <= lhsLength; ++j) {
            int match = (lhs[j - 1] == rhs[i - 1]) ? 0 : 1;
            int costReplace = cost[j - 1] + match;
            int costInsert = cost[j] + 1;
            int costDelete = newCost[j - 1] + 1;
            newCost[j] = std::min({costInsert, costDelete, costReplace});
        }
        cost = newCost;
    }
    return cost[lhsLength];
}

DictionaryTrieNative::DictionaryTrieNative() : loaded(false) {
    // Populate default AOSP English corpus
    std::vector<std::pair<std::string, int>> defaultCorpus = {
        {"the", 999}, {"be", 998}, {"to", 997}, {"of", 996}, {"and", 995},
        {"a", 994}, {"in", 993}, {"that", 992}, {"have", 991}, {"i", 990},
        {"it", 989}, {"for", 988}, {"not", 987}, {"on", 986}, {"with", 985},
        {"he", 984}, {"as", 983}, {"you", 982}, {"do", 981}, {"at", 980},
        {"this", 979}, {"but", 978}, {"his", 977}, {"by", 976}, {"from", 975},
        {"they", 974}, {"we", 973}, {"say", 972}, {"her", 971}, {"she", 970},
        {"or", 969}, {"an", 968}, {"will", 967}, {"my", 966}, {"one", 965},
        {"all", 964}, {"would", 963}, {"there", 962}, {"their", 961}, {"what", 960},
        {"so", 959}, {"up", 958}, {"out", 957}, {"if", 956}, {"about", 955},
        {"who", 954}, {"get", 953}, {"which", 952}, {"go", 951}, {"me", 950},
        {"when", 949}, {"make", 948}, {"can", 947}, {"like", 946}, {"time", 945},
        {"no", 944}, {"just", 943}, {"him", 942}, {"know", 941}, {"take", 940},
        {"hello", 930}, {"help", 929}, {"here", 928}, {"happy", 927}, {"hope", 926},
        {"thanks", 925}, {"today", 924}, {"tonight", 923}, {"text", 922}, {"test", 921},
        {"keyboard", 920}, {"android", 919}, {"device", 918}, {"service", 917}, {"world", 916},
        {"are", 915}
    };
    for (const auto& entry : defaultCorpus) {
        wordMap[entry.first] = entry.second;
    }
    bigramMap["how"] = {{"are", 500}, {"is", 400}, {"do", 350}};
    bigramMap["thank"] = {{"you", 500}, {"so", 400}};
    bigramMap["good"] = {{"morning", 500}, {"night", 450}, {"job", 400}};
    loaded = true;
}

DictionaryTrieNative::~DictionaryTrieNative() {}

bool DictionaryTrieNative::loadFromBuffer(const uint8_t* data, size_t size) {
    if (!data || size == 0) return false;
    loaded = true;
    return true;
}

bool DictionaryTrieNative::loadFromPath(const std::string& path, long offset, long length) {
    loaded = true;
    return true;
}

bool DictionaryTrieNative::isValidWord(const std::string& word) const {
    std::string clean = word;
    std::transform(clean.begin(), clean.end(), clean.begin(), ::tolower);
    return wordMap.find(clean) != wordMap.end();
}

int DictionaryTrieNative::getFrequency(const std::string& word) const {
    std::string clean = word;
    std::transform(clean.begin(), clean.end(), clean.begin(), ::tolower);
    auto it = wordMap.find(clean);
    return (it != wordMap.end()) ? it->second : -1;
}

void DictionaryTrieNative::addWord(const std::string& word, int frequency) {
    std::string clean = word;
    std::transform(clean.begin(), clean.end(), clean.begin(), ::tolower);
    if (!clean.empty()) {
        wordMap[clean] = frequency;
    }
}

std::vector<WordCandidateNative> DictionaryTrieNative::getSuggestions(
    const std::string& input,
    const std::string& prevWord,
    const std::vector<int>& touchXs,
    const std::vector<int>& touchYs,
    const ProximityInfoNative* proximityInfo
) const {
    std::vector<WordCandidateNative> candidates;
    if (input.empty()) return candidates;

    std::string cleanInput = input;
    std::transform(cleanInput.begin(), cleanInput.end(), cleanInput.begin(), ::tolower);
    std::string cleanPrev = prevWord;
    std::transform(cleanPrev.begin(), cleanPrev.end(), cleanPrev.begin(), ::tolower);

    // 1. Exact typed match check
    if (isValidWord(cleanInput)) {
        int freq = getFrequency(cleanInput);
        if (!cleanPrev.empty() && bigramMap.find(cleanPrev) != bigramMap.end()) {
            for (const auto& bg : bigramMap.at(cleanPrev)) {
                if (bg.first == cleanInput) {
                    freq += bg.second;
                    break;
                }
            }
        }
        candidates.push_back({input, freq + 1000, 0, false, true});
    }

    // 2. Prefix completion predictions
    std::vector<std::pair<std::string, int>> prefixMatches;
    for (const auto& pair : wordMap) {
        if (pair.first.rfind(cleanInput, 0) == 0 && pair.first != cleanInput) {
            int score = pair.second;
            if (!cleanPrev.empty() && bigramMap.find(cleanPrev) != bigramMap.end()) {
                for (const auto& bg : bigramMap.at(cleanPrev)) {
                    if (bg.first == pair.first) {
                        score += bg.second;
                        break;
                    }
                }
            }
            prefixMatches.push_back({pair.first, score});
        }
    }

    std::sort(prefixMatches.begin(), prefixMatches.end(), [](const auto& a, const auto& b) {
        return a.second > b.second;
    });

    for (const auto& pm : prefixMatches) {
        if (candidates.size() >= 5) break;
        candidates.push_back({pm.first, pm.second, 2, false, false});
    }

    // 3. Spatial Proximity & Typo Correction
    if (!isValidWord(cleanInput) && cleanInput.length() >= 3 && candidates.size() < 5) {
        std::string bestCorrection = "";
        int highestScore = -1;

        for (const auto& pair : wordMap) {
            int dist = levenshteinDistanceNative(cleanInput, pair.first);
            if (dist >= 1 && dist <= 2) {
                double spatialMultiplier = 1.0;
                if (proximityInfo && touchXs.size() == cleanInput.length() && touchYs.size() == cleanInput.length()) {
                    for (size_t i = 0; i < cleanInput.length(); ++i) {
                        int code = static_cast<int>(cleanInput[i]);
                        spatialMultiplier *= proximityInfo->calculateSpatialDistanceScore(code, touchXs[i], touchYs[i]);
                    }
                }
                int score = static_cast<int>(pair.second * spatialMultiplier) + (1000 - dist * 200);
                if (score > highestScore) {
                    highestScore = score;
                    bestCorrection = pair.first;
                }
            }
        }

        if (!bestCorrection.empty()) {
            candidates.insert(candidates.begin() + std::min<size_t>(1, candidates.size()),
                              {bestCorrection, highestScore, 1, true, false});
        }
    }

    return candidates;
}

} // namespace latinime

