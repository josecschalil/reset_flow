import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reset_flow/models/expense.dart';
import 'package:reset_flow/providers/expense_provider.dart';

class AddExpenseDialog extends StatefulWidget {
  final ExpenseNotifier notifier;
  final Expense? initialExpense;
  final String? initialCategoryId;

  const AddExpenseDialog(
      {super.key,
      required this.notifier,
      this.initialExpense,
      this.initialCategoryId});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  static const _navy = Color(0xFF1E3A5F);
  static const _ink = Color(0xFF14202E);
  static const _muted = Color(0xFF5F6B7A);
  static const _field = Color(0xFFF8F9FB);
  static const _line = Color(0xFFDFE3E9);

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
    } else if (widget.initialCategoryId != null) {
      _selectedCategoryId = widget.initialCategoryId;
    }
  }

  InputDecoration _fieldDecoration(String label, {Widget? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _muted, fontWeight: FontWeight.w500),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: _field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _navy, width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _line),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.notifier.state.categories;
    final isEditing = widget.initialExpense != null;

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      actionsPadding: const EdgeInsets.fromLTRB(12, 4, 20, 16),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2F7),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.receipt_long_outlined, color: _navy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isEditing ? 'Edit expense' : 'Add expense',
              style: const TextStyle(
                color: _ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _amountController,
                style:
                    const TextStyle(color: _ink, fontWeight: FontWeight.w600),
                decoration: _fieldDecoration(
                  'Amount',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 14, right: 4),
                    child: Text('₹',
                        style: TextStyle(
                            color: _navy,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ),
                ).copyWith(prefixIconConstraints: const BoxConstraints()),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _labelController,
                style: const TextStyle(color: _ink),
                decoration: _fieldDecoration('Label (e.g. Lunch, Uber)',
                    prefixIcon: const Icon(Icons.edit_outlined,
                        size: 19, color: _muted)),
              ),
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
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
                    decoration: _fieldDecoration('Date',
                        prefixIcon: const Icon(Icons.calendar_today_outlined,
                            size: 18, color: _muted)),
                    child:
                        Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                isExpanded: true,
                decoration: _fieldDecoration('Category',
                    prefixIcon: const Icon(Icons.category_outlined,
                        size: 19, color: _muted)),
                items: categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Row(
                      children: [
                        Icon(
                            IconData(cat.iconCodePoint,
                                fontFamily: 'MaterialIcons'),
                            color: Color(cat.colorValue),
                            size: 18),
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text);
            if (amount != null && _selectedCategoryId != null) {
              if (isEditing) {
                widget.notifier.updateExpense(widget.initialExpense!.copyWith(
                  categoryId: _selectedCategoryId!,
                  amount: amount,
                  date: _selectedDate,
                  label: _labelController.text,
                ));
              } else {
                widget.notifier.addExpense(_selectedCategoryId!, amount,
                    _selectedDate, _labelController.text);
              }
              Navigator.pop(context);
            }
          },
          child: Text(isEditing ? 'Save changes' : 'Add expense'),
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
              leading: Icon(
                  IconData(cat.iconCodePoint, fontFamily: 'MaterialIcons'),
                  color: Color(cat.colorValue)),
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
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
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
                decoration: const InputDecoration(
                    labelText: 'Category Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text('Select Color', style: TextStyle(fontSize: 12)),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Colors.red,
                    Colors.pink,
                    Colors.blueGrey,
                    Colors.teal,
                    Colors.blue,
                    Colors.lightBlue,
                    Colors.cyan,
                    Colors.blueAccent,
                    Colors.green,
                    Colors.lightGreen,
                    Colors.lime,
                    Colors.yellow,
                    Colors.amber,
                    Colors.orange,
                    Colors.deepOrange,
                    Colors.brown,
                    Colors.grey,
                    Colors.blueGrey,
                    Colors.black
                  ]
                      .map((c) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () => setDialogState(
                                  () => selectedColorValue = c.value),
                              child: CircleAvatar(
                                backgroundColor: c,
                                radius: 12,
                                child: selectedColorValue == c.value
                                    ? const Icon(Icons.check,
                                        size: 14, color: Colors.white)
                                    : null,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Select Icon', style: TextStyle(fontSize: 12)),
              Wrap(
                spacing: 8,
                children: [
                  Icons.restaurant,
                  Icons.home,
                  Icons.flight,
                  Icons.medical_services,
                  Icons.movie,
                  Icons.shopping_bag,
                  Icons.directions_car,
                  Icons.school,
                  Icons.fitness_center,
                  Icons.work,
                  Icons.sports_esports,
                  Icons.pets,
                ]
                    .map((icon) => GestureDetector(
                          onTap: () => setDialogState(
                              () => selectedIcon = icon.codePoint),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: selectedIcon == icon.codePoint
                                  ? Color(selectedColorValue).withOpacity(0.2)
                                  : null,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(icon,
                                color: selectedIcon == icon.codePoint
                                    ? Color(selectedColorValue)
                                    : Colors.grey),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  if (initialCat == null) {
                    widget.notifier.addCategory(
                        nameController.text, selectedIcon, selectedColorValue);
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
