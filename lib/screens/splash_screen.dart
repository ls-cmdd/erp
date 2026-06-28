import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>    _fade;
  late Animation<double>    _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: .85, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final app  = context.read<AppProvider>();
    await app.init();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            auth.isAuthenticated ? const MainShell() : const LoginScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary, cs.primary.withBlue((cs.primary.blue + 30).clamp(0,255))],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 110, height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.15),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(Icons.business_center_rounded,
                        size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 28),
                  const Text('نظام ERP المتكامل',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                          color: Colors.white, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  Text('الإصدار 2.0',
                      style: TextStyle(fontSize: 15,
                          color: Colors.white.withOpacity(.75))),
                  const SizedBox(height: 56),
                  SizedBox(
                    width: 160,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white.withOpacity(.25),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                      minHeight: 3,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
