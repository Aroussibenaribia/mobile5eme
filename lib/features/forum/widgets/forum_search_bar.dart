import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ForumSearchBar extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterTap;
  final String activeSort;
  final String activeStatus;

  const ForumSearchBar({
    super.key,
    required this.onSearchChanged,
    required this.onFilterTap,
    this.activeSort = 'newest',
    this.activeStatus = 'all',
  });

  @override
  State<ForumSearchBar> createState() => _ForumSearchBarState();
}

class _ForumSearchBarState extends State<ForumSearchBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  void _onChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearchChanged(query);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasActiveFilter = widget.activeStatus != 'all' || widget.activeSort != 'newest';

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Rechercher une panne, astuce, matériel...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                        onPressed: () {
                          _controller.clear();
                          widget.onSearchChanged('');
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: widget.onFilterTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: hasActiveFilter ? AppColors.primaryLight : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasActiveFilter ? AppColors.primary : AppColors.cardBorder,
                width: hasActiveFilter ? 1.5 : 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: hasActiveFilter ? AppColors.primaryDark : AppColors.secondary,
                  size: 22,
                ),
                if (hasActiveFilter)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
