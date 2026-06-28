import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────
Future<bool> showConfirmDialog(BuildContext ctx, {
  required String title, required String content,
  String confirmText = 'تأكيد', bool isDanger = false,
}) async {
  final r = await showDialog<bool>(context: ctx, builder: (_) => AlertDialog(
    title: Text(title),
    content: Text(content),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
      ElevatedButton(
        onPressed: () => Navigator.pop(ctx, true),
        style: isDanger ? ElevatedButton.styleFrom(backgroundColor: AppTheme.danger) : null,
        child: Text(confirmText),
      ),
    ],
  ));
  return r ?? false;
}

// ── AppSearchBar ──────────────────────────────────────────────────────────────
class AppSearchBar extends StatelessWidget {
  final String hint;
  final void Function(String) onChanged;
  final TextEditingController? controller;
  const AppSearchBar({super.key, required this.hint, required this.onChanged, this.controller});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.search_rounded, size: 20),
      suffixIcon: controller != null && (controller!.text.isNotEmpty)
          ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18),
              onPressed: () { controller!.clear(); onChanged(''); })
          : null,
    ),
  );
}

// ── EmptyState ────────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon; final String title; final String? subtitle; final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(48),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 80, color: Colors.grey[200]),
        const SizedBox(height: 16),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey[500]), textAlign: TextAlign.center),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: TextStyle(fontSize: 14, color: Colors.grey[400]), textAlign: TextAlign.center),
        ],
        if (action != null) ...[const SizedBox(height: 24), action!],
      ]),
    ),
  );
}

// ── LoadingOverlay ────────────────────────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  final Widget child; final bool isLoading;
  const LoadingOverlay({super.key, required this.child, required this.isLoading});

  @override
  Widget build(BuildContext context) => Stack(children: [
    child,
    if (isLoading) const ColoredBox(color: Color(0x44000000),
        child: Center(child: CircularProgressIndicator())),
  ]);
}
