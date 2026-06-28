import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form     = GlobalKey<FormState>();
  final _userCtrl = TextEditingController(text: 'admin');
  final _passCtrl = TextEditingController(text: 'admin123');
  bool _obscure   = true;
  bool _loading   = false;
  String? _error;

  Future<void> _login() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });
    final result = await context.read<AuthProvider>()
        .login(_userCtrl.text.trim(), _passCtrl.text.trim());
    if (!mounted) return;
    if (result.isSuccess) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainShell(),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      setState(() {
        _loading = false;
        _error = result.message ?? 'اسم المستخدم أو كلمة المرور غير صحيحة';
      });
    }
  }

  @override
  void dispose() { _userCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      body: Row(children: [
        // Left panel – branding
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, Color.lerp(cs.primary, Colors.black, .35)!],
                begin: Alignment.topRight, end: Alignment.bottomLeft,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.12),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(Icons.business_center_rounded,
                      size: 72, color: Colors.white),
                ),
                const SizedBox(height: 32),
                const Text('نظام ERP المتكامل',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(height: 12),
                Text('إدارة متكاملة لجميع القطاعات',
                    style: TextStyle(fontSize: 16,
                        color: Colors.white.withOpacity(.75))),
                const SizedBox(height: 48),
                ...[ ('المبيعات والمشتريات', Icons.shopping_cart_outlined),
                     ('المخزون والمنتجات',   Icons.inventory_2_outlined),
                     ('المالية والحسابات',   Icons.account_balance_outlined),
                     ('الموارد البشرية',     Icons.people_outline),
                     ('التقارير والإحصاءات', Icons.bar_chart_outlined),
                ].map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 56),
                  child: Row(children: [
                    Icon(e.$2, color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                    Text(e.$1, style: const TextStyle(color: Colors.white70, fontSize: 15)),
                  ]),
                )),
              ],
            ),
          ),
        ),
        // Right panel – form
        Container(
          width: 460,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('تسجيل الدخول',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text('أدخل بياناتك للمتابعة',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                    const SizedBox(height: 36),
                    TextFormField(
                      controller: _userCtrl,
                      decoration: const InputDecoration(
                        labelText: 'اسم المستخدم',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v?.isEmpty ?? true) ? 'مطلوب' : null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v?.isEmpty ?? true) ? 'مطلوب' : null,
                      onFieldSubmitted: (_) => _login(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        child: _loading
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('دخول', style: TextStyle(fontSize: 17)),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text('الإصدار 2.0.0  ·  نظام ERP المتكامل',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
