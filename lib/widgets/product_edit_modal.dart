
/*import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../models/category_model.dart';
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
  late TextEditingController _nameController,
      _priceController,
      _descriptionController,
      _stockController,
      _boxController,
      _passwordController;
  bool _isUploading = false;
  String _passwordError = '';
List<String> _selectedCategoryIds = [];
  // Cargamos al initState las URLs existentes
  List<String> _existingImages = [];
  List<Uint8List> _pickedImages = [];

  @override
  void initState() {
    super.initState();
    _existingImages = List.from(widget.product.images);
    _nameController = TextEditingController(text: widget.product.name);
    _priceController =
        TextEditingController(text: widget.product.price.toString());
    _descriptionController =
        TextEditingController(text: widget.product.description);
    _stockController =
        TextEditingController(text: widget.product.stock.toString());
        _selectedCategoryIds = List<String>.from(widget.product.categories);

WidgetsBinding.instance.addPostFrameCallback((_) {

  final provider =
      Provider.of<CategoryProvider>(context, listen: false);

  if (provider.categories.isEmpty) {
    provider.fetchCategories().then((_) {
      _resolveSelectedCategories(provider);
    });
  } else {
    _resolveSelectedCategories(provider);
  }

});

    _boxController = TextEditingController(text: widget.product.box.join(', '));
    _passwordController = TextEditingController();
  }

void _resolveSelectedCategories(CategoryProvider provider) {
  final selected = <String>{};

  selected.addAll(widget.product.categories);

  final legacyCategory = widget.product.category.toLowerCase().trim();

  for (final category in provider.categories) {
    if (category.id == widget.product.category ||
        category.name.toLowerCase().trim() == legacyCategory) {
      selected.add(category.id);
    }
  }

  if (mounted) {
    setState(() {
      _selectedCategoryIds = selected.where((id) => id.isNotEmpty).toList();
    });
  }
}
  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _boxController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final slotsLeft = 5 - (_existingImages.length + _pickedImages.length);
    if (slotsLeft <= 0) return;
    final result = await FilePicker.platform
        .pickFiles(allowMultiple: true, type: FileType.image, withData: true);
    if (result != null) {
      setState(() {
        final incoming = result.files
            .where((f) => f.bytes != null)
            .map((f) => f.bytes!)
            .toList();
        _pickedImages.addAll(incoming.take(slotsLeft));
      });
    }
  }

  Widget _deleteIcon() => Container(
        decoration:
            BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
        padding: const EdgeInsets.all(2),
        child: const Icon(Icons.close, size: 16, color: Colors.white),
      );

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
  return;
}
    if (_passwordController.text != '6038') {
      setState(() => _passwordError = 'Contraseña incorrecta');
      return;
    }
    setState(() {
      _passwordError = '';
      _isUploading = true;
    });
final categoryProvider =
    Provider.of<CategoryProvider>(context, listen: false);
    final updated = widget.product.copyWith(
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
      category: _selectedCategoryIds.isNotEmpty
    ? categoryProvider.categories
        .firstWhere((c) => c.id == _selectedCategoryIds.first)
        .name
    : widget.product.category,
categories: _selectedCategoryIds,
      box: _boxController.text.isNotEmpty
          ? _boxController.text
              .split(',')
              .map((s) => int.tryParse(s.trim()) ?? 0)
              .toList()
          : widget.product.box,
    );

    final provider = Provider.of<ProductProvider>(context, listen: false);
    try {
      // 1) Actualiza datos básicos
      await provider.updateProduct(updated);
    final savedProduct = await provider.updateProduct(
  updated,
  newImages: _pickedImages,
);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto actualizado con éxito')),
      );
     widget.onSave(savedProduct);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context, listen: false);

    return AlertDialog(
      title: const Text('Editar Producto'),
      content: SizedBox(
        width: 350,
        height: 520,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_isUploading) const LinearProgressIndicator(),
              // — Campos —
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
                maxLines: 2,
              ),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
              ),
              Consumer<CategoryProvider>(
                  builder: (context, categoryProvider, child) {
                    if (categoryProvider.isLoading) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      );
                    }

                    if (categoryProvider.error != null) {
                      return Text(
                        'Error cargando categorías: ${categoryProvider.error}',
                        style: const TextStyle(color: Colors.red),
                      );
                    }

                    return FormField<List<String>>(
  initialValue: _selectedCategoryIds,
  validator: (_) {
    if (_selectedCategoryIds.isEmpty) {
      return 'Selecciona al menos una categoría';
    }
    return null;
  },
  builder: (field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            'Categorías',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        Container(
          constraints: const BoxConstraints(maxHeight: 130),
          decoration: BoxDecoration(
            border: Border.all(
              color: field.hasError ? Colors.red : Colors.grey.shade400,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: categoryProvider.categories.map((category) {
                final isSelected = _selectedCategoryIds.contains(category.id);

                return CheckboxListTile(
                  dense: true,
                  value: isSelected,
                  title: Text(category.name),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: _isUploading
                      ? null
                      : (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedCategoryIds.add(category.id);
                            } else {
                              _selectedCategoryIds.remove(category.id);
                            }

                            field.didChange(_selectedCategoryIds);
                          });
                        },
                );
              }).toList(),
            ),
          ),
        ),
        if (field.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 12),
            child: Text(
              field.errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  },
);
                  },
                ),
              TextFormField(
                controller: _boxController,
                decoration: const InputDecoration(
                    labelText: 'Caja (separar por comas)'),
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
              ),
              if (_passwordError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_passwordError,
                      style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: (_existingImages.length + _pickedImages.length) < 5
                    ? _pickImages
                    : null,
                icon: const Icon(Icons.photo_library),
                label: const Text('Añadir imágenes'),
              ),
              const SizedBox(height: 12),
              // — Miniaturas en Wrap —
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Slots para URLs existentes
                      for (int i = 0; i < _existingImages.length; i++)
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                _existingImages[i],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image, size: 60),
                              ),
                            ),
                            Positioned(
                              top: -6,
                              right: -6,
                              child: GestureDetector(
                                onTap: () async {
                                  try {
                                    // Llama a tu provider para eliminar del servidor
                                    await provider.deleteProductImage(
                                        widget.product.id, _existingImages[i]);
                                    setState(() {
                                      _existingImages.removeAt(i);
                                    });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e')));
                                  }
                                },
                                child: _deleteIcon(),
                              ),
                            ),
                          ],
                        ),
                      // Slots para nuevas imágenes elegidas
                      for (int j = 0; j < _pickedImages.length; j++)
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.memory(
                                _pickedImages[j],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: -6,
                              right: -6,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _pickedImages.removeAt(j);
                                  });
                                },
                                child: _deleteIcon(),
                              ),
                            ),
                          ],
                        ),
                      // Placeholders para completar 5 slots
                      ...List.generate(
                        5 - (_existingImages.length + _pickedImages.length),
                        (_) => Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.image,
                              size: 40, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _updateProduct,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
*/

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';

class ProductEditModal extends StatefulWidget {
  final Product product;
  final ValueChanged<Product> onSave;

  const ProductEditModal({
    super.key,
    required this.product,
    required this.onSave,
  });

  @override
  State<ProductEditModal> createState() =>
      _ProductEditModalState();
}

class _ProductEditModalState extends State<ProductEditModal> {
  static const int _maxImages = 5;

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _stockController;
  late final TextEditingController _boxController;
  late final TextEditingController _passwordController;

  bool _isUploading = false;
  bool _isDeletingImage = false;

  String _passwordError = '';

  List<String> _selectedCategoryIds = [];
  List<String> _existingImages = [];
  List<Uint8List> _pickedImages = [];

  int get _totalImages =>
      _existingImages.length + _pickedImages.length;

  @override
  void initState() {
    super.initState();

    _existingImages =
        List<String>.from(widget.product.images);

    _selectedCategoryIds =
        List<String>.from(widget.product.categories);

    _nameController =
        TextEditingController(text: widget.product.name);

    _priceController = TextEditingController(
      text: widget.product.price.toString(),
    );

    _descriptionController = TextEditingController(
      text: widget.product.description,
    );

    _stockController = TextEditingController(
      text: widget.product.stock.toString(),
    );

    _boxController = TextEditingController(
      text: widget.product.box.join(', '),
    );

    _passwordController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final categoryProvider =
          context.read<CategoryProvider>();

      if (categoryProvider.categories.isEmpty) {
        await categoryProvider.fetchCategories();
      }

      if (!mounted) return;

      _resolveSelectedCategories(categoryProvider);
    });
  }

  void _resolveSelectedCategories(
    CategoryProvider provider,
  ) {
    final selectedIds = <String>{
      ...widget.product.categories,
    };

    final legacyCategory =
        widget.product.category.trim().toLowerCase();

    for (final category in provider.categories) {
      final categoryName =
          category.name.trim().toLowerCase();

      if (category.id == widget.product.category ||
          categoryName == legacyCategory) {
        selectedIds.add(category.id);
      }
    }

    if (!mounted) return;

    setState(() {
      _selectedCategoryIds = selectedIds
          .where((id) => id.trim().isNotEmpty)
          .toList();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _stockController.dispose();
    _boxController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final slotsLeft = _maxImages - _totalImages;

    if (slotsLeft <= 0) {
      _showMessage(
        'Solo puedes tener un máximo de $_maxImages imágenes.',
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true,
    );

    if (result == null || !mounted) return;

    final incomingImages = result.files
        .where((file) => file.bytes != null)
        .map((file) => file.bytes!)
        .take(slotsLeft)
        .toList();

    setState(() {
      _pickedImages.addAll(incomingImages);
    });
  }

  Future<void> _deleteExistingImage(
    String imageUrl,
  ) async {
    if (_isUploading || _isDeletingImage) return;

    setState(() {
      _isDeletingImage = true;
    });

    try {
      await context
          .read<ProductProvider>()
          .deleteProductImage(
            widget.product.id,
            imageUrl,
          );

      if (!mounted) return;

      setState(() {
        _existingImages.remove(imageUrl);
      });

      _showMessage('Imagen eliminada.');
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'No fue posible eliminar la imagen: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingImage = false;
        });
      }
    }
  }

  List<int> _parseBoxValues() {
    return _boxController.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .map(int.tryParse)
        .whereType<int>()
        .toList();
  }

  Future<void> _updateProduct() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != '6038') {
      setState(() {
        _passwordError = 'Contraseña incorrecta';
      });
      return;
    }

    final categoryProvider =
        context.read<CategoryProvider>();

    String legacyCategory =
        widget.product.category;

    if (_selectedCategoryIds.isNotEmpty) {
      final matches = categoryProvider.categories.where(
        (category) =>
            category.id == _selectedCategoryIds.first,
      );

      if (matches.isNotEmpty) {
        legacyCategory = matches.first.name;
      }
    }

    final updatedProduct = widget.product.copyWith(
      name: _nameController.text.trim(),
      price: double.tryParse(
            _priceController.text
                .trim()
                .replaceAll(',', '.'),
          ) ??
          widget.product.price,
      description:
          _descriptionController.text.trim(),
      stock: int.tryParse(
            _stockController.text.trim(),
          ) ??
          widget.product.stock,
      box: _parseBoxValues(),
      category: legacyCategory,
      categories:
          List<String>.from(_selectedCategoryIds),
    );

    setState(() {
      _passwordError = '';
      _isUploading = true;
    });

    try {
      final savedProduct =
          await context.read<ProductProvider>().updateProduct(
                updatedProduct,
                newImages: _pickedImages,
              );

      if (!mounted) return;

      widget.onSave(savedProduct);

      _showMessage(
        'Producto actualizado con éxito.',
      );

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Error al actualizar el producto: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade700 : null,
      ),
    );
  }

  Widget _buildDeleteIcon() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        color: Colors.black87,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.close,
        size: 15,
        color: Colors.white,
      ),
    );
  }

  Widget _buildExistingImage(
    String imageUrl,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (
                context,
                child,
                loadingProgress,
              ) {
                if (loadingProgress == null) {
                  return child;
                }

                return const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) {
                return const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 35,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: -7,
          right: -7,
          child: InkWell(
            onTap: _isDeletingImage
                ? null
                : () => _deleteExistingImage(
                      imageUrl,
                    ),
            child: _buildDeleteIcon(),
          ),
        ),
        Positioned(
          left: 4,
          bottom: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Actual',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickedImage(
    int index,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Colors.deepPurple.shade200,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.memory(
              _pickedImages[index],
              fit: BoxFit.contain,
            ),
          ),
        ),
        Positioned(
          top: -7,
          right: -7,
          child: InkWell(
            onTap: _isUploading
                ? null
                : () {
                    setState(() {
                      _pickedImages.removeAt(index);
                    });
                  },
            child: _buildDeleteIcon(),
          ),
        ),
        Positioned(
          left: 4,
          bottom: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(
                alpha: 0.85,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Nueva',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyImageSlot() {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.add_photo_alternate_outlined,
        size: 30,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildImageSection() {
    final emptySlots =
        (_maxImages - _totalImages).clamp(0, _maxImages);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Imágenes del producto',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$_totalImages/$_maxImages',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final imageUrl in _existingImages)
              _buildExistingImage(imageUrl),
            for (int index = 0;
                index < _pickedImages.length;
                index++)
              _buildPickedImage(index),
            for (int index = 0;
                index < emptySlots;
                index++)
              _buildEmptyImageSlot(),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _isUploading ||
                  _isDeletingImage ||
                  _totalImages >= _maxImages
              ? null
              : _pickImages,
          icon: const Icon(
            Icons.photo_library_outlined,
          ),
          label: const Text(
            'Seleccionar imágenes',
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesField(
    CategoryProvider categoryProvider,
  ) {
    if (categoryProvider.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: LinearProgressIndicator(),
      );
    }

    if (categoryProvider.error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Error cargando categorías: '
            '${categoryProvider.error}',
            style: const TextStyle(
              color: Colors.red,
            ),
          ),
          TextButton.icon(
            onPressed: categoryProvider.fetchCategories,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    return FormField<List<String>>(
      validator: (_) {
        if (_selectedCategoryIds.isEmpty) {
          return 'Selecciona al menos una categoría';
        }

        return null;
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Categorías',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(
                maxHeight: 170,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: field.hasError
                      ? Colors.red
                      : Colors.grey.shade400,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount:
                    categoryProvider.categories.length,
                itemBuilder: (context, index) {
                  final CategoryModel category =
                      categoryProvider.categories[index];

                  final selected =
                      _selectedCategoryIds.contains(
                    category.id,
                  );

                  return CheckboxListTile(
                    dense: true,
                    value: selected,
                    title: Text(category.name),
                    controlAffinity:
                        ListTileControlAffinity.leading,
                    onChanged: _isUploading
                        ? null
                        : (checked) {
                            setState(() {
                              if (checked == true) {
                                if (!_selectedCategoryIds
                                    .contains(category.id)) {
                                  _selectedCategoryIds.add(
                                    category.id,
                                  );
                                }
                              } else {
                                _selectedCategoryIds.remove(
                                  category.id,
                                );
                              }
                            });

                            field.didChange(
                              List<String>.from(
                                _selectedCategoryIds,
                              ),
                            );
                          },
                  );
                },
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(
                  top: 6,
                  left: 12,
                ),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider =
        context.watch<CategoryProvider>();

    return AlertDialog(
      title: const Text('Editar producto'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isUploading)
                  const Padding(
                    padding: EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: LinearProgressIndicator(),
                  ),
                TextFormField(
                  controller: _nameController,
                  enabled: !_isUploading,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Ingresa el nombre';
                    }

                    return null;
                  },
                ),
                TextFormField(
                  controller: _priceController,
                  enabled: !_isUploading,
                  decoration: const InputDecoration(
                    labelText: 'Precio',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final price = double.tryParse(
                      (value ?? '')
                          .trim()
                          .replaceAll(',', '.'),
                    );

                    if (price == null || price < 0) {
                      return 'Ingresa un precio válido';
                    }

                    return null;
                  },
                ),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_isUploading,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                  ),
                  maxLines: 3,
                ),
                TextFormField(
                  controller: _stockController,
                  enabled: !_isUploading,
                  decoration: const InputDecoration(
                    labelText: 'Stock',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final stock = int.tryParse(
                      (value ?? '').trim(),
                    );

                    if (stock == null || stock < 0) {
                      return 'Ingresa un stock válido';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildCategoriesField(
                  categoryProvider,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _boxController,
                  enabled: !_isUploading,
                  decoration: const InputDecoration(
                    labelText:
                        'Caja (valores separados por comas)',
                  ),
                ),
                const SizedBox(height: 16),
                _buildImageSection(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  enabled: !_isUploading,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                  ),
                  obscureText: true,
                  onChanged: (_) {
                    if (_passwordError.isNotEmpty) {
                      setState(() {
                        _passwordError = '';
                      });
                    }
                  },
                ),
                if (_passwordError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 8,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _passwordError,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed:
              _isUploading ? null : _updateProduct,
          child: Text(
            _isUploading ? 'Guardando...' : 'Guardar',
          ),
        ),
      ],
    );
  }
}