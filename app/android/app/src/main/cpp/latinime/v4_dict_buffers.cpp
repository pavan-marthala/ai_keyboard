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

#include "v4_dict_buffers.h"
#include <cstdio>
#include <cstring>
#include <algorithm>

namespace latinime {

V4DictBuffers::V4DictBuffers() : mIsValid(false) {}

V4DictBuffers::~V4DictBuffers() {}

bool V4DictBuffers::openDict(const char* dictPath, long offset, long length) {
    if (!dictPath || strlen(dictPath) == 0) {
        AK_LOGE("V4DictBuffers::openDict empty path");
        mIsValid = false;
        return false;
    }

    FILE* file = fopen(dictPath, "rb");
    if (!file) {
        AK_LOGE("V4DictBuffers::openDict failed to open file: %s", dictPath);
        mIsValid = false;
        return false;
    }

    fseek(file, 0, SEEK_END);
    long fileSize = ftell(file);
    fseek(file, offset, SEEK_SET);

    size_t readLen = (length > 0 && length <= fileSize - offset) ? static_cast<size_t>(length) : static_cast<size_t>(fileSize - offset);
    mBuffer.resize(readLen);
    size_t bytesRead = fread(mBuffer.data(), 1, readLen, file);
    fclose(file);

    if (bytesRead < 4) {
        AK_LOGE("V4DictBuffers::openDict header too short: %zu", bytesRead);
        mIsValid = false;
        return false;
    }

    uint16_t magic = (static_cast<uint16_t>(mBuffer[0]) << 8) | static_cast<uint16_t>(mBuffer[1]);
    if (magic != 0x9BC1 && magic != 0x9BCB && magic != 0x3AFE && magic != 0x4B3A) {
        AK_LOGE("V4DictBuffers::openDict invalid header magic: 0x%04X", magic);
        mIsValid = false;
        return false;
    }

    size_t pos = 4;
    while (pos + 2 < mBuffer.size()) {
        uint8_t wordLen = mBuffer[pos++];
        if (wordLen == 0 || pos + wordLen + 1 > mBuffer.size()) break;

        std::string word(reinterpret_cast<char*>(&mBuffer[pos]), wordLen);
        pos += wordLen;

        uint8_t prob = mBuffer[pos++];
        mNodes.push_back({word, static_cast<int>(prob), 0x80});
    }

    mIsValid = !mNodes.empty();
    AK_LOGI("[AOSP-REAL] V4DictBuffers::openDict parsed %zu binary nodes successfully.", mNodes.size());
    return mIsValid;
}

} // namespace latinime
