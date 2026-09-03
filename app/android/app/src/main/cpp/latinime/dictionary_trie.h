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

#ifndef LATINIME_DICTIONARY_TRIE_H
#define LATINIME_DICTIONARY_TRIE_H

#include <string>
#include <vector>
#include <map>

namespace latinime {

struct WordCandidateNative {
    std::string word;
    int score;
    int kind; // 0: TYPED, 1: CORRECTION, 2: PREDICTION
    bool isAutoCorrection;
    bool isTypedWord;
};

class DictionaryTrieNative {
private:
    std::map<std::string, int> wordMap;
    std::map<std::string, std::vector<std::pair<std::string, int>>> bigramMap;
    bool loaded;

public:
    DictionaryTrieNative();
    ~DictionaryTrieNative();

    bool loadFromBuffer(const uint8_t* data, size_t size);
    bool loadFromPath(const std::string& path, long offset, long length);
    bool isValidWord(const std::string& word) const;
    int getFrequency(const std::string& word) const;
    void addWord(const std::string& word, int frequency);
    
    std::vector<WordCandidateNative> getSuggestions(
        const std::string& input,
        const std::string& prevWord,
        const std::vector<int>& touchXs,
        const std::vector<int>& touchYs,
        const class ProximityInfoNative* proximityInfo
    ) const;
};

} // namespace latinime

#endif // LATINIME_DICTIONARY_TRIE_H

