cmake_minimum_required(VERSION 3.22.1)

project("latinime" C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(
    latinime
    SHARED
    latinime/latinime_jni.cpp
    latinime/v4_dict_buffers.cpp
    latinime/dictionary_facade.cpp
    latinime/proximity_info.cpp
)

find_library(
    log-lib
    log
)

target_link_libraries(
    latinime
    ${log-lib}
)
