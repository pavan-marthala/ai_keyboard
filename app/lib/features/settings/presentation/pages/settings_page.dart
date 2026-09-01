import 'package:ai_keyboard/core/errors/failures.dart';
import 'package:ai_keyboard/features/ai_service/domain/entities/ai_model.dart';
import 'package:ai_keyboard/features/settings/domain/entities/ai_provider_metadata.dart';
import 'package:ai_keyboard/features/settings/domain/entities/ai_provider_type.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('AI Keyboard Settings')),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state.failure != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure!.message),
                backgroundColor: Colors.red,
              ),
            );
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
                color: hasKey ? Colors.green.shade50 : Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        hasKey
                            ? Icons.check_circle
                            : Icons.warning_amber_rounded,
                        color: hasKey ? Colors.green : Colors.orange.shade800,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          hasKey
                              ? '${metadata.displayName} API Key configured.'
                              : '${metadata.displayName} API Key missing. Add key below.',
                          style: TextStyle(
                            color: hasKey
                                ? Colors.green.shade900
                                : Colors.orange.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'AI Provider Selection',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 20),
              const Text(
                'API Key',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _apiKeyController,
                obscureText: _obscureApiKey,
                decoration: InputDecoration(
                  labelText: '${metadata.displayName} API Key',
                  hintText: hasKey
                      ? '•••••••••••• (Key Configured)'
                      : 'Enter API Key',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureApiKey = !_obscureApiKey;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Don't have an API key?",
                    style: TextStyle(color: Colors.grey.shade700),
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
                    child: ElevatedButton.icon(
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${metadata.displayName} key saved securely!',
                                    ),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.save),
                      label: const Text('Save API Key'),
                    ),
                  ),
                  if (hasKey) ...[
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: state.isLoading
                          ? null
                          : () {
                              context.read<SettingsBloc>().add(
                                SettingsEvent.deleteApiKey(
                                  provider: activeProvider,
                                ),
                              );
                            },
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        'Delete Key',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Model Discovery',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            ],
          );
        },
      ),
    );
  }
}
