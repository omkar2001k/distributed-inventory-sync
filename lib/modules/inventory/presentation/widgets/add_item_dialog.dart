import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/inventory_item_entity.dart';

/// Modal dialog allowing warehouse operators to create a new inventory SKU.
class AddItemDialog extends StatefulWidget {
  const AddItemDialog({super.key});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _quantityController = TextEditingController(text: '10');
  final _minStockController = TextEditingController(text: '5');
  String _selectedCategory = 'Equipment';

  final List<String> _categories = [
    'Equipment',
    'Electronics',
    'Packaging',
    'Safety',
    'Power & Battery',
    'Storage',
    'Tools',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final item = InventoryItemEntity(
        id: 'item-${const Uuid().v4().substring(0, 8)}',
        name: _nameController.text.trim(),
        sku: _skuController.text.trim().toUpperCase(),
        category: _selectedCategory,
        quantity: int.tryParse(_quantityController.text) ?? 0,
        minStock: int.tryParse(_minStockController.text) ?? 5,
        lastModified: DateTime.now().toUtc(),
        version: 1,
      );
      Navigator.of(context).pop(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.add_box_rounded, color: Colors.blueAccent),
          SizedBox(width: 8),
          Text('Add New Warehouse Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  hintText: 'e.g. Industrial Barcode Scanner',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(
                  labelText: 'SKU Code',
                  hintText: 'e.g. WH-EQ-909',
                  prefixIcon: Icon(Icons.qr_code_2_rounded),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a SKU' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Initial Units',
                        prefixIcon: Icon(Icons.numbers_rounded),
                      ),
                      validator: (val) {
                        final numVal = int.tryParse(val ?? '');
                        if (numVal == null || numVal < 0) return 'Must be >= 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _minStockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Min Alert Stock',
                        prefixIcon: Icon(Icons.warning_amber_rounded),
                      ),
                      validator: (val) {
                        final numVal = int.tryParse(val ?? '');
                        if (numVal == null || numVal < 0) return 'Must be >= 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Add Item'),
        ),
      ],
    );
  }
}
