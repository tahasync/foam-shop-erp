import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/opening_balance.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/theme_provider.dart';

class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final authState = ref.watch(authStateProvider);
    final authService = ref.watch(authServiceProvider);
    final user = authState.asData?.value;
    final obAsync = ref.watch(openingBalanceStreamProvider);
    final themeMode = ref.watch(themeModeProvider);

    final openingBal = obAsync.asData?.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Account / Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                CircleAvatar(
                  radius: 36,
                  backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                  child: user?.photoURL == null ? const Icon(Icons.person_rounded, size: 36) : null,
                ),
                const SizedBox(height: 12),
                Text(user?.displayName ?? '', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(user?.email ?? '', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(children: [
              ListTile(
                leading: Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.account_balance_rounded, color: cs.onPrimaryContainer)),
                title: const Text('Shuru ka Capital'),
                subtitle: Text('Rs. ${(openingBal?.capitalAmount ?? 0).toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.edit_rounded),
                onTap: () => _editCapital(context, ref, openingBal),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(children: [
                  Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.brightness_6_rounded, size: 18, color: cs.onSecondaryContainer)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Theme: ${themeMode == ThemeMode.light ? 'Light' : themeMode == ThemeMode.dark ? 'Dark' : 'System'}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  SizedBox(
                    width: 160,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded, size: 16)),
                        ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_6_rounded, size: 16)),
                        ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded, size: 16)),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (v) => ref.read(themeModeProvider.notifier).setMode(v.first),
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: cs.primaryContainer,
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(Icons.logout_rounded, color: cs.error),
              title: Text('Sign Out', style: TextStyle(color: cs.error)),
              onTap: () async {
                final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Local data will be cleared. Cloud copy stays safe.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out')),
                  ],
                ));
                if (ok == true) await authService.signOut();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _editCapital(BuildContext context, WidgetRef ref, OpeningBalance? current) {
    final ctrl = TextEditingController(text: (current?.capitalAmount ?? 0).toStringAsFixed(0));
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Shuru ka Capital'),
      content: SingleChildScrollView(child: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Opening Capital (PKR)', filled: true), keyboardType: TextInputType.number)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          try {
            final a = double.tryParse(ctrl.text) ?? 0;
            if (a < 0) return;
            final s = ref.read(firestoreServiceProvider);
            await s.setOpeningBalance(OpeningBalance(
                id: current?.id ?? s.generateId(), date: DateTime.now(), capitalAmount: a));
            if (ctx.mounted) Navigator.pop(ctx);
          } catch (e) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Save failed: $e'), backgroundColor: Theme.of(ctx).colorScheme.error));
            }
          }
        }, child: const Text('Save')),
      ],
    )).then((_) => ctrl.dispose());
  }
}
