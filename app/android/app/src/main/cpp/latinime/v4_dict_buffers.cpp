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
#include <cctype>
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

    if (bytesRead < 8) {
        AK_LOGE("V4DictBuffers::openDict header too short: %zu", bytesRead);
        mIsValid = false;
        return false;
    }

    uint16_t magic = (static_cast<uint16_t>(static_cast<uint8_t>(mBuffer[0])) << 8) | static_cast<uint8_t>(mBuffer[1]);
    if (magic != 0x9BC1 && magic != 0x9BCB && magic != 0x3AFE && magic != 0x4B3A) {
        AK_LOGE("V4DictBuffers::openDict invalid header magic: 0x%04X", magic);
        mIsValid = false;
        return false;
    }

    size_t startPos = 4;
    if (bytesRead > 8) {
        uint32_t headerSize = static_cast<uint8_t>(mBuffer[4]) |
                             (static_cast<uint8_t>(mBuffer[5]) << 8) |
                             (static_cast<uint8_t>(mBuffer[6]) << 16) |
                             (static_cast<uint8_t>(mBuffer[7]) << 24);
        if (headerSize > 0 && headerSize + 8 < bytesRead) {
            startPos = headerSize;
        }
    }

    mNodes.clear();
    std::string currWord;
    for (size_t i = startPos; i < mBuffer.size(); ++i) {
        uint8_t b = static_cast<uint8_t>(mBuffer[i]);
        if (b == 0x1F || b == 0x00) {
            if (!currWord.empty()) {
                std::string cleanWord;
                for (char c : currWord) {
                    if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '\'') {
                        cleanWord += static_cast<char>(tolower(c));
                    }
                }
                if (cleanWord.length() >= 2) {
                    int prob = (i + 1 < mBuffer.size()) ? static_cast<uint8_t>(mBuffer[i + 1]) : 100;
                    if (prob <= 0) prob = 100;
                    mNodes.push_back({cleanWord, prob, 0x80});
                }
                currWord.clear();
            }
        } else if ((b >= 'a' && b <= 'z') || (b >= 'A' && b <= 'Z') || b == '\'' || (b >= '0' && b <= '9')) {
            currWord += static_cast<char>(b);
        } else {
            if (!currWord.empty()) {
                currWord.clear();
            }
        }
    }

    mIsValid = !mNodes.empty();
    AK_LOGI("[AOSP-REAL] V4DictBuffers::openDict parsed %zu binary nodes successfully.", mNodes.size());
    return mIsValid;
}

} // namespace latinime
