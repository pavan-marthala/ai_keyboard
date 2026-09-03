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

#ifndef LATINIME_V4_DICT_BUFFERS_H
#define LATINIME_V4_DICT_BUFFERS_H

#include "defines.h"
#include <vector>
#include <string>
#include <cstdint>

namespace latinime {

struct DictNodeV4 {
    std::string word;
    int probability;
    int flags;
};

class V4DictBuffers {
private:
    bool mIsValid;
    std::vector<uint8_t> mBuffer;
    std::vector<DictNodeV4> mNodes;

public:
    V4DictBuffers();
    ~V4DictBuffers();

    bool openDict(const char* dictPath, long offset, long length);
    bool isValid() const { return mIsValid; }
    const std::vector<DictNodeV4>& getNodes() const { return mNodes; }
};

} // namespace latinime

#endif // LATINIME_V4_DICT_BUFFERS_H

