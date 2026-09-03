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

#ifndef LATINIME_SUGGESTION_DECODER_H
#define LATINIME_SUGGESTION_DECODER_H

#include "dictionary_trie.h"
#include "proximity_info.h"

namespace latinime {

class SuggestionDecoderNative {
public:
    static std::vector<WordCandidateNative> decodeSuggestions(
        const DictionaryTrieNative* dict,
        const std::string& input,
        const std::string& prevWord,
        const std::vector<int>& touchXs,
        const std::vector<int>& touchYs,
        const ProximityInfoNative* proximityInfo
    ) {
        if (!dict) return {};
        return dict->getSuggestions(input, prevWord, touchXs, touchYs, proximityInfo);
    }
};

} // namespace latinime

#endif // LATINIME_SUGGESTION_DECODER_H

