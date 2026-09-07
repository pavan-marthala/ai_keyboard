import 'package:flutter/material.dart';
import 'package:open_at_login/open_at_login.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final OpenAtLogin openAtLogin = OpenAtLogin.instance;
  openAtLogin.initialize(
    appName: 'OpenAtLogin Example',
    appPath: '/Applications/OpenAtLogin Example.app',
  );
  openAtLogin.setEnabled(true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenAtLogin Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'OpenAtLogin Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late bool _isEnabled;
  late final OpenAtLogin _openAtLogin;

  @override
  initState() {
    super.initState();
    _openAtLogin = OpenAtLogin.instance;
    _isEnabled = false;
    _openAtLogin.isEnabled().then((value) {
      setState(() {
        _isEnabled = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'OpenAtLogin is ${_isEnabled ? "enabled" : "disabled"}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _openAtLogin.setEnabled(!_isEnabled).then((_) {
                  setState(() {
                    _isEnabled = !_isEnabled;
                  });
                });
              },
              child: Text(_isEnabled ? 'Disable' : 'Enable'),
            ),
          ],
        ),
      ),
    );
  }
}
