cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "open_at_login")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, and it must not
# be changed
set(PLUGIN_NAME "open_at_login_plugin")

add_library(${PLUGIN_NAME} SHARED
  "include/open_at_login/open_at_login_plugin_c_api.h"
  "open_at_login_plugin_c_api.cpp"
  "open_at_login_plugin.h"
  "open_at_login_plugin.cpp"
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET "hidden"
  VISIBILITY_INLINES_HIDDEN YES
)

target_compile_definitions(${PLUGIN_NAME} PRIVATE
  FLUTTER_PLUGIN_IMPL
  _SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS
)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
)

target_link_libraries(${PLUGIN_NAME} PRIVATE
  flutter
  flutter_wrapper_plugin
  advapi32
  windowsapp
)

# List of absolute paths to libraries that should be bundled with the plugin
set(open_at_login_bundled_libraries
  ""
  PARENT_SCOPE
)

