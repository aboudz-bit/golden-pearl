import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../main.dart';

class AdminPromotions extends StatefulWidget {
  const AdminPromotions({super.key});

  @override
  State<AdminPromotions> createState() => _AdminPromotionsState();
}

class _AdminPromotionsState extends State<AdminPromotions> {
  List<Map<String, dynamic>> _discounts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDiscounts();
  }

  Future<void> _loadDiscounts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await apiService.getAllDiscounts();
      setState(() {
        _discounts = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool _isExpired(Map<String, dynamic> discount) {
    final expiresAt = discount['expiresAt'];
    if (expiresAt == null) return false;
    try {
      final date = DateTime.parse(expiresAt.toString());
      return date.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  bool _isActive(Map<String, dynamic> discount) {
    return discount['active'] == true && !_isExpired(discount);
  }

  String _formatValue(Map<String, dynamic> discount) {
    final type = discount['type'] ?? 'percentage';
    final value = (discount['value'] as num?) ?? 0;
    if (type == 'percentage') {
      return '${value}%';
    }
    return '${(value / 100).toStringAsFixed(2)} SAR';
  }

  Future<void> _toggleActive(Map<String, dynamic> discount) async {
    final id = discount['id'] as int;
    final current = discount['active'] == true;
    try {
      await apiService.updateDiscount(id, {'active': !current});
      _loadDiscounts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteDiscount(Map<String, dynamic> discount) async {
    final id = discount['id'] as int;
    final code = discount['code'] ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Discount'),
        content: Text('Are you sure you want to delete "$code"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await apiService.deleteDiscount(id);
        _loadDiscounts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _openForm({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final codeController = TextEditingController(text: existing?['code'] ?? '');
    final valueController = TextEditingController(
      text: existing != null ? ((existing['value'] as num?) ?? 0).toString() : '',
    );
    final minOrderController = TextEditingController(
      text: existing != null ? ((existing['minOrder'] as num?) ?? (existing['minOrderAmount'] as num?) ?? 0).toString() : '',
    );
    final maxUsesController = TextEditingController(
      text: existing != null ? ((existing['maxUses'] as num?) ?? 0).toString() : '',
    );
    String selectedType = existing?['type'] ?? 'percentage';
    DateTime? expiresAt;
    if (existing?['expiresAt'] != null) {
      try {
        expiresAt = DateTime.parse(existing!['expiresAt'].toString());
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                        Text(
                          isEdit ? 'Edit Discount Code' : 'Add Discount Code',
                          style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: kCharcoal),
                        ),
                        const SizedBox(width: 48), // Spacer for centering
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: kDivider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('Code'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _inputDecoration('e.g. WELCOME20'),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Type'),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: kDivider),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedType,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)')),
                            DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount (SAR)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setSheetState(() => selectedType = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel(selectedType == 'percentage' ? 'Value (%)' : 'Value (in halalah)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: valueController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(selectedType == 'percentage' ? 'e.g. 15' : 'e.g. 5000 (= 50 SAR)'),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Min Order Amount (halalah)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: minOrderController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('e.g. 10000 (= 100 SAR)'),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Max Uses'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: maxUsesController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('e.g. 100'),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Expires At'),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: expiresAt ?? DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: kGoldPrimary,
                                  onPrimary: Colors.white,
                                  surface: kCardBg,
                                  onSurface: kCharcoal,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setSheetState(() => expiresAt = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: kDivider),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                expiresAt != null
                                    ? DateFormat('yyyy-MM-dd').format(expiresAt!)
                                    : 'Select date (optional)',
                                style: TextStyle(
                                  color: expiresAt != null ? kCharcoal : kSecondaryText,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Icon(Icons.calendar_today, color: kSecondaryText, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: isSubmitting ? null : () async {
                        final code = codeController.text.trim();
                        final valueStr = valueController.text.trim();
                        final minOrderStr = minOrderController.text.trim();
                        final maxUsesStr = maxUsesController.text.trim();

                        if (code.isEmpty || valueStr.isEmpty || minOrderStr.isEmpty || maxUsesStr.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('All fields are required')),
                          );
                          return;
                        }

                        final value = int.tryParse(valueStr) ?? 0;
                        final minOrder = int.tryParse(minOrderStr) ?? 0;
                        final maxUses = int.tryParse(maxUsesStr) ?? 0;

                        if (value <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Value must be greater than 0')),
                          );
                          return;
                        }

                        setSheetState(() => isSubmitting = true);

                        final data = <String, dynamic>{
                          'code': code,
                          'type': selectedType,
                          'value': value,
                          'minOrder': minOrder,
                          'maxUses': maxUses,
                        };
                        if (expiresAt != null) {
                          data['expiresAt'] = expiresAt!.toIso8601String().split('T')[0];
                        }

                        try {
                          if (isEdit) {
                            await apiService.updateDiscount(existing['id'] as int, data);
                          } else {
                            await apiService.createDiscount(data);
                          }
                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(isEdit ? 'Code updated successfully' : 'Code created successfully')),
                            );
                          }
                          _loadDiscounts();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                            );
                          }
                        } finally {
                          setSheetState(() => isSubmitting = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGoldPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSubmitting 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(isEdit ? 'Update Code' : 'Create Code'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kCharcoal),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: kSecondaryText.withOpacity(0.5), fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kGoldPrimary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCreamBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Promotions', style: playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: kCharcoal)),
        backgroundColor: kCreamBg,
        elevation: 0,
        foregroundColor: kCharcoal,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: kGoldPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Code'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kGoldPrimary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: kSecondaryText),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: kSecondaryText)),
                      const SizedBox(height: 16),
                      OutlinedButton(onPressed: _loadDiscounts, child: const Text('Retry')),
                    ],
                  ),
                )
              : _discounts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_offer_outlined, size: 64, color: kSecondaryText.withOpacity(0.4)),
                          const SizedBox(height: 16),
                          Text('No discount codes yet', style: TextStyle(color: kSecondaryText, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Tap "Add Code" to create one', style: TextStyle(color: kSecondaryText.withOpacity(0.6), fontSize: 13)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDiscounts,
                      color: kGoldPrimary,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: _discounts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final discount = _discounts[index];
                          return _buildDiscountCard(discount);
                        },
                      ),
                    ),
    );
  }

  Widget _buildDiscountCard(Map<String, dynamic> discount) {
    final code = discount['code'] ?? '';
    final type = discount['type'] ?? 'percentage';
    final active = _isActive(discount);
    final expired = _isExpired(discount);
    final uses = (discount['uses'] as num?)?.toInt() ?? 0;
    final maxUses = (discount['maxUses'] as num?)?.toInt() ?? 0;

    Color statusColor;
    String statusLabel;
    if (expired) {
      statusColor = const Color(0xFFE53935);
      statusLabel = 'Expired';
    } else if (active) {
      statusColor = const Color(0xFF43A047);
      statusLabel = 'Active';
    } else {
      statusColor = const Color(0xFFFFA000);
      statusLabel = 'Inactive';
    }

    Color typeBadgeColor = type == 'percentage'
        ? const Color(0xFF5C6BC0)
        : const Color(0xFF00897B);

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kDivider),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openForm(existing: discount),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        code,
                        style: playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: kCharcoal),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: typeBadgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        type == 'percentage' ? 'Percentage' : 'Fixed',
                        style: TextStyle(color: typeBadgeColor, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formatValue(discount),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kCharcoal),
                    ),
                    const Spacer(),
                    Icon(Icons.people_outline, size: 15, color: kSecondaryText),
                    const SizedBox(width: 4),
                    Text(
                      maxUses > 0 ? '$uses / $maxUses uses' : '$uses uses',
                      style: TextStyle(fontSize: 12, color: kSecondaryText),
                    ),
                  ],
                ),
                if ((discount['minOrder'] ?? discount['minOrderAmount']) != null && ((discount['minOrder'] as num?) ?? (discount['minOrderAmount'] as num?) ?? 0) > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Min order: ${(((discount['minOrder'] as num?) ?? (discount['minOrderAmount'] as num?) ?? 0) / 100).toStringAsFixed(2)} SAR',
                    style: TextStyle(fontSize: 12, color: kSecondaryText),
                  ),
                ],
                if (discount['expiresAt'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Expires: ${_formatDate(discount['expiresAt'])}',
                    style: TextStyle(fontSize: 12, color: expired ? const Color(0xFFE53935) : kSecondaryText),
                  ),
                ],
                const Divider(height: 20, color: kDivider),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _toggleActive(discount),
                      icon: Icon(
                        discount['active'] == true ? Icons.pause_circle_outline : Icons.play_circle_outline,
                        size: 18,
                      ),
                      label: Text(discount['active'] == true ? 'Deactivate' : 'Activate'),
                      style: TextButton.styleFrom(foregroundColor: kGoldPrimary),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: () => _deleteDiscount(discount),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFFE53935)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    try {
      final date = DateTime.parse(dateStr.toString());
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return dateStr.toString();
    }
  }
}
