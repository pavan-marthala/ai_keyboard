import 'package:atfix/core/errors/failures.dart';
import 'package:atfix/core/theme/app_theme.dart';
import 'package:atfix/core/utils/app_buitton.dart';
import 'package:atfix/core/utils/app_text_field.dart';
import 'package:atfix/core/utils/app_toast.dart';
import 'package:atfix/core/utils/sized_context.dart';
import 'package:atfix/features/settings/domain/entities/ai_provider_metadata.dart';
import 'package:atfix/features/settings/domain/entities/ai_provider_type.dart';
import 'package:atfix/features/commands/presentation/bloc/command_bloc.dart';
import 'package:atfix/features/commands/presentation/bloc/command_event.dart';
import 'package:atfix/features/commands/presentation/bloc/command_state.dart';
import 'package:atfix/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:atfix/features/settings/presentation/bloc/settings_event.dart';
import 'package:atfix/features/settings/presentation/bloc/settings_state.dart';
import 'package:material_ui/material_ui.dart';
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

          return SafeArea(
            child: ListView(
              padding: EdgeInsets.only(
                bottom: context.viewInsets.bottom + 100,
                top: models.isEmpty ? 24 : 16,
                left: 16,
                right: 16,
              ),
              children: [
                Text('Settings', style: typo.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Connect a provider, pick a model, and manage your commands.',
                  style: typo.bodyMedium,
                ),
                const SizedBox(height: 20),
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
                    color: colors.error.withValues(alpha: 0.10),

                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: colors.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              state.modelsError?.message ?? "Unknown error occurred while fetching models.",
                              style: TextStyle(color: colors.error),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              context.read<SettingsBloc>().add(
                                SettingsEvent.fetchModels(
                                  provider: activeProvider,
                                  forceRefresh: true,
                                ),
                              );
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Retry'),
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
                  // DropdownButtonFormField<String>(
                  //   initialValue:
                  //       models.any((m) => m.id == state.settings.activeModelId)
                  //       ? state.settings.activeModelId
                  //       : models.first.id,
                  //   decoration: const InputDecoration(
                  //     labelText: 'Select Model',
                  //     border: OutlineInputBorder(),
                  //   ),
                  //   items: models.map((AiModel model) {
                  //     return DropdownMenuItem<String>(
                  //       value: model.id,
                  //       child: Text(
                  //         model.displayName,
                  //         overflow: TextOverflow.ellipsis,
                  //       ),
                  //     );
                  //   }).toList(),
                  //   onChanged: (value) {
                  //     if (value != null) {
                  //       context.read<SettingsBloc>().add(
                  //         SettingsEvent.selectModel(value),
                  //       );
                  //     }
                  //   },
                  // ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      alignment: Alignment.topCenter,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: models.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final model = models[index];
                          final isSelected =
                              model.id == state.settings.activeModelId;
                          return GestureDetector(
                            onTap: () {
                              context.read<SettingsBloc>().add(
                                SettingsEvent.selectModel(model.id),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surfaceDark,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: isSelected
                                      ? colors.primary
                                      : colors.border,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? colors.primary
                                        : colors.textSecondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    model.displayName,
                                    style: typo.bodyMedium.copyWith(
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Keyboard Settings',
                  style: typo.titleMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure native keyboard layout and preferences.',
                  style: typo.bodyMedium.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Use Numbers',
                    style: typo.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Show a dedicated number row above QWERTY letters',
                    style: typo.bodySmall.copyWith(color: colors.textSecondary),
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
                Text(
                  'AI Commands',
                  style: typo.titleMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enable or disable built-in text transformation commands.',
                  style: typo.bodyMedium.copyWith(),
                ),
                const SizedBox(height: 12),
                BlocBuilder<CommandBloc, CommandState>(
                  builder: (context, commandState) {
                    final commands = commandState.commands;
                    return Column(
                      children: commands.map((cmd) {
                        return SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Row(
                            spacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  cmd.trigger,
                                  style: typo.titleMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.primary400,
                                  ),
                                ),
                              ),
                              Text(
                                cmd.name,
                                style: typo.titleMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            cmd.description,
                            style: typo.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
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
            ),
          );
        },
      ),
    );
  }
}
