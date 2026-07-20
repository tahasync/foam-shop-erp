import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../widgets/sync_status_indicator.dart';
import '../widgets/custom_nav_bar.dart';
import 'inventory_screen.dart';
import 'sales_entry_screen.dart';
import 'customer_khata_screen.dart';
import 'supplier_khata_screen.dart';
import 'dashboard_screen.dart';
import 'expense_sheet_screen.dart';
import 'customer_recovery_screen.dart';
import 'billing_screen.dart';
import 'reports_screen.dart';
import 'export_screen.dart';
import 'account_settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  final _screens = [
    const DashboardScreen(),
    const SalesEntryScreen(),
    const InventoryScreen(),
    const CustomerKhataScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const SizedBox.shrink(),
        actions: [
          const SyncStatusIndicator(),
          const SizedBox(width: 4),
            PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 14,
              backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null ? const Icon(Icons.person_rounded, size: 16) : null,
            ),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'settings', child: Text('Account / Settings')),
              const PopupMenuItem(value: 'billing', child: Text('Billing')),
              const PopupMenuItem(value: 'expenses', child: Text('Expenses')),
              const PopupMenuItem(value: 'recovery', child: Text('Recovery')),
              const PopupMenuItem(value: 'supplier', child: Text('Supplier Khata')),
              const PopupMenuItem(value: 'reports', child: Text('Reports')),
              const PopupMenuItem(value: 'export', child: Text('Export Reports')),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'signout', child: Text('Sign Out', style: TextStyle(color: Theme.of(context).colorScheme.error))),
            ],
            onSelected: (v) async {
              if (v == 'signout') await authService.signOut();
              else if (v == 'settings') _push(context, const AccountSettingsScreen());
              else if (v == 'billing') _push(context, const BillingScreen());
              else if (v == 'expenses') _push(context, const ExpenseSheetScreen());
              else if (v == 'recovery') _push(context, const CustomerRecoveryScreen());
              else if (v == 'supplier') _push(context, const SupplierKhataScreen());
              else if (v == 'reports') _push(context, const ReportsScreen());
              else if (v == 'export') _push(context, const ExportScreen());
            },
          ),
        ],
      ),
      body: _screens[_tab],
      bottomNavigationBar: CustomNavBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}
