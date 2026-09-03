/*
 * Copyright (C) 2014, The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef LATINIME_WORD_ID_ARRAY_H
#define LATINIME_WORD_ID_ARRAY_H

#include <array>
#include <cstddef>
#include "defines.h"

namespace latinime {

template <size_t N>
class WordIdArray {
 public:
    WordIdArray() : mData{} {}

    int& operator[](size_t index) { return mData[index]; }
    int operator[](size_t index) const { return mData[index]; }
    const int* data() const { return mData.data(); }
    size_t size() const { return N; }

 private:
    std::array<int, N> mData;
};

} // namespace latinime
#endif /* LATINIME_WORD_ID_ARRAY_H */

