import 'package:ai_keyboard/core/di/injection.dart';
import 'package:ai_keyboard/features/playground/data/services/keyboard_status_service.dart';
import 'package:ai_keyboard/features/settings/domain/entities/ai_provider_metadata.dart';
import 'package:ai_keyboard/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:ai_keyboard/features/settings/presentation/bloc/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class KeyboardPlaygroundPage extends StatefulWidget {
  const KeyboardPlaygroundPage({super.key, this.onNavigateToSettings});

  final VoidCallback? onNavigateToSettings;

  @override
  State<KeyboardPlaygroundPage> createState() => _KeyboardPlaygroundPageState();
}

class _KeyboardPlaygroundPageState extends State<KeyboardPlaygroundPage>
    with WidgetsBindingObserver {
  final _textController = TextEditingController();
  final _keyboardStatusService = getIt<KeyboardStatusService>();

  bool _isKeyboardActive = false;
  bool _isCheckingStatus = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkKeyboardStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkKeyboardStatus();
    }
  }

  Future<void> _checkKeyboardStatus() async {
    setState(() => _isCheckingStatus = true);
    final active = await _keyboardStatusService.isAiKeyboardActive();
    if (mounted) {
      setState(() {
        _isKeyboardActive = active;
        _isCheckingStatus = false;
      });
    }
  }

  void _populateExample(String text) {
    _textController.text = text;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keyboard Playground')),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          final activeProvider = state.settings.activeProvider;
          final metadata = AiProviderMetadata.getForType(activeProvider);
          final hasKey = state.hasApiKeyMap[activeProvider] ?? false;
          final activeModel = state.settings.activeModelId;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Text(
                'Test Your AI Keyboard',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Type text below and use @commands (like @fix) to transform text using your native keyboard.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 20),
              Card(
                color: _isKeyboardActive
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isKeyboardActive
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: _isKeyboardActive
                                ? Colors.green
                                : Colors.orange.shade800,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _isKeyboardActive
                                ? 'AI Keyboard Active'
                                : 'AI Keyboard Not Active',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _isKeyboardActive
                                  ? Colors.green.shade900
                                  : Colors.orange.shade900,
                            ),
                          ),
                          const Spacer(),
                          if (_isCheckingStatus)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      if (!_isKeyboardActive) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Enable and select AI Keyboard in Android System Settings to test transformation.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _keyboardStatusService.openKeyboardSettings();
                          },
                          icon: const Icon(Icons.settings),
                          label: const Text('Select AI Keyboard'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Configuration Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Provider:',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          Text(
                            metadata.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        spacing: 12,
                        children: [
                          Text(
                            'Model:',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                          Expanded(
                            child: Text(
                              activeModel.isEmpty
                                  ? 'Not selected'
                                  : activeModel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'API Key:',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          Text(
                            hasKey ? 'Configured ✓' : 'Not Configured ⚠️',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: hasKey ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      if (!hasKey && widget.onNavigateToSettings != null) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: widget.onNavigateToSettings,
                          icon: const Icon(Icons.tune, size: 16),
                          label: const Text('Configure AI Settings'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Try Your AI Keyboard',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _textController,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText:
                      'Tap here to open AI Keyboard and type text with @fix...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _textController.clear(),
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Try an Example',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.auto_fix_high, size: 16),
                    label: const Text('Grammar Fix (@fix)'),
                    onPressed: () =>
                        _populateExample('I am going office tomorrow @fix '),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.spellcheck, size: 16),
                    label: const Text('Simple Grammar (@fix)'),
                    onPressed: () =>
                        _populateExample('she don\'t like this @fix '),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade800),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tip: Text transformation is executed by the Android native keyboard service, not inside this app.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
