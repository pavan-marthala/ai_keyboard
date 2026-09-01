import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'features/commands/presentation/bloc/command_bloc.dart';
import 'features/commands/presentation/bloc/command_event.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/settings/presentation/bloc/settings_event.dart';

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
        home: const AppHomeScreen(),
      ),
    );
  }
}

class AppHomeScreen extends StatelessWidget {
  const AppHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Keyboard Utility')),
      body: const Center(
        child: Text(
          'AI Keyboard Utility Base Architecture Ready.\nConfigure settings and commands.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
