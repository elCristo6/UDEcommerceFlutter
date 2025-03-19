import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/product_provider.dart';

class ProductEditModal extends StatefulWidget {
  final Product product;
  final Function(Product updatedProduct) onSave;

  const ProductEditModal({
    Key? key,
    required this.product,
    required this.onSave,
  }) : super(key: key);

  @override
  _ProductEditModalState createState() => _ProductEditModalState();
}

class _ProductEditModalState extends State<ProductEditModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _stockController;
  late TextEditingController _categoryController;
  late TextEditingController _boxController;
  late TextEditingController _imageUrlController;
  late TextEditingController _passwordController;

  String _passwordError = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController =
        TextEditingController(text: widget.product.price.toString());
    _descriptionController =
        TextEditingController(text: widget.product.description);
    _stockController =
        TextEditingController(text: widget.product.stock.toString());
    _categoryController = TextEditingController(text: widget.product.category);
    _boxController = TextEditingController(text: widget.product.box.join(', '));
    _imageUrlController = TextEditingController(text: widget.product.imageUrl);
    _passwordController = TextEditingController();
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
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    // Verificamos la contraseña (en este ejemplo, se requiere que la contraseña sea "6038")
    if (_passwordController.text != '6038') {
      setState(() => _passwordError = 'Contraseña incorrecta');
      return;
    }
    setState(() => _passwordError = '');

    // Construir el objeto actualizado usando copyWith; si el campo está vacío, se usa el valor original.
    final updatedProduct = widget.product.copyWith(
      name: _nameController.text.isNotEmpty
          ? _nameController.text
          : widget.product.name,
      price: _priceController.text.isNotEmpty
          ? double.tryParse(_priceController.text) ?? widget.product.price
          : widget.product.price,
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : widget.product.description,
      stock: _stockController.text.isNotEmpty
          ? int.tryParse(_stockController.text) ?? widget.product.stock
          : widget.product.stock,
      category: _categoryController.text.isNotEmpty
          ? _categoryController.text
          : widget.product.category,
      box: _boxController.text.isNotEmpty
          ? _boxController.text
              .split(',')
              .map((s) => int.tryParse(s.trim()) ?? 0)
              .toList()
          : widget.product.box,
      imageUrl: _imageUrlController.text.isNotEmpty
          ? _imageUrlController.text
          : widget.product.imageUrl,
    );

    try {
      // Llamamos al Provider para actualizar el producto
      await Provider.of<ProductProvider>(context, listen: false)
          .updateProduct(updatedProduct);

      // (Opcional) Puedes refrescar la lista de productos si lo consideras necesario:
      // await Provider.of<ProductProvider>(context, listen: false)
      //     .fetchProducts(forceUpdate: true);

      // Avisamos al widget padre que se ha actualizado el producto y cerramos el modal.
      widget.onSave(updatedProduct);
      Navigator.of(context).pop();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Producto'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          // No se incluyen validadores obligatorios para permitir campos vacíos.
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
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
              ),
              if (_passwordError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _passwordError,
                    style: const TextStyle(color: Colors.red),
                  ),
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
          onPressed: _updateProduct,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
