import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/api_service.dart';

const _kModules = [
  {'key': 'dashboard', 'label': 'Dashboard', 'icon': Icons.dashboard_outlined, 'actions': ['view']},
  {'key': 'orders', 'label': 'Orders', 'icon': Icons.receipt_long_outlined, 'actions': ['view', 'updateStatus']},
  {'key': 'products', 'label': 'Products', 'icon': Icons.inventory_2_outlined, 'actions': ['view', 'create', 'edit', 'delete']},
  {'key': 'categories', 'label': 'Categories', 'icon': Icons.category_outlined, 'actions': ['view', 'edit']},
  {'key': 'banners', 'label': 'Banners', 'icon': Icons.photo_library_outlined, 'actions': ['view', 'edit']},
  {'key': 'customers', 'label': 'Customers', 'icon': Icons.people_outlined, 'actions': ['view', 'export']},
  {'key': 'notifications', 'label': 'Notifications', 'icon': Icons.notifications_outlined, 'actions': ['view', 'send', 'delete']},
  {'key': 'discountCodes', 'label': 'Discount Codes', 'icon': Icons.local_offer_outlined, 'actions': ['view', 'create', 'edit', 'delete']},
];

String _actionLabel(String action) {
  switch (action) {
    case 'view': return 'View';
    case 'create': return 'Create';
    case 'edit': return 'Edit';
    case 'delete': return 'Delete';
    case 'updateStatus': return 'Update Status';
    case 'send': return 'Send';
    case 'export': return 'Export';
    default: return action;
  }
}

class AdminStaffScreen extends StatefulWidget {
  const AdminStaffScreen({super.key});

  @override
  State<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends State<AdminStaffScreen> {
  List<Map<String, dynamic>> _staffUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() => _loading = true);
    try {
      _staffUsers = await apiService.getStaffUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading staff: $e'), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    bool active = true;

    final perms = <String, Map<String, bool>>{};
    for (final m in _kModules) {
      final key = m['key'] as String;
      final actions = m['actions'] as List<String>;
      perms[key] = { for (final a in actions) a: false };
    }
    perms['dashboard']!['view'] = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: kGoldPrimary.withOpacity(0.06),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: kGoldPrimary.withOpacity(0.12), shape: BoxShape.circle),
                          child: const Icon(Icons.person_add, color: kGoldPrimary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text('Add Staff Member', style: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: kCharcoal)),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildField('Name', nameCtrl, 'Full name'),
                          const SizedBox(height: 12),
                          _buildField('Email', emailCtrl, 'staff@goldenpearl.com', keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 12),
                          _buildField('Password', passwordCtrl, 'Min 6 characters', obscure: true),
                          const SizedBox(height: 12),
                          _buildField('Phone (optional)', phoneCtrl, '05xxxxxxxx', keyboardType: TextInputType.phone),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text('Active', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kCharcoal)),
                              const Spacer(),
                              Switch(
                                value: active,
                                activeColor: kGoldPrimary,
                                onChanged: (v) => setDialogState(() => active = v),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Text('Permissions', style: playfairDisplay(fontSize: 16, fontWeight: FontWeight.w600, color: kCharcoal)),
                          const SizedBox(height: 12),
                          ...(_kModules.map((m) {
                            final key = m['key'] as String;
                            final label = m['label'] as String;
                            final icon = m['icon'] as IconData;
                            final actions = m['actions'] as List<String>;
                            final modulePerms = perms[key]!;
                            return _buildPermissionModule(key, label, icon, actions, modulePerms, setDialogState);
                          })),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: kDivider)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGoldPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _createStaff(ctx, nameCtrl.text, emailCtrl.text, passwordCtrl.text, phoneCtrl.text, active, perms),
                        child: const Text('Create Staff', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, {bool obscure = false, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kSecondaryText)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: kCharcoal),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: kSecondaryText.withOpacity(0.5), fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kDivider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kDivider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kGoldPrimary)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionModule(String key, String label, IconData icon, List<String> actions, Map<String, bool> modulePerms, StateSetter setDialogState) {
    final allEnabled = actions.every((a) => modulePerms[a] == true);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kDivider),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          childrenPadding: const EdgeInsets.only(left: 14, right: 14, bottom: 10),
          leading: Icon(icon, color: kGoldPrimary, size: 20),
          title: Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kCharcoal))),
              Switch(
                value: allEnabled,
                activeColor: kGoldPrimary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (v) {
                  setDialogState(() {
                    for (final a in actions) {
                      modulePerms[a] = v;
                    }
                  });
                },
              ),
            ],
          ),
          children: actions.map((action) {
            return CheckboxListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: EdgeInsets.zero,
              activeColor: kGoldPrimary,
              title: Text(_actionLabel(action), style: const TextStyle(fontSize: 13, color: kCharcoal)),
              value: modulePerms[action] ?? false,
              onChanged: (v) => setDialogState(() => modulePerms[action] = v ?? false),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _createStaff(BuildContext ctx, String name, String email, String password, String phone, bool active, Map<String, Map<String, bool>> perms) async {
    if (name.trim().isEmpty || email.trim().isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name, email, and password are required'), backgroundColor: Colors.red));
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: Colors.red));
      return;
    }
    try {
      await apiService.createStaffUser({
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'phone': phone.trim().isNotEmpty ? phone.trim() : null,
        'isActive': active,
        'permissions': perms,
      });
      if (mounted) Navigator.pop(ctx);
      _loadStaff();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff member created'), backgroundColor: kGoldPrimary));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _showEditPermissions(Map<String, dynamic> staffUser) {
    final existingPerms = (staffUser['permissions'] as Map<String, dynamic>?) ?? {};
    final perms = <String, Map<String, bool>>{};
    for (final m in _kModules) {
      final key = m['key'] as String;
      final actions = m['actions'] as List<String>;
      final existing = (existingPerms[key] as Map<String, dynamic>?) ?? {};
      perms[key] = { for (final a in actions) a: existing[a] == true };
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: kGoldPrimary.withOpacity(0.06),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: kGoldPrimary.withOpacity(0.12), shape: BoxShape.circle),
                          child: const Icon(Icons.security, color: kGoldPrimary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Edit Permissions', style: playfairDisplay(fontSize: 16, fontWeight: FontWeight.w700, color: kCharcoal)),
                              Text(staffUser['name'] ?? '', style: const TextStyle(fontSize: 12, color: kSecondaryText)),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: _kModules.map((m) {
                          final key = m['key'] as String;
                          final label = m['label'] as String;
                          final icon = m['icon'] as IconData;
                          final actions = m['actions'] as List<String>;
                          return _buildPermissionModule(key, label, icon, actions, perms[key]!, setDialogState);
                        }).toList(),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: kDivider))),
                    child: SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGoldPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          try {
                            await apiService.updateStaffPermissions(staffUser['id'], perms);
                            if (mounted) Navigator.pop(ctx);
                            _loadStaff();
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissions updated'), backgroundColor: kGoldPrimary));
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                          }
                        },
                        child: const Text('Save Permissions', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _toggleActive(Map<String, dynamic> staffUser) async {
    final newActive = !(staffUser['isActive'] == true);
    try {
      await apiService.updateStaffUser(staffUser['id'], {'isActive': newActive});
      _loadStaff();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(newActive ? 'Staff member activated' : 'Staff member deactivated'),
          backgroundColor: kGoldPrimary,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _confirmDelete(Map<String, dynamic> staffUser) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Disable Staff?', style: TextStyle(fontWeight: FontWeight.w700, color: kCharcoal)),
        content: Text('This will disable ${staffUser['name']}\'s access. They will no longer be able to log in.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: kSecondaryText))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await apiService.deleteStaffUser(staffUser['id']);
                _loadStaff();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff member disabled'), backgroundColor: kGoldPrimary));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kGoldPrimary));
    }

    return RefreshIndicator(
      onRefresh: _loadStaff,
      color: kGoldPrimary,
      child: _staffUsers.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 100),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(color: kGoldPrimary.withOpacity(0.08), shape: BoxShape.circle),
                        child: const Icon(Icons.group_add, color: kGoldPrimary, size: 32),
                      ),
                      const SizedBox(height: 16),
                      Text('No Staff Members', style: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: kCharcoal)),
                      const SizedBox(height: 8),
                      const Text('Add staff to help manage the store', style: TextStyle(color: kSecondaryText, fontSize: 13)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGoldPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Staff'),
                        onPressed: _showCreateDialog,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _staffUsers.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Text('${_staffUsers.length} Staff Member${_staffUsers.length == 1 ? '' : 's'}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kCharcoal)),
                        const Spacer(),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kGoldPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add', style: TextStyle(fontSize: 13)),
                          onPressed: _showCreateDialog,
                        ),
                      ],
                    ),
                  );
                }
                final staff = _staffUsers[index - 1];
                return _buildStaffCard(staff);
              },
            ),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> staff) {
    final isActive = staff['isActive'] == true;
    final perms = (staff['permissions'] as Map<String, dynamic>?) ?? {};
    final enabledModules = <String>[];
    for (final m in _kModules) {
      final key = m['key'] as String;
      final label = m['label'] as String;
      final mp = (perms[key] as Map<String, dynamic>?) ?? {};
      if (mp.values.any((v) => v == true)) enabledModules.add(label);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isActive ? kDivider : Colors.red.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: isActive ? kGoldPrimary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (staff['name'] as String? ?? '?').substring(0, 1).toUpperCase(),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isActive ? kGoldPrimary : kSecondaryText),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(staff['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kCharcoal), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(isActive ? 'Active' : 'Disabled', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isActive ? Colors.green : Colors.red)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(staff['email'] ?? '', style: const TextStyle(fontSize: 12, color: kSecondaryText)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: kSecondaryText, size: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'permissions', child: Row(children: [Icon(Icons.security, size: 18, color: kGoldPrimary), SizedBox(width: 8), Text('Permissions')])),
                    PopupMenuItem(value: 'toggle', child: Row(children: [Icon(isActive ? Icons.block : Icons.check_circle, size: 18, color: isActive ? Colors.orange : Colors.green), SizedBox(width: 8), Text(isActive ? 'Deactivate' : 'Activate')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Disable', style: TextStyle(color: Colors.red))])),
                  ],
                  onSelected: (action) {
                    switch (action) {
                      case 'permissions': _showEditPermissions(staff); break;
                      case 'toggle': _toggleActive(staff); break;
                      case 'delete': _confirmDelete(staff); break;
                    }
                  },
                ),
              ],
            ),
          ),
          if (enabledModules.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: enabledModules.map((m) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kGoldPrimary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kGoldPrimary.withOpacity(0.15)),
                  ),
                  child: Text(m, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: kGoldPrimary)),
                )).toList(),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Text('No permissions assigned', style: TextStyle(fontSize: 11, color: kSecondaryText, fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }
}
