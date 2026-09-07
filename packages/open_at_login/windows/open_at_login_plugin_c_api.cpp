#include "include/open_at_login/open_at_login_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "open_at_login_plugin.h"

void OpenAtLoginPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  open_at_login::OpenAtLoginPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

