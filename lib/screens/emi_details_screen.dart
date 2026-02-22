import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reset_flow/models/emi_model.dart';
import 'package:reset_flow/providers/emi_provider.dart';
import 'package:reset_flow/providers/monetary_provider.dart';

class EMIDetailScreen extends ConsumerWidget {
  final String planId;
  const EMIDetailScreen({super.key, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emiState = ref.watch(emiProvider);
    final plan = emiState.plans.firstWhere((p) => p.id == planId, orElse: () => throw 'Plan not found');
    final installments = emiState.installments[planId] ?? [];
    final colorScheme = Theme.of(context).colorScheme;

    int paidCount = installments.where((i) => i.isPaid).length;
    double paidAmount = installments.where((i) => i.isPaid).fold(0, (sum, i) => sum + i.amount);
    double remainingAmount = plan.totalAmount - paidAmount;
    double progress = installments.isEmpty ? 0 : paidCount / installments.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(plan.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'Preclose Plan',
            onPressed: remainingAmount > 0 ? () => _confirmPreclose(context, ref) : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete Plan',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Stats
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5))),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 8,
                            backgroundColor: colorScheme.outlineVariant.withOpacity(0.5),
                            valueColor: AlwaysStoppedAnimation(plan.type == 'credit' ? Colors.green : Colors.orange),
                          ),
                        ),
                        Text('${(progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatRow('Total Principal', '₹${plan.totalAmount.toStringAsFixed(0)}'),
                          const SizedBox(height: 8),
                          _buildStatRow('Remaining', '₹${remainingAmount.toStringAsFixed(2)}', isBold: true, color: plan.type == 'credit' ? Colors.green : Colors.orange),
                          const SizedBox(height: 8),
                          _buildStatRow('Installments', '$paidCount / ${plan.installmentCount} paid'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PROVIDER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                        Text(plan.provider, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('START DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                        Text(DateFormat('MMM dd, yyyy').format(plan.startDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Installment List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: installments.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final inst = installments[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  leading: CircleAvatar(
                    backgroundColor: inst.isPaid 
                      ? (plan.type == 'credit' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1))
                      : colorScheme.surfaceVariant,
                    child: Icon(
                      inst.isPaid ? Icons.check : Icons.event, 
                      color: inst.isPaid ? (plan.type == 'credit' ? Colors.green : Colors.orange) : Colors.grey,
                      size: 20,
                    ),
                  ),
                  title: Text(DateFormat('MMMM yyyy').format(inst.dueDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('₹${inst.amount.toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (inst.isPaid)
                        TextButton(
                          onPressed: () => ref.read(emiProvider.notifier).unpayInstallment(inst),
                          child: const Text('Unpay', style: TextStyle(color: Colors.red, fontSize: 12)),
                        )
                      else
                        FilledButton.tonal(
                          onPressed: () => ref.read(emiProvider.notifier).payInstallment(inst, plan),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(0, 32),
                          ),
                          child: const Text('Pay', style: TextStyle(fontSize: 12)),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _showEditAmountDialog(context, ref, inst),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: TextStyle(
          fontSize: isBold ? 14 : 12, 
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color,
        )),
      ],
    );
  }

  void _confirmPreclose(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preclose Plan?'),
        content: const Text('This will mark all remaining installments as paid. Associated transactions will NOT be created for individual months.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(emiProvider.notifier).preclosePlan(planId);
              Navigator.pop(context);
            },
            child: const Text('Preclose'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete EMI Plan?'),
        content: const Text('This will delete the plan and all its installments. Individual transactions already created will NOT be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(emiProvider.notifier).deletePlan(planId);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close detail screen
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditAmountDialog(BuildContext context, WidgetRef ref, EMIInstallment inst) {
    final controller = TextEditingController(text: inst.amount.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Amount'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0;
              if (val > 0) {
                ref.read(emiProvider.notifier).updateInstallmentAmount(inst.id, val);
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
