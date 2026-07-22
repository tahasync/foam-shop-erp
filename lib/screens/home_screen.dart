import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/update_checker.dart';
import '../widgets/custom_nav_bar.dart';
import 'inventory_screen.dart';
import 'sales_entry_screen.dart';
import 'customer_khata_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;
  bool _checkedUpdate = false;

  final _screens = [
    const DashboardScreen(),
    const SalesEntryScreen(),
    const InventoryScreen(),
    const CustomerKhataScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    if (_checkedUpdate) return;
    _checkedUpdate = true;
    try {
      final pkg = await PackageInfo.fromPlatform();
      final installed = pkg.version;
      final update = await checkForUpdate();
      if (update == null || !mounted) return;
      if (isNewerVersion(installed, update.tagName)) {
        showUpdateDialog(context, update);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(bottom: 96 + bottom),
        child: _screens[_tab],
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }

}
