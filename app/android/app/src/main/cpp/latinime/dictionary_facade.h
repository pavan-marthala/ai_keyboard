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

#ifndef LATINIME_DICTIONARY_FACADE_H
#define LATINIME_DICTIONARY_FACADE_H

#include "defines.h"
#include "v4_dict_buffers.h"
#include "proximity_info.h"
#include <string>
#include <vector>
#include <memory>

namespace latinime {

struct SuggestedWordNative {
    std::string word;
    int score;
    int kind; // 0: TYPED, 1: CORRECTION, 2: PREDICTION
    bool isAutoCorrection;
    bool isTypedWord;
};

class DictionaryFacade {
private:
    std::unique_ptr<V4DictBuffers> mDictBuffers;

public:
    DictionaryFacade();
    ~DictionaryFacade();

    bool openDictionary(const char* dictPath, long offset, long length);
    bool isValidWord(const std::string& word) const;

    std::vector<SuggestedWordNative> getSuggestions(
        const std::string& input,
        const std::string& prevWord,
        const std::vector<int>& touchXs,
        const std::vector<int>& touchYs,
        const ProximityInfo* proximityInfo
    ) const;
};

} // namespace latinime

#endif // LATINIME_DICTIONARY_FACADE_H

