import 'package:ai_keyboard/core/errors/failures.dart';
import 'package:ai_keyboard/core/theme/app_theme.dart';
import 'package:ai_keyboard/core/utils/app_buitton.dart';
import 'package:ai_keyboard/core/utils/app_text_field.dart';
import 'package:ai_keyboard/core/utils/app_toast.dart';
import 'package:ai_keyboard/features/ai_service/domain/entities/ai_model.dart';
import 'package:ai_keyboard/features/settings/domain/entities/ai_provider_metadata.dart';
import 'package:ai_keyboard/features/settings/domain/entities/ai_provider_type.dart';
import 'package:ai_keyboard/features/commands/presentation/bloc/command_bloc.dart';
import 'package:ai_keyboard/features/commands/presentation/bloc/command_event.dart';
import 'package:ai_keyboard/features/commands/presentation/bloc/command_state.dart';
import 'package:ai_keyboard/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:ai_keyboard/features/settings/presentation/bloc/settings_event.dart';
import 'package:ai_keyboard/features/settings/presentation/bloc/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _apiKeyController = TextEditingController();
  bool _obscureApiKey = true;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _openApiKeyUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typo = context.appTypography;
    return Scaffold(
      appBar: AppBar(title: const Text('AI Keyboard Settings')),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state.failure != null) {
            showErrorToast(message: state.failure!.message);
          }
        },
        builder: (context, state) {
          final activeProvider = state.settings.activeProvider;
          final metadata = AiProviderMetadata.getForType(activeProvider);
          final hasKey = state.hasApiKeyMap[activeProvider] ?? false;
          final models = state.modelsMap[activeProvider] ?? [];

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                color: hasKey
                    ? colors.success.withValues(alpha: 0.10)
                    : colors.warning.withValues(alpha: 0.10),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        hasKey
                            ? Icons.check_circle
                            : Icons.warning_amber_rounded,
                        color: hasKey ? colors.success : colors.warning,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          hasKey
                              ? '${metadata.displayName} API Key configured.'
                              : '${metadata.displayName} API Key missing. Add key below.',
                          style: TextStyle(
                            color: hasKey ? colors.success : colors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'AI Provider Selection',
                style: typo.titleMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AiProviderType>(
                initialValue: activeProvider,
                decoration: const InputDecoration(
                  labelText: 'Provider',
                  border: OutlineInputBorder(),
                ),
                items: AiProviderMetadata.allProviders.map((m) {
                  return DropdownMenuItem(
                    value: m.type,
                    child: Text(m.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _apiKeyController.clear();
                    context.read<SettingsBloc>().add(
                      SettingsEvent.selectProvider(value),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              Text(
                metadata.description,
                style: typo.bodyMedium.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 20),
              Text(
                'API Key',
                style: typo.titleMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _apiKeyController,
                isPassword: _obscureApiKey,
                hintText: hasKey
                    ? '•••••••••••• (Key Configured)'
                    : '${metadata.displayName} API Key',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                    color: colors.textPrimary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureApiKey = !_obscureApiKey;
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Don't have an API key?",
                    style: typo.bodyMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openApiKeyUrl(metadata.apiKeyUrl),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Get API Key →'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Save API Key',
                      icon: const Icon(Icons.save, size: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      onPressed: state.isLoading
                          ? null
                          : () {
                              final key = _apiKeyController.text.trim();
                              if (key.isNotEmpty) {
                                context.read<SettingsBloc>().add(
                                  SettingsEvent.saveApiKey(
                                    provider: activeProvider,
                                    apiKey: key,
                                  ),
                                );
                                _apiKeyController.clear();
                                showSuccessToast(
                                  message:
                                      '${metadata.displayName} key saved securely!',
                                );
                              }
                            },
                      isLoading: state.isLoading,
                    ),
                  ),
                  if (hasKey) ...[
                    const SizedBox(width: 12),
                    AppButton(
                      text: 'Delete Key',
                      icon: const Icon(Icons.delete, size: 20),
                      color: colors.error,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 8,
                      ),
                      onPressed: state.isLoading
                          ? null
                          : () {
                              context.read<SettingsBloc>().add(
                                SettingsEvent.deleteApiKey(
                                  provider: activeProvider,
                                ),
                              );
                            },
                      isLoading: state.isLoading,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Model Discovery',
                    style: typo.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (hasKey)
                    TextButton.icon(
                      onPressed: state.isFetchingModels
                          ? null
                          : () {
                              context.read<SettingsBloc>().add(
                                SettingsEvent.fetchModels(
                                  provider: activeProvider,
                                  forceRefresh: true,
                                ),
                              );
                            },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Refresh'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (state.isFetchingModels)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Loading models...'),
                      ],
                    ),
                  ),
                )
              else if (state.modelsError != null)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.modelsError!.message,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.read<SettingsBloc>().add(
                              SettingsEvent.fetchModels(
                                provider: activeProvider,
                                forceRefresh: true,
                              ),
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (models.isEmpty)
                Text(
                  hasKey
                      ? 'No compatible text models found.'
                      : 'Add an API key above to load models.',
                  style: TextStyle(color: Colors.grey.shade600),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue:
                      models.any((m) => m.id == state.settings.activeModelId)
                      ? state.settings.activeModelId
                      : models.first.id,
                  decoration: const InputDecoration(
                    labelText: 'Select Model',
                    border: OutlineInputBorder(),
                  ),
                  items: models.map((AiModel model) {
                    return DropdownMenuItem<String>(
                      value: model.id,
                      child: Text(
                        model.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      context.read<SettingsBloc>().add(
                        SettingsEvent.selectModel(value),
                      );
                    }
                  },
                ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Keyboard Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Configure native keyboard layout and preferences.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Use Numbers',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Show a dedicated number row above QWERTY letters',
                ),
                value: state.settings.useNumbersEnabled,
                onChanged: (bool value) {
                  final updated = state.settings.copyWith(
                    useNumbersEnabled: value,
                  );
                  context.read<SettingsBloc>().add(
                    SettingsEvent.updateSettings(updated),
                  );
                },
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'AI Commands',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Enable or disable built-in text transformation commands.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              const SizedBox(height: 12),
              BlocBuilder<CommandBloc, CommandState>(
                builder: (context, commandState) {
                  final commands = commandState.commands;
                  return Column(
                    children: commands.map((cmd) {
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${cmd.trigger} — ${cmd.name}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(cmd.description),
                        value: cmd.enabled,
                        onChanged: (_) {
                          context.read<CommandBloc>().add(
                            CommandEvent.toggleCommandEnabled(cmd.trigger),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
