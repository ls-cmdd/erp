import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import '../providers/settings_provider.dart';
import '../core/utils.dart';
import 'dashboard_screen.dart';
import 'sales_screen.dart';
import 'purchases_screen.dart';
import 'customers_screen.dart';
import 'suppliers_screen.dart';
import 'products_screen.dart';
import 'inventory_screen.dart';
import 'finance_screen.dart';
import 'hr_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WindowListener {
  bool _railExpanded = true;

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_outlined,        activeIcon: Icons.dashboard_rounded,        label: 'لوحة التحكم'),
    _NavItem(icon: Icons.point_of_sale_outlined,    activeIcon: Icons.point_of_sale_rounded,    label: 'المبيعات'),
    _NavItem(icon: Icons.shopping_basket_outlined,  activeIcon: Icons.shopping_basket_rounded,  label: 'المشتريات'),
    _NavItem(icon: Icons.people_outline,            activeIcon: Icons.people_rounded,           label: 'العملاء'),
    _NavItem(icon: Icons.local_shipping_outlined,   activeIcon: Icons.local_shipping_rounded,   label: 'الموردون'),
    _NavItem(icon: Icons.inventory_2_outlined,      activeIcon: Icons.inventory_2_rounded,      label: 'المنتجات'),
    _NavItem(icon: Icons.warehouse_outlined,        activeIcon: Icons.warehouse_rounded,        label: 'المخزون'),
    _NavItem(icon: Icons.account_balance_outlined,  activeIcon: Icons.account_balance_rounded,  label: 'المالية'),
    _NavItem(icon: Icons.badge_outlined,            activeIcon: Icons.badge_rounded,            label: 'الموارد البشرية'),
    _NavItem(icon: Icons.bar_chart_outlined,        activeIcon: Icons.bar_chart_rounded,        label: 'التقارير'),
    _NavItem(icon: Icons.settings_outlined,         activeIcon: Icons.settings_rounded,         label: 'الإعدادات'),
  ];

  static const _pages = [
    DashboardScreen(),
    SalesScreen(),
    PurchasesScreen(),
    CustomersScreen(),
    SuppliersScreen(),
    ProductsScreen(),
    InventoryScreen(),
    FinanceScreen(),
    HRScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void _logout() {
    context.read<AuthProvider>().logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final idx      = context.watch<AppProvider>().selectedIndex;
    final cs       = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();
    final auth     = context.watch<AuthProvider>();
    final isLight  = Theme.of(context).brightness == Brightness.light;

    final sidebarBg = isLight ? Colors.white : const Color(0xFF111827);
    final borderClr = isLight ? const Color(0xFFE8ECF0) : const Color(0xFF1F2937);

    return Scaffold(
      body: Row(children: [
        // ── Sidebar ──────────────────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          width: _railExpanded ? 230 : 72,
          decoration: BoxDecoration(
            color: sidebarBg,
            border: Border(right: BorderSide(color: borderClr)),
          ),
          child: Column(children: [
            // Header
            DragToMoveArea(
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.primary.withOpacity(.7)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.business_center_rounded,
                        color: Colors.white, size: 20),
                  ),
                  if (_railExpanded) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('ERP System',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                              color: cs.onSurface),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(() => _railExpanded = !_railExpanded),
                    icon: Icon(_railExpanded ? Icons.menu_open_rounded : Icons.menu_rounded,
                        size: 20, color: Colors.grey[500]),
                    splashRadius: 18,
                  ),
                ]),
              ),
            ),
            const Divider(height: 1),
            // Nav items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                itemCount: _navItems.length,
                itemBuilder: (_, i) {
                  final item    = _navItems[i];
                  final active  = idx == i;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Material(
                      color: active
                          ? cs.primary.withOpacity(.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.read<AppProvider>().setSelectedIndex(i),
                        child: Container(
                          height: 44,
                          padding: EdgeInsets.symmetric(
                              horizontal: _railExpanded ? 12 : 10),
                          child: Row(children: [
                            Icon(active ? item.activeIcon : item.icon,
                                size: 20,
                                color: active ? cs.primary : Colors.grey[500]),
                            if (_railExpanded) ...[
                              const SizedBox(width: 12),
                              Text(item.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                    color: active ? cs.primary : Colors.grey[600],
                                  )),
                            ],
                          ]),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            // User section
            Padding(
              padding: const EdgeInsets.all(8),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _logout,
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: cs.primary.withOpacity(.15),
                        child: Text(
                          auth.userName.isNotEmpty ? auth.userName[0] : 'A',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                              color: cs.primary),
                        ),
                      ),
                      if (_railExpanded) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(auth.userName,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis),
                              Text(auth.userRole == 'admin' ? 'مدير النظام' : 'مستخدم',
                                  style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                            ],
                          ),
                        ),
                        Icon(Icons.logout_rounded, size: 16, color: Colors.grey[400]),
                      ],
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
        // ── Content ───────────────────────────────────────────────────────
        Expanded(child: IndexedStack(index: idx, children: _pages)),
      ]),
    );
  }
}

class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
