import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/product_provider.dart';
import '../providers/dashboard_provider.dart';
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
  bool _invLowStockFilter = false;
  String? _invHighlightId;

  @override
  void initState() {
    super.initState();
    _checkUpdate();
  }

  void _goToInventory() {
    final products = ref.read(productsStreamProvider).asData?.value ?? [];
    final lowStock = products.where((p) => p.isLowStock).toList();
    if (lowStock.length == 1) {
      _invHighlightId = lowStock.first.id;
      _invLowStockFilter = false;
    } else {
      _invLowStockFilter = lowStock.isNotEmpty;
      _invHighlightId = null;
    }
    setState(() => _tab = 2);
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
    final as = ref.watch(accountingSummaryProvider);
    final lowStockCount = as.asData?.value.lowStockCount ?? 0;
    final khataCount = ref.watch(accountingSummaryProvider).asData?.value.totalCustomerBaqaya ?? 0;

    final screens = <Widget>[
      DashboardScreen(onLowStockTap: _goToInventory),
      const SalesEntryScreen(),
      InventoryScreen(
        initialLowStockFilter: _invLowStockFilter,
        highlightProductId: _invHighlightId,
      ),
      const CustomerKhataScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: screens[_tab],
      bottomNavigationBar: Container(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 26, offset: const Offset(0, 10)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: CustomNavBar(
                  currentIndex: _tab,
                  onTap: (i) => setState(() => _tab = i),
                  showInventoryDot: lowStockCount > 0,
                  showKhataDot: khataCount > 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
