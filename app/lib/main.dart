import 'package:ai_keyboard/core/di/injection.dart';
import 'package:ai_keyboard/features/commands/presentation/bloc/command_bloc.dart';
import 'package:ai_keyboard/features/commands/presentation/bloc/command_event.dart';
import 'package:ai_keyboard/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:ai_keyboard/features/settings/presentation/bloc/settings_event.dart';
import 'package:ai_keyboard/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const AiKeyboardApp());
}

class AiKeyboardApp extends StatelessWidget {
  const AiKeyboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<SettingsBloc>()..add(const SettingsEvent.loadSettings()),
        ),
        BlocProvider(
          create: (_) =>
              getIt<CommandBloc>()..add(const CommandEvent.loadCommands()),
        ),
      ],
      child: MaterialApp(
        title: 'AI Keyboard Utility',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const SettingsPage(),
      ),
    );
  }
}
