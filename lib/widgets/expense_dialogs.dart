import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reset_flow/models/expense.dart';
import 'package:reset_flow/providers/expense_provider.dart';

class AddExpenseDialog extends StatefulWidget {
  final ExpenseNotifier notifier;
  final Expense? initialExpense;

  const AddExpenseDialog({super.key, required this.notifier, this.initialExpense});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _amountController = TextEditingController();
  final _labelController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    if (widget.initialExpense != null) {
      _amountController.text = widget.initialExpense!.amount.toString();
      _labelController.text = widget.initialExpense!.label;
      _selectedDate = widget.initialExpense!.date;
      _selectedCategoryId = widget.initialExpense!.categoryId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.notifier.state.categories;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(widget.initialExpense == null ? 'Add Expense' : 'Edit Expense'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(labelText: 'Label (e.g. Lunch, Uber)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder()),
                child: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: categories.map((cat) {
                return DropdownMenuItem(
                  value: cat.id,
                  child: Row(
                    children: [
                      Icon(IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'), color: Color(cat.colorValue), size: 18),
                      const SizedBox(width: 8),
                      Text(cat.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedCategoryId = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text);
            if (amount != null && _selectedCategoryId != null) {
              if (widget.initialExpense == null) {
                widget.notifier.addExpense(_selectedCategoryId!, amount, _selectedDate, _labelController.text);
              } else {
                widget.notifier.updateExpense(widget.initialExpense!.copyWith(
                  categoryId: _selectedCategoryId!,
                  amount: amount,
                  date: _selectedDate,
                  label: _labelController.text,
                ));
              }
              Navigator.pop(context);
            }
          },
          child: Text(widget.initialExpense == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}

class ManageCategoriesDialog extends StatefulWidget {
  final ExpenseNotifier notifier;

  const ManageCategoriesDialog({super.key, required this.notifier});

  @override
  State<ManageCategoriesDialog> createState() => _ManageCategoriesDialogState();
}

class _ManageCategoriesDialogState extends State<ManageCategoriesDialog> {
  @override
  Widget build(BuildContext context) {
    final categories = widget.notifier.state.categories;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Manage Categories'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return ListTile(
              leading: Icon(IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'), color: Color(cat.colorValue)),
              title: Text(cat.name),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => widget.notifier.deleteCategory(cat.id),
              ),
              onTap: () => _showCategoryDialog(context, cat),
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ElevatedButton.icon(
          onPressed: () => _showCategoryDialog(context, null),
          icon: const Icon(Icons.add),
          label: const Text('New Category'),
        ),
      ],
    );
  }

  void _showCategoryDialog(BuildContext context, ExpenseCategory? initialCat) {
    final nameController = TextEditingController(text: initialCat?.name ?? '');
    int selectedIcon = initialCat?.iconCodePoint ?? Icons.category.codePoint;
    int selectedColorValue = initialCat?.colorValue ?? Colors.blue.value;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(initialCat == null ? 'Add Category' : 'Edit Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Category Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text('Select Color', style: TextStyle(fontSize: 12)),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
                    Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
                    Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
                    Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
                    Colors.brown, Colors.grey, Colors.blueGrey, Colors.black
                  ].map((c) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setDialogState(() => selectedColorValue = c.value),
                      child: CircleAvatar(
                        backgroundColor: c,
                        radius: 12,
                        child: selectedColorValue == c.value ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                      ),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Select Icon', style: TextStyle(fontSize: 12)),
              Wrap(
                spacing: 8,
                children: [
                  Icons.restaurant, Icons.home, Icons.flight, Icons.medical_services,
                  Icons.movie, Icons.shopping_bag, Icons.directions_car, Icons.school,
                  Icons.fitness_center, Icons.work, Icons.sports_esports, Icons.pets,
                ].map((icon) => GestureDetector(
                  onTap: () => setDialogState(() => selectedIcon = icon.codePoint),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: selectedIcon == icon.codePoint ? Color(selectedColorValue).withOpacity(0.2) : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(icon, color: selectedIcon == icon.codePoint ? Color(selectedColorValue) : Colors.grey),
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  if (initialCat == null) {
                    widget.notifier.addCategory(nameController.text, selectedIcon, selectedColorValue);
                  } else {
                    widget.notifier.updateCategory(initialCat.copyWith(
                      name: nameController.text,
                      iconCodePoint: selectedIcon,
                      colorValue: selectedColorValue,
                    ));
                  }
                  Navigator.pop(context);
                  setState(() {}); // Refresh categories list
                }
              },
              child: Text(initialCat == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
