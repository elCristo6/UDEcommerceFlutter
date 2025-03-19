import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/product_provider.dart';

class ProductCreateModal extends StatefulWidget {
  final Function(Product createdProduct) onSave;

  const ProductCreateModal({Key? key, required this.onSave}) : super(key: key);

  @override
  _ProductCreateModalState createState() => _ProductCreateModalState();
}

class _ProductCreateModalState extends State<ProductCreateModal> {
  final _formKey = GlobalKey<FormState>();

  // Inicializamos los controladores con valores vacíos.
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _stockController;
  late TextEditingController _categoryController;
  late TextEditingController _boxController;
  late TextEditingController _imageUrlController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    _stockController = TextEditingController();
    _categoryController = TextEditingController();
    _boxController = TextEditingController();
    _imageUrlController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    _boxController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _createProduct() async {
    // Se crea un nuevo producto; para el id se envía una cadena vacía, ya que el servidor generará el ID.
    final newProduct = Product(
      id: '',
      name: _nameController.text,
      price: _priceController.text.isNotEmpty
          ? double.tryParse(_priceController.text) ?? 0.0
          : 0.0,
      description: _descriptionController.text,
      box: _boxController.text.isNotEmpty
          ? _boxController.text
              .split(',')
              .map((s) => int.tryParse(s.trim()) ?? 0)
              .toList()
          : [],
      imageUrl: _imageUrlController.text,
      stock: _stockController.text.isNotEmpty
          ? int.tryParse(_stockController.text) ?? 0
          : 0,
      category: _categoryController.text,
      quantity: 1,
      updatedAt: DateTime.now(),
    );

    try {
      // Llamamos al método addProduct del ProductProvider (que realiza la petición POST)
      await Provider.of<ProductProvider>(context, listen: false)
          .addProduct(newProduct);
      // Opcional: refrescar la lista de productos
      await Provider.of<ProductProvider>(context, listen: false)
          .fetchProducts(forceUpdate: true);
      // Notificar al widget padre y cerrar el modal.
      widget.onSave(newProduct);
      Navigator.of(context).pop();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear el producto: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear Producto'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          // No incluimos validadores obligatorios para permitir campos vacíos.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Precio'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              TextFormField(
                controller: _boxController,
                decoration: const InputDecoration(
                    labelText: 'Caja (separar por comas)'),
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'URL de Imagen'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _createProduct,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
