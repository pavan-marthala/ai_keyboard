import 'package:ai_keyboard/core/di/injection.dart';
import 'package:ai_keyboard/core/theme/app_theme.dart';
import 'package:ai_keyboard/core/utils/app_buitton.dart';
import 'package:ai_keyboard/core/utils/app_text_field.dart';
import 'package:ai_keyboard/core/utils/check_platforms.dart';
import 'package:ai_keyboard/core/utils/sized_context.dart';
import 'package:ai_keyboard/features/desktop_onboarding/domain/entities/desktop_capability.dart';
import 'package:ai_keyboard/features/desktop_onboarding/domain/repositories/desktop_capability_repository.dart';
import 'package:ai_keyboard/features/playground/data/services/keyboard_status_service.dart';
import 'package:ai_keyboard/features/settings/domain/entities/ai_provider_metadata.dart';
import 'package:ai_keyboard/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:ai_keyboard/features/settings/presentation/bloc/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class KeyboardPlaygroundPage extends StatefulWidget {
  const KeyboardPlaygroundPage({super.key});

  @override
  State<KeyboardPlaygroundPage> createState() => _KeyboardPlaygroundPageState();
}

class _KeyboardPlaygroundPageState extends State<KeyboardPlaygroundPage>
    with WidgetsBindingObserver {
  final _textController = TextEditingController();
  final _keyboardStatusService = getIt<KeyboardStatusService>();
  final _desktopCapabilityRepository = getIt<DesktopCapabilityRepository>();

  bool _isKeyboardActive = false;
  bool _isCheckingStatus = true;
  List<DesktopCapability> _desktopCapabilities = [];

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
    if (PlatformChecker.isDesktop()) {
      final capabilities = await _desktopCapabilityRepository.getCapabilities();
      if (mounted) {
        final allEnabled =
            capabilities.isNotEmpty &&
            capabilities
                .where((c) => c.isRequired)
                .every((c) => c.status == DesktopCapabilityStatus.enabled);
        setState(() {
          _desktopCapabilities = capabilities;
          _isKeyboardActive = allEnabled;
          _isCheckingStatus = false;
        });
      }
    } else {
      final active = await _keyboardStatusService.isAiKeyboardActive();
      if (mounted) {
        setState(() {
          _isKeyboardActive = active;
          _isCheckingStatus = false;
        });
      }
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
      // appBar: AppBar(title: const Text('Keyboard Playground')),
      body: SafeArea(
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            final activeProvider = state.settings.activeProvider;
            final metadata = AiProviderMetadata.getForType(activeProvider);
            final hasKey = state.hasApiKeyMap[activeProvider] ?? false;
            final activeModel = state.settings.activeModelId;

            return ListView(
              padding: EdgeInsets.only(
                bottom: context.viewInsets.bottom + 100,
                top: 16,
                left: 16,
                right: 16,
              ),
              children: [
                Text('Test Your AI Keyboard', style: typo.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Type text below and use @commands (like @fix) to transform text using your native keyboard.',
                  style: typo.bodyMedium,
                ),
                const SizedBox(height: 20),
                _buildStatusCard(context),
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
                        if (!hasKey) ...[
                          const SizedBox(height: 12),
                          AppButton(
                            text: "Configure API Key",
                            color: colors.card,
                            onPressed: () {
                              StatefulNavigationShell.of(context).goBranch(1);
                            },
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            icon: Icon(
                              Icons.tune,
                              size: 20,
                              color: colors.primary,
                            ),
                            side: BoxBorder.all(
                              color: colors.primary,
                              width: 2,
                            ),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Try Your AI Keyboard',
                        style: typo.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _textController.clear(),
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _textController,
                  hintText:
                      'Tap here to open AI Keyboard and type text with @fix...',
                ),
                const SizedBox(height: 20),
                Text(
                  'Try a command',
                  style: typo.titleMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    CommandChip(
                      avatar: Icon(
                        Icons.auto_fix_high,
                        size: 14,
                        color: colors.primary,
                      ),
                      label: 'Grammar ',
                      command: '@fix',
                      onPressed: () =>
                          _populateExample('I am going office tomorrow @fix '),
                    ),

                    CommandChip(
                      avatar: Icon(Icons.edit, size: 14, color: colors.primary),
                      label: 'Rewrite',
                      command: '@rewrite',
                      onPressed: () => _populateExample(
                        'I need to tell you something important @rewrite ',
                      ),
                    ),
                    CommandChip(
                      avatar: Icon(Icons.work, size: 14, color: colors.primary),
                      label: 'Professional',
                      command: '@pro',
                      onPressed: () => _populateExample(
                        'hey send me the report when you can @pro ',
                      ),
                    ),
                    CommandChip(
                      avatar: Icon(
                        Icons.chat_bubble_outline,
                        size: 14,
                        color: colors.primary,
                      ),
                      label: 'Casual',
                      command: '@casual',
                      onPressed: () => _populateExample(
                        'I would like to know if you are available tomorrow @casual ',
                      ),
                    ),
                    CommandChip(
                      avatar: Icon(
                        Icons.compress,
                        size: 14,
                        color: colors.primary,
                      ),
                      label: 'Shorten',
                      command: '@short',
                      onPressed: () => _populateExample(
                        'I wanted to let you know that I will not be able to attend the meeting tomorrow @short ',
                      ),
                    ),
                    CommandChip(
                      avatar: Icon(
                        Icons.expand,
                        size: 14,
                        color: colors.primary,
                      ),
                      label: 'Expand',
                      command: '@expand',
                      onPressed: () =>
                          _populateExample('The project is delayed @expand '),
                    ),
                    CommandChip(
                      avatar: Icon(
                        Icons.translate,
                        size: 14,
                        color: colors.primary,
                      ),
                      label: 'Translate Spanish',
                      command: '@translate:es',
                      onPressed: () =>
                          _populateExample('I am going home @translate:es '),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final colors = context.appColors;
    final typo = context.appTypography;

    if (PlatformChecker.isDesktop()) {
      final missingCapabilities = _desktopCapabilities
          .where((c) => c.status != DesktopCapabilityStatus.enabled)
          .toList();

      return Card(
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
                        : Icons.warning_amber_rounded,
                    color: _isKeyboardActive ? colors.success : colors.warning,
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
              const SizedBox(height: 8),
              Text(
                _isKeyboardActive
                    ? 'AI Keyboard has the necessary system permissions to detect commands and transform text.'
                    : 'AI Keyboard requires system permissions to detect commands and interact with active text fields.',
                style: typo.bodyMedium.copyWith(
                  fontSize: 13,
                  color: _isKeyboardActive
                      ? colors.textSecondary
                      : colors.warning,
                ),
              ),
              if (!_isKeyboardActive && missingCapabilities.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...missingCapabilities.map((capability) {
                  final isUnknown =
                      capability.status == DesktopCapabilityStatus.unknown;
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    capability.title,
                                    style: typo.titleMedium.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (isUnknown
                                                  ? colors.primary300
                                                  : colors.warning)
                                              .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isUnknown
                                          ? 'Verify in Settings'
                                          : 'Required',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isUnknown
                                            ? colors.primary300
                                            : colors.warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isUnknown
                                    ? 'Status cannot be verified automatically. Verify or enable this permission in System Settings.'
                                    : capability.description,
                                style: typo.bodyMedium.copyWith(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => _desktopCapabilityRepository
                              .openSystemSettings(capability.type),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.textPrimary,
                            side: BorderSide(color: colors.borderLight),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Open Settings',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      );
    }

    // Mobile (Android / iOS)
    return Card(
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
                  color: _isKeyboardActive ? colors.success : colors.warning,
                ),
                const SizedBox(width: 10),
                Text(
                  _isKeyboardActive
                      ? 'AI Keyboard Active'
                      : 'AI Keyboard Not Active',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _isKeyboardActive ? colors.success : colors.warning,
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
    );
  }
}

class CommandChip extends StatelessWidget {
  const CommandChip({
    super.key,
    required this.label,
    required this.command,
    required this.avatar,
    required this.onPressed,
  });
  final String label;
  final String command;
  final Widget avatar;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typo = context.appTypography;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        color: colors.surfaceDark,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Container(
                //   height: 30,
                //   width: 30,
                //   decoration: BoxDecoration(
                //     color: colors.primary.withValues(alpha: 0.10),
                //     borderRadius: BorderRadius.circular(12),
                //   ),
                //   child: avatar,
                // ),
                // const SizedBox(width: 6),

                Text(
                  command,
                  style: typo.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 6),

                Text(
                  label,
                  style: typo.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
