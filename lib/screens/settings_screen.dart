import 'package:erp_system/db/database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../services/backup_service.dart';
import '../core/theme.dart';
import '../widgets/app_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() { super.initState(); _tabs = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(children: [
          Row(children: [
            Text('الإعدادات', style: Theme.of(context).textTheme.headlineSmall),
          ]),
          const SizedBox(height: 16),
          TabBar(controller: _tabs, tabs: const [
            Tab(text: 'معلومات الشركة'), Tab(text: 'إعدادات النظام'),
            Tab(text: 'المستخدمون'), Tab(text: 'النسخ الاحتياطي'),
          ]),
        ]),
      ),
      Expanded(child: TabBarView(controller: _tabs, children: [
        _CompanyTab(), _SystemTab(), _UsersTab(), _BackupTab(),
      ])),
    ]);
  }
}

// ── Company Tab ───────────────────────────────────────────────────────────────
class _CompanyTab extends StatefulWidget {
  @override State<_CompanyTab> createState() => _CompanyTabState();
}
class _CompanyTabState extends State<_CompanyTab> {
  late Map<String, TextEditingController> _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsProvider>().settings;
    _ctrl = {
      'company_name'   : TextEditingController(text: s['company_name'] ?? ''),
      'company_name_en': TextEditingController(text: s['company_name_en'] ?? ''),
      'company_phone'  : TextEditingController(text: s['company_phone'] ?? ''),
      'company_email'  : TextEditingController(text: s['company_email'] ?? ''),
      'company_address': TextEditingController(text: s['company_address'] ?? ''),
      'company_website': TextEditingController(text: s['company_website'] ?? ''),
      'tax_number'     : TextEditingController(text: s['tax_number'] ?? ''),
      'commercial_register': TextEditingController(text: s['commercial_register'] ?? ''),
      'invoice_footer' : TextEditingController(text: s['invoice_footer'] ?? ''),
    };
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final sp = context.read<SettingsProvider>();
    final updates = _ctrl.map((k, v) => MapEntry(k, v.text.trim()));
    await sp.updateSettings(updates);
    setState(() => _saving = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الحفظ بنجاح')));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('معلومات الشركة', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Wrap(spacing: 16, runSpacing: 16, children: [
          _f('company_name', 'اسم الشركة (عربي)', 320),
          _f('company_name_en', 'Company Name (English)', 320),
          _f('company_phone', 'الهاتف', 220),
          _f('company_email', 'البريد الإلكتروني', 280),
          _f('company_website', 'الموقع الإلكتروني', 280),
          _f('tax_number', 'الرقم الضريبي', 260),
          _f('commercial_register', 'السجل التجاري', 260),
          _f('company_address', 'العنوان', 620),
          _f('invoice_footer', 'تذييل الفاتورة', 620),
        ]),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving ? const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_rounded, size: 18),
          label: const Text('حفظ التغييرات'),
        ),
      ]),
    );
  }

  Widget _f(String key, String label, double w) => SizedBox(width: w,
      child: TextFormField(controller: _ctrl[key], decoration: InputDecoration(labelText: label)));
}

// ── System Tab ────────────────────────────────────────────────────────────────
class _SystemTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sp      = context.watch<SettingsProvider>();
    final isLight = sp.themeMode != ThemeMode.dark;
    final colors  = [
      const Color(0xFF1565C0), const Color(0xFF00695C), const Color(0xFF880E4F),
      const Color(0xFF4A148C), const Color(0xFFBF360C), const Color(0xFF263238),
      const Color(0xFF1B5E20), const Color(0xFF0D47A1),
    ];

    return ListView(padding: const EdgeInsets.all(24), children: [
      _SectionCard(title: 'اللغة والمنطقة', children: [
        ListTile(
          title: const Text('اللغة'),
          trailing: DropdownButton<String>(
            value: sp.language,
            items: const [
              DropdownMenuItem(value: 'ar', child: Text('العربية')),
              DropdownMenuItem(value: 'en', child: Text('English')),
            ],
            onChanged: (v) => sp.setSetting('language', v!),
          ),
        ),
        ListTile(
          title: const Text('العملة'),
          trailing: SizedBox(width: 140, child: DropdownButton<String>(
            value: sp.get('currency', defaultValue: 'ريال'),
            items: [
              ('ريال','ريال سعودي'), ('دينار','دينار كويتي'),
              ('درهم','درهم إماراتي'), ('جنيه','جنيه مصري'),
              ('USD','دولار أمريكي'),
            ].map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2))).toList(),
            onChanged: (v) => sp.setSetting('currency', v!),
          )),
        ),
        ListTile(
          title: const Text('نسبة الضريبة الافتراضية (%)'),
          trailing: SizedBox(width: 100, child: TextFormField(
            initialValue: sp.get('tax_rate', defaultValue: '15'),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (v) => sp.setSetting('tax_rate', v),
            decoration: const InputDecoration(suffixText: '%'),
          )),
        ),
      ]),
      const SizedBox(height: 16),
      _SectionCard(title: 'المظهر', children: [
        ListTile(
          title: const Text('الوضع'),
          trailing: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, label: Text('فاتح'), icon: Icon(Icons.light_mode_outlined)),
              ButtonSegment(value: ThemeMode.dark,  label: Text('داكن'),  icon: Icon(Icons.dark_mode_outlined)),
              ButtonSegment(value: ThemeMode.system,label: Text('تلقائي'),icon: Icon(Icons.auto_mode_outlined)),
            ],
            selected: {sp.themeMode},
            onSelectionChanged: (s) {
              final v = s.first == ThemeMode.dark ? 'dark' : s.first == ThemeMode.system ? 'system' : 'light';
              sp.setSetting('theme', v);
            },
          ),
        ),
        ListTile(
          title: const Text('لون التطبيق'),
          subtitle: Wrap(spacing: 8, children: colors.map((c) => InkWell(
            onTap: () => sp.setSetting('primary_color', c.value.toString()),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: c, borderRadius: BorderRadius.circular(8),
                border: sp.primaryColor.value == c.value
                    ? Border.all(color: Colors.white, width: 3) : null,
                boxShadow: sp.primaryColor.value == c.value
                    ? [BoxShadow(color: c.withOpacity(.5), blurRadius: 8)] : [],
              ),
            ),
          )).toList()),
        ),
      ]),
      const SizedBox(height: 16),
      _SectionCard(title: 'ترقيم الفواتير', children: [
        ListTile(title: const Text('بادئة فواتير المبيعات'),
            trailing: SizedBox(width: 120, child: TextFormField(
              initialValue: sp.get('sales_prefix', defaultValue: 'INV'),
              onChanged: (v) => sp.setSetting('sales_prefix', v),
            ))),
        ListTile(title: const Text('بادئة فواتير المشتريات'),
            trailing: SizedBox(width: 120, child: TextFormField(
              initialValue: sp.get('purchase_prefix', defaultValue: 'PUR'),
              onChanged: (v) => sp.setSetting('purchase_prefix', v),
            ))),
        ListTile(title: const Text('بادئة المصروفات'),
            trailing: SizedBox(width: 120, child: TextFormField(
              initialValue: sp.get('expense_prefix', defaultValue: 'EXP'),
              onChanged: (v) => sp.setSetting('expense_prefix', v),
            ))),
      ]),
    ]);
  }
}

// ── Users Tab ─────────────────────────────────────────────────────────────────
class _UsersTab extends StatefulWidget {
  @override State<_UsersTab> createState() => _UsersTabState();
}
class _UsersTabState extends State<_UsersTab> {
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final users = await context.read<AuthProvider>().getAllUsers();
    setState(() => _users = users);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          onPressed: () => _addUserDialog(),
          icon: const Icon(Icons.person_add_outlined, size: 18),
          label: const Text('إضافة مستخدم'),
        ),
      )),
      Expanded(child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _users.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final u = _users[i];
          return ListTile(
            leading: CircleAvatar(child: Text((u['full_name'] ?? u['username'] ?? 'U')[0])),
            title: Text(u['full_name']?.toString() ?? u['username']?.toString() ?? ''),
            subtitle: Text('${u['username']}  ·  ${u['role'] == 'admin' ? 'مدير' : 'مستخدم'}'),
            trailing: u['role'] != 'admin' ? IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {},
            ) : null,
          );
        },
      )),
    ]);
  }

  void _addUserDialog() {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String role    = 'user';
    showDialog(context: context, builder: (_) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: const Text('إضافة مستخدم'),
        content: SizedBox(width: 360, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم الكامل')),
          const SizedBox(height: 12),
          TextFormField(controller: userCtrl, decoration: const InputDecoration(labelText: 'اسم المستخدم *')),
          const SizedBox(height: 12),
          TextFormField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور *')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: role,
            decoration: const InputDecoration(labelText: 'الصلاحية'),
            items: [('admin','مدير'),('user','مستخدم')]
                .map((r) => DropdownMenuItem(value: r.$1, child: Text(r.$2))).toList(),
            onChanged: (v) => setS(() => role = v!),
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () async {

            await AppDatabase.instance.insert('users', {
              'username': userCtrl.text.trim(), 'password': passCtrl.text.trim(),
              'full_name': nameCtrl.text.trim(), 'role': role, 'is_active': 1,
            });
            if (ctx.mounted) Navigator.pop(ctx);
            _load();
          }, child: const Text('إضافة')),
        ],
      ),
    ));
  }
}

// ── Backup Tab ────────────────────────────────────────────────────────────────
class _BackupTab extends StatefulWidget {
  @override State<_BackupTab> createState() => _BackupTabState();
}
class _BackupTabState extends State<_BackupTab> {
  List<dynamic> _backups = [];
  bool _loading = false;

  @override
  void initState() { super.initState(); _loadBackups(); }

  Future<void> _loadBackups() async {
    final b = await BackupService.instance.listBackups();
    setState(() => _backups = b);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(24), children: [
      _SectionCard(title: 'إدارة النسخ الاحتياطية', children: [
        ListTile(
          leading: Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.green.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.backup_outlined, color: Colors.green)),
          title: const Text('إنشاء نسخة احتياطية', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('حفظ قاعدة البيانات الحالية'),
          trailing: ElevatedButton(
            onPressed: _loading ? null : () async {
              setState(() => _loading = true);
              try {
                final path = await BackupService.instance.createBackup();
                await _loadBackups();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم الحفظ: $path')));
              } finally { setState(() => _loading = false); }
            },
            child: const Text('إنشاء'),
          ),
        ),
        ListTile(
          leading: Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.restore_rounded, color: Colors.orange)),
          title: const Text('استعادة نسخة احتياطية', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('تحذير: سيتم استبدال البيانات الحالية'),
          trailing: OutlinedButton(
            onPressed: () async {
              final ok = await showConfirmDialog(context,
                  title: 'استعادة نسخة احتياطية',
                  content: 'هذا سيستبدل جميع البيانات الحالية. هل أنت متأكد؟',
                  isDanger: true);
              if (ok) {
                try {
                  await BackupService.instance.restoreBackup();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم الاستعادة بنجاح')));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('استعادة'),
          ),
        ),
      ]),
      if (_backups.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text('النسخ الاحتياطية المحفوظة (${_backups.length})',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ..._backups.take(10).map((f) {
          final name = f.path.toString().split('/').last.split('\\').last;
          return ListTile(
            leading: const Icon(Icons.storage_outlined, color: Colors.grey),
            title: Text(name, style: const TextStyle(fontSize: 13)),
            dense: true,
          );
        }),
      ],
      const SizedBox(height: 16),
      _SectionCard(title: 'معلومات النظام', children: [
        ListTile(title: const Text('إصدار النظام'), trailing: const Text('2.0.0', style: TextStyle(fontWeight: FontWeight.w700))),
        ListTile(title: const Text('قاعدة البيانات'), trailing: const Text('SQLite (محلي)', style: TextStyle(fontWeight: FontWeight.w700))),
        ListTile(title: const Text('حالة الشبكة'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          const Text('غير متصل (وضع عمل بدون إنترنت)', style: TextStyle(fontSize: 12)),
        ])),
      ]),
    ]);
  }
}

class _SectionCard extends StatelessWidget {
  final String title; final List<Widget> children;
  const _SectionCard({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLight ? const Color(0xFFE8ECF0) : const Color(0xFF2D3748)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
        const Divider(height: 1),
        ...children,
      ]),
    );
  }
}
