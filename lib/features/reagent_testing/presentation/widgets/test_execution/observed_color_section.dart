import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:reagentkit/features/reagent_testing/domain/entities/reagent_entity.dart';

class ColorOption {
  final String englishName;
  final String arabicName;
  final Color displayColor;

  const ColorOption({
    required this.englishName,
    required this.arabicName,
    required this.displayColor,
  });
}

class ObservedColorSection extends ConsumerStatefulWidget {
  final ReagentEntity reagent;
  final Function(String?) onColorSelected;
  final String? selectedColor;

  const ObservedColorSection({
    super.key,
    required this.reagent,
    required this.onColorSelected,
    this.selectedColor,
  });

  @override
  ConsumerState<ObservedColorSection> createState() =>
      _ObservedColorSectionState();
}

class _ObservedColorSectionState extends ConsumerState<ObservedColorSection> {
  bool _isExpanded = false;

  // Get colors specific to the current reagent
  List<ColorOption> get _reagentColorOptions {
    final colorOptions = <ColorOption>[];
    final seenColors = <String>{};

    for (final drugResult in widget.reagent.drugResults) {
      // Only add unique colors (avoid duplicates)
      if (!seenColors.contains(drugResult.color)) {
        seenColors.add(drugResult.color);
        colorOptions.add(
          ColorOption(
            englishName: drugResult.color,
            arabicName: drugResult.colorAr,
            displayColor: _getDisplayColorForName(drugResult.color),
          ),
        );
      }
    }

    return colorOptions;
  }

  // Map color names to appropriate display colors
  Color _getDisplayColorForName(String colorName) {
    final lowerColor = colorName.toLowerCase();

    if (lowerColor.contains('black')) {
      return const Color(0xFF212121);
    }
    if (lowerColor.contains('blue') && lowerColor.contains('dark')) {
      return const Color(0xFF0D47A1);
    }
    if (lowerColor.contains('blue') && lowerColor.contains('bright')) {
      return const Color(0xFF03A9F4);
    }
    if (lowerColor.contains('blue')) {
      return const Color(0xFF2196F3);
    }
    if (lowerColor.contains('green') && lowerColor.contains('bright')) {
      return const Color(0xFF4CAF50);
    }
    if (lowerColor.contains('green')) {
      return const Color(0xFF66BB6A);
    }
    if (lowerColor.contains('red') && lowerColor.contains('dark')) {
      return const Color(0xFFD32F2F);
    }
    if (lowerColor.contains('red')) {
      return const Color(0xFFE57373);
    }
    if (lowerColor.contains('orange') && lowerColor.contains('light')) {
      return const Color(0xFFFFB74D);
    }
    if (lowerColor.contains('orange')) {
      return const Color(0xFFFF9800);
    }
    if (lowerColor.contains('yellow') && lowerColor.contains('light')) {
      return const Color(0xFFFFF176);
    }
    if (lowerColor.contains('yellow')) {
      return const Color(0xFFFFEB3B);
    }
    if (lowerColor.contains('purple')) {
      return const Color(0xFF9C27B0);
    }
    if (lowerColor.contains('pink')) {
      return const Color(0xFFF48FB1);
    }
    if (lowerColor.contains('brown')) {
      return const Color(0xFF8D6E63);
    }
    if (lowerColor.contains('none') ||
        lowerColor.contains('no change') ||
        lowerColor.contains('clear')) {
      return const Color(0xFFE0E0E0);
    }

    // Default color for unmatched colors
    return const Color(0xFF9E9E9E);
  }

  bool _isRtl(BuildContext context) {
    return Directionality.of(context) == TextDirection.rtl;
  }

  String _getColorName(ColorOption colorOption, BuildContext context) {
    return _isRtl(context) ? colorOption.arabicName : colorOption.englishName;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.indigo.shade50,
                Colors.blue.shade50,
                Colors.cyan.shade50,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.shade200.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        HeroIcons.swatch,
                        color: Colors.orange.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isRtl(context)
                                ? 'اللون المُلاحظ'
                                : 'Observed Color',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo.shade700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isRtl(context)
                                ? 'اختر اللون الذي لاحظته أثناء التفاعل'
                                : 'Select the color you observed during the reaction',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      icon: Icon(
                        _isExpanded
                            ? HeroIcons.chevron_up
                            : HeroIcons.chevron_down,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ],
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isRtl(context)
                              ? 'خيارات الألوان المتاحة:'
                              : 'Available Color Options:',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo.shade700,
                              ),
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 1,
                                childAspectRatio: 4.5,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: _reagentColorOptions.length,
                          itemBuilder: (context, index) {
                            final colorOption = _reagentColorOptions[index];
                            final colorName = _getColorName(
                              colorOption,
                              context,
                            );
                            final isSelected =
                                widget.selectedColor == colorOption.englishName;

                            return GestureDetector(
                              onTap: () {
                                widget.onColorSelected(colorOption.englishName);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.indigo.shade100
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.indigo.shade400
                                        : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? Colors.indigo.shade200.withOpacity(0.5)
                                          : Colors.grey.shade200.withOpacity(0.3),
                                      blurRadius: isSelected ? 8 : 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 8.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: colorOption.displayColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.grey.shade400,
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          colorName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontSize: 13,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                                color: isSelected
                                                    ? Colors.indigo.shade700
                                                    : Colors.grey.shade700,
                                                height: 1.3,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: _isRtl(context)
                                              ? TextAlign.right
                                              : TextAlign.left,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (isSelected)
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.indigo.shade600,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            HeroIcons.check,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                if (widget.selectedColor != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          HeroIcons.check_circle,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isRtl(context)
                                ? 'اللون المُلاحظ: ${_getSelectedColorName()}'
                                : 'Observed Color: ${_getSelectedColorName()}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSelectedColorName() {
    if (widget.selectedColor == null) return '';

    final selectedOption = _reagentColorOptions.firstWhere(
      (option) => option.englishName == widget.selectedColor,
      orElse: () => const ColorOption(
        englishName: '',
        arabicName: '',
        displayColor: Colors.grey,
      ),
    );

    return _getColorName(selectedOption, context);
  }
}
