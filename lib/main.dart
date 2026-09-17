import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'providers/journal_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/link_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => LinkProvider()),
      ],
      child: const HawkApp(),
    ),
  );
}

class HawkApp extends StatelessWidget {
  const HawkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HAWK Dashboard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const InitialAuthCheck(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InitialAuthCheck extends StatefulWidget {
  const InitialAuthCheck({super.key});

  @override
  State<InitialAuthCheck> createState() => _InitialAuthCheckState();
}

class _InitialAuthCheckState extends State<InitialAuthCheck> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = await authProvider.checkAuthStatus();
    
    if (!mounted) return;
    
    if (isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
