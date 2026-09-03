import 'package:ai_keyboard/core/di/injection.dart';
import 'package:ai_keyboard/core/theme/app_theme.dart';
import 'package:ai_keyboard/core/utils/app_buitton.dart';
import 'package:ai_keyboard/core/utils/app_text_field.dart';
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
    final colors = context.appColors;
    final typo = context.appTypography;
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
              Text('Test Your AI Keyboard', style: typo.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Type text below and use @commands (like @fix) to transform text using your native keyboard.',
                style: typo.bodyMedium,
              ),
              const SizedBox(height: 20),
              Card(
                color: _isKeyboardActive
                    ? colors.success.withValues(alpha: 0.10)
                    : colors.warning.withValues(alpha: 0.10),
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
                                ? colors.success
                                : colors.warning,
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
                                  ? colors.success
                                  : colors.warning,
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
                          style: typo.bodyMedium.copyWith(
                            fontSize: 13,
                            color: colors.warning,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          text: "Select AI Keyboard",
                          color: colors.warning,
                          onPressed: () async {
                            await _keyboardStatusService.openKeyboardSettings();
                          },
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          icon: const Icon(Icons.settings, size: 20),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: colors.card,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Configuration Summary',
                        style: typo.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Provider:',
                            style: typo.bodyMedium.copyWith(
                              color: colors.textSecondary,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            metadata.displayName,
                            style: typo.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                            style: typo.bodyMedium.copyWith(
                              color: colors.textSecondary,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                          Flexible(
                            child: Text(
                              activeModel.isEmpty
                                  ? 'Not selected'
                                  : activeModel,
                              style: typo.bodyMedium.copyWith(
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
                            style: typo.bodyMedium.copyWith(
                              color: colors.textSecondary,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            hasKey ? 'Configured ✓' : 'Not Configured ⚠️',
                            style: typo.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: hasKey ? colors.success : colors.error,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (!hasKey && widget.onNavigateToSettings != null) ...[
                        const SizedBox(height: 12),
                        AppButton(
                          text: "Configure API Key",
                          color: colors.card,
                          onPressed: widget.onNavigateToSettings,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          icon: Icon(
                            Icons.tune,
                            size: 20,
                            color: colors.primary,
                          ),
                          side: BoxBorder.all(color: colors.primary, width: 2),
                          textStyle: typo.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Try Your AI Keyboard',
                style: typo.titleMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _textController,
                hintText:
                    'Tap here to open AI Keyboard and type text with @fix...',
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
              Text(
                'Try an Example',
                style: typo.titleMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.auto_fix_high, size: 16),
                    label: const Text('Fix Grammar (@fix)'),
                    onPressed: () =>
                        _populateExample('I am going office tomorrow @fix '),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.edit, size: 16),
                    label: const Text('Rewrite (@rewrite)'),
                    onPressed: () => _populateExample(
                      'I need to tell you something important @rewrite ',
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.work, size: 16),
                    label: const Text('Professional (@pro)'),
                    onPressed: () => _populateExample(
                      'hey send me the report when you can @pro ',
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Casual (@casual)'),
                    onPressed: () => _populateExample(
                      'I would like to know if you are available tomorrow @casual ',
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.compress, size: 16),
                    label: const Text('Shorten (@short)'),
                    onPressed: () => _populateExample(
                      'I wanted to let you know that I will not be able to attend the meeting tomorrow @short ',
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.expand, size: 16),
                    label: const Text('Expand (@expand)'),
                    onPressed: () =>
                        _populateExample('The project is delayed @expand '),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.translate, size: 16),
                    label: const Text('Translate Spanish (@translate:es)'),
                    onPressed: () =>
                        _populateExample('I am going home @translate:es '),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tip: Text transformation is executed by the Android native keyboard service, not inside this app.',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
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
