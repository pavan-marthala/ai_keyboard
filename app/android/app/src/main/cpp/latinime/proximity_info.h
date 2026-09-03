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

#ifndef LATINIME_PROXIMITY_INFO_H
#define LATINIME_PROXIMITY_INFO_H

#include "defines.h"
#include <vector>
#include <map>
#include <cmath>

namespace latinime {

struct KeyRectNative {
    int left;
    int top;
    int right;
    int bottom;

    int width() const { return right - left; }
    int height() const { return bottom - top; }
    int centerX() const { return (left + right) / 2; }
    int centerY() const { return (top + bottom) / 2; }
};

class ProximityInfo {
private:
    int mDisplayWidth;
    int mDisplayHeight;
    int mGridWidth;
    int mGridHeight;
    int mKeyWidth;
    int mKeyHeight;
    std::map<int, KeyRectNative> mKeyBoundsMap;

public:
    ProximityInfo(int displayWidth, int displayHeight, int gridWidth, int gridHeight,
                  int keyWidth, int keyHeight, const std::map<int, KeyRectNative>& keyBoundsMap)
        : mDisplayWidth(displayWidth), mDisplayHeight(displayHeight),
          mGridWidth(gridWidth), mGridHeight(gridHeight),
          mKeyWidth(keyWidth), mKeyHeight(keyHeight),
          mKeyBoundsMap(keyBoundsMap) {}

    int getDisplayWidth() const { return mDisplayWidth; }
    int getDisplayHeight() const { return mDisplayHeight; }
    int getKeyWidth() const { return mKeyWidth; }
    int getKeyHeight() const { return mKeyHeight; }

    double getSpatialDistanceScore(int codePoint, int touchX, int touchY) const {
        if (touchX < 0 || touchY < 0 || mKeyBoundsMap.empty()) return 1.0;
        auto it = mKeyBoundsMap.find(codePoint);
        if (it == mKeyBoundsMap.end()) return 0.4;
        const auto& rect = it->second;
        double dx = static_cast<double>(touchX - rect.centerX());
        double dy = static_cast<double>(touchY - rect.centerY());
        double distSq = dx * dx + dy * dy;
        double sigmaSq = static_cast<double>(mKeyWidth * mKeyWidth) / 4.0;
        if (sigmaSq <= 0.0) sigmaSq = 1000.0;
        return std::exp(-distSq / (2.0 * sigmaSq));
    }
};

} // namespace latinime

#endif // LATINIME_PROXIMITY_INFO_H
