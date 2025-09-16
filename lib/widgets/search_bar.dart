// search_bar.dart
import 'package:flutter/material.dart';

import 'search_bar_desktop.dart';

class SearchBar extends StatelessWidget implements PreferredSizeWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const SearchBar({
    Key? key,
    this.hintText = 'Buscar...',
    this.onChanged,
    this.onSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return isMobile
        // ? MobileSearchBar(
        ? SearchBarDesktop(
            hintText: hintText,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
          )
        : SearchBarDesktop(
            hintText: hintText,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
          );
  }

  @override
  Size get preferredSize => const Size.fromHeight(140);
}
