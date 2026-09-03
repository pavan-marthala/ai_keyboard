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

#ifndef LATINIME_CHAR_UTILS_H
#define LATINIME_CHAR_UTILS_H

#include <cctype>

namespace latinime {

class CharUtils {
public:
    static inline int toLowerCase(int c) {
        if (c >= 'A' && c <= 'Z') {
            return c + ('a' - 'A');
        }
        return c;
    }

    static inline bool isAsciiUpper(int c) {
        return c >= 'A' && c <= 'Z';
    }

    static inline bool isAsciiLower(int c) {
        return c >= 'a' && c <= 'z';
    }
};

} // namespace latinime

#endif // LATINIME_CHAR_UTILS_H

