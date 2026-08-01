import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../providers/category_provider.dart';

class CategorySidebar extends StatelessWidget {
  final ValueChanged<CategoryModel>? onCategoryTap;

  const CategorySidebar({
    super.key,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CategoryProvider>(context);

    return Container(
      width: 230,
      constraints: const BoxConstraints(
        minHeight: 430,
        maxHeight: 430,
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF07111F).withOpacity(.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF1B3248),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF008CFF).withOpacity(.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _buildContent(context, provider),
    );
  }

  Widget _buildContent(BuildContext context, CategoryProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF168CFF),
        ),
      );
    }

    if (provider.error != null) {
      return const Center(
        child: Text(
          'No se pudieron cargar las categorías',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFB8C2D4),
            fontSize: 12,
          ),
        ),
      );
    }

    final categories = provider.categories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'CATEGORÍAS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: .5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(color: Color(0xFF253449), height: 1),
        const SizedBox(height: 4),

        Expanded(
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];

              return _CategoryItem(
                category: category,
                onTap: () => onCategoryTap?.call(category),
              );
            },
          ),
        ),

        const SizedBox(height: 4),
        _seeAllCategories(context),
      ],
    );
  }

  Widget _seeAllCategories(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/categories'),
      borderRadius: BorderRadius.circular(10),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Icon(
              Icons.apps_rounded,
              color: Color(0xFF168CFF),
              size: 17,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ver todas las categorías',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF168CFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem extends StatefulWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.category,
    required this.onTap,
  });

  @override
  State<_CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<_CategoryItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcon(widget.category.name);
    final label = _cleanCategoryName(widget.category.name);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 5.8, horizontal: 5),
          decoration: BoxDecoration(
            color: _hover ? const Color(0xFF10233B) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: const Border(
              bottom: BorderSide(
                color: Color(0xFF16283B),
                width: .45,
              ),
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: _hover ? const Color(0xFF168CFF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                icon,
                color: const Color(0xFF168CFF),
                size: 17,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _hover ? Colors.white : const Color(0xFFE8EDF5),
                    fontSize: 12,
                    fontWeight: _hover ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFB8C2D4),
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _categoryIcon(String name) {
  final value = name.toLowerCase();

  if (value.contains('robot') || value.contains('kid') || value.contains('kit')) {
    return Icons.smart_toy_outlined;
  }

  if (value.contains('impresion') || value.contains('3d')) {
    return Icons.view_in_ar_outlined;
  }

  if (value.contains('tarjeta') || value.contains('desarrollo')) {
    return Icons.developer_board_outlined;
  }

  if (value.contains('sensor') || value.contains('infrarrojo')) {
    return Icons.sensors_outlined;
  }

  if (value.contains('comunicacion') || value.contains('antena')) {
    return Icons.wifi_tethering_outlined;
  }

  if (value.contains('display') || value.contains('pantalla')) {
    return Icons.monitor_outlined;
  }

  if (value.contains('audio') || value.contains('amplificador')) {
    return Icons.speaker_outlined;
  }

  if (value.contains('automatizacion') || value.contains('domotica')) {
    return Icons.home_work_outlined;
  }

  if (value.contains('movimiento') || value.contains('mecanica')) {
    return Icons.settings_outlined;
  }

  return Icons.memory_outlined;
}

String _cleanCategoryName(String name) {
  final value = name.trim().toUpperCase();

  switch (value) {
    case 'AMPLIFICADORES DE AUDIO':
      return 'Audio';
    case 'ANTENAS':
      return 'Antenas';
    case 'AUTOMATIZACION Y DOMOTICA':
      return 'Domótica';
    case 'DISPLAYS Y PANTALLAS':
      return 'Displays';
    case 'IMPRESION 3D':
      return 'Impresión 3D';
    case 'MODULOS DE COMUNICACION':
      return 'Comunicación';
    case 'MOVIMIENTOS Y MECANICA':
      return 'Mecánica';
    case 'ROBOTS Y KIDS EDUCATIVOS':
      return 'Kits STEM';
    case 'SENSORES':
      return 'Sensores';
    case 'TARJETAS DE DESARROLLO':
      return 'Tarjetas';
    case 'INFRARROJO':
      return 'Infrarrojo';
    default:
      return name
          .trim()
          .toLowerCase()
          .split(' ')
          .where((word) => word.isNotEmpty)
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ');
  }
}