import 'package:ai_keyboard/features/settings/domain/entities/ai_provider_type.dart';
import 'package:ai_keyboard/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:ai_keyboard/features/settings/presentation/bloc/settings_event.dart';
import 'package:ai_keyboard/features/settings/presentation/bloc/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    final state = context.read<SettingsBloc>().state;
    _modelController.text = state.settings.activeModelId;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Keyboard Settings')),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (_modelController.text != state.settings.activeModelId) {
            _modelController.text = state.settings.activeModelId;
          }
        },
        builder: (context, state) {
          final hasKey = state.hasApiKeyMap[AiProviderType.openAi] ?? false;

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
                          hasKey ? 'OpenAI API Key configured securely.' : 'OpenAI API Key not configured. AI commands will be disabled.',
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
                'AI Provider Configuration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AiProviderType>(
                initialValue: state.settings.activeProvider,
                decoration: const InputDecoration(
                  labelText: 'Active AI Provider',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: AiProviderType.openAi,
                    child: Text('OpenAI'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    context.read<SettingsBloc>().add(
                      SettingsEvent.updateSettings(
                        state.settings.copyWith(activeProvider: value),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: 'Model ID',
                  hintText: 'e.g. gpt-4o-mini, gpt-4o',
                  border: OutlineInputBorder(),
                  helperText: 'Default: gpt-4o-mini',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _apiKeyController,
                obscureText: _obscureApiKey,
                decoration: InputDecoration(
                  labelText: 'OpenAI API Key',
                  hintText: 'sk-...',
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
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () {
                        final key = _apiKeyController.text.trim();
                        final model = _modelController.text.trim();

                        if (model.isNotEmpty) {
                          context.read<SettingsBloc>().add(
                            SettingsEvent.updateSettings(
                              state.settings.copyWith(activeModelId: model),
                            ),
                          );
                        }

                        if (key.isNotEmpty) {
                          context.read<SettingsBloc>().add(
                            SettingsEvent.saveApiKey(
                              provider: AiProviderType.openAi,
                              apiKey: key,
                            ),
                          );
                          _apiKeyController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('API Key saved securely!'),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.save),
                label: const Text('Save Settings'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              if (hasKey) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          context.read<SettingsBloc>().add(
                            const SettingsEvent.deleteApiKey(
                              provider: AiProviderType.openAi,
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('API Key deleted.')),
                          );
                        },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'Delete API Key',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
