import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/app_settings_model.dart';
import '../../../data/models/flooring_type_model.dart';
import '../../../data/models/user_model.dart';
import '../application/admin_providers.dart';
import 'widgets/flooring_type_form_sheet.dart';

/// Route: /admin — gate this behind UserRole.admin in your router's redirect.
///
/// [initialTab] controls which tab opens first:
///   0 = Flooring Types, 1 = Settings, 2 = Users. Defaults to 0.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Flooring Types'),
            Tab(text: 'Settings'),
            Tab(text: 'Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FlooringTypesTab(),
          _SettingsTab(),
          _UsersTab(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1: Flooring Types
// ---------------------------------------------------------------------------

class _FlooringTypesTab extends ConsumerWidget {
  const _FlooringTypesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(flooringTypesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => showFlooringTypeFormSheet(context),
        child: const Icon(Icons.add),
      ),
      body: typesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load flooring types: $e')),
        data: (types) {
          if (types.isEmpty) {
            return const Center(child: Text('No flooring types yet. Tap + to add one.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: types.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => _FlooringTypeTile(type: types[i]),
          );
        },
      ),
    );
  }
}

class _FlooringTypeTile extends ConsumerWidget {
  const _FlooringTypeTile({required this.type});

  final FlooringTypeModel type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(type.name),
      subtitle: Text(
        'Pack: ${type.packSize} m² • €${type.pricePerSqm.toStringAsFixed(2)}/m²',
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'edit') {
            showFlooringTypeFormSheet(context, existing: type);
          } else if (value == 'delete') {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Delete flooring type?'),
                content: Text('This removes "${type.name}". This cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await ref.read(flooringTypeFormControllerProvider.notifier).delete(type.id);
            }
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2: Settings (company details + default wastage %)
// ---------------------------------------------------------------------------

class _SettingsTab extends ConsumerWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load settings: $e')),
      data: (settings) => _SettingsForm(settings: settings),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({required this.settings});

  final AppSettingsModel settings;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _wastageCtrl;

  @override
  void initState() {
    super.initState();
    _initControllers(widget.settings);
  }

  void _initControllers(AppSettingsModel s) {
    _nameCtrl = TextEditingController(text: s.companyName);
    _addressCtrl = TextEditingController(text: s.companyAddress);
    _phoneCtrl = TextEditingController(text: s.companyPhone);
    _emailCtrl = TextEditingController(text: s.companyEmail);
    _wastageCtrl = TextEditingController(text: s.defaultWastagePct.toString());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _wastageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.settings.copyWith(
      companyName: _nameCtrl.text.trim(),
      companyAddress: _addressCtrl.text.trim(),
      companyPhone: _phoneCtrl.text.trim(),
      companyEmail: _emailCtrl.text.trim(),
      defaultWastagePct: double.parse(_wastageCtrl.text.trim()),
    );

    await ref.read(settingsFormControllerProvider.notifier).save(updated);

    if (!mounted) return;
    final error = ref.read(settingsFormControllerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error != null ? 'Could not save: $error' : 'Settings saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(settingsFormControllerProvider).isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Company Details', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Company name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                return v.contains('@') ? null : 'Enter a valid email';
              },
            ),
            const SizedBox(height: 24),
            Text('Defaults', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _wastageCtrl,
              decoration: const InputDecoration(
                labelText: 'Default wastage %',
                helperText: 'Pre-fills the wastage field when a new room is added',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n < 0) return 'Enter a valid percentage';
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: saving ? null : _save,
              child: saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save settings'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 3: Users (view roles, change role)
// ---------------------------------------------------------------------------

class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load users: $e')),
      data: (users) {
        if (users.isEmpty) return const Center(child: Text('No users yet.'));
        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final user = users[i];
            return ListTile(
              title: Text(user.name),
              subtitle: Text(user.email),
              trailing: DropdownButton<UserRole>(
                value: user.role,
                items: UserRole.values
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                    .toList(),
                onChanged: (role) {
                  if (role == null) return;
                  ref.read(userRoleControllerProvider.notifier).updateRole(user.id, role);
                },
              ),
            );
          },
        );
      },
    );
  }
}