import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/auth_screen.dart';
import 'home/home_screen.dart';

class NavigationWrapper extends StatefulWidget {
  const NavigationWrapper({super.key});

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _getInitialSession();
    _listenToAuthChanges();
  }

  // Get the current session immediately
  void _getInitialSession() {
    final session = Supabase.instance.client.auth.currentSession;
    setState(() {
      _user = session?.user;
    });
  }

  // Listen to auth state changes
  void _listenToAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _user = data.session?.user;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If user is logged in, show HomeScreen
    if (_user != null) {
      return const HomeScreen();
    }

    // Otherwise, show AuthScreen
    return const AuthScreen();
  }
}
