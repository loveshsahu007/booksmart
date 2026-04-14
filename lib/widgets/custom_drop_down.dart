import 'package:booksmart/constant/exports.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

class CustomDropDownWidget<T> extends StatefulWidget {
  const CustomDropDownWidget({
    super.key,
    required this.dropDownKey,
    required this.items,
    this.label,
    this.hint,
    this.selectedItem,
    this.itemAsString,
    this.showSearchBox = false,
    this.onChanged,
  });

  final GlobalKey<DropdownSearchState<T>> dropDownKey;
  final String? label;
  final String? hint;
  final T? selectedItem;
  final List<T> items;
  final String Function(T)? itemAsString;
  final bool showSearchBox;
  final ValueChanged<T?>? onChanged;

  @override
  State<CustomDropDownWidget<T>> createState() =>
      _CustomDropDownWidgetState<T>();
}

class _CustomDropDownWidgetState<T> extends State<CustomDropDownWidget<T>> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DropdownSearch<T>(
      key: widget.dropDownKey,
      selectedItem: widget.selectedItem,
      itemAsString: widget.itemAsString,
      items: (filter, infiniteScrollProps) => widget.items,
      onChanged: widget.onChanged,

      /// ✅ INPUT FIELD STYLE
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          filled: true,
          fillColor: colors.surface,
          isDense: true,
          labelText: widget.label,
          hintText: widget.hint,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),

      /// ✅ POPUP STYLE (Dark/Light Fix)
      popupProps: PopupProps.menu(
        showSearchBox: widget.showSearchBox,
        menuProps: MenuProps(
          backgroundColor: colors.surface,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        /// ✅ Search box styling
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.surfaceVariant,
            hintText: "Search...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),

        /// ✅ FIXED itemBuilder signature
        itemBuilder: (context, item, isDisabled, isSelected) {
          final text = widget.itemAsString?.call(item) ?? item.toString();
          // Determine divider color based on theme brightness
          final bool isDarkMode = theme.brightness == Brightness.dark;
          final Color dividerColor = isDarkMode
              ? Colors.white.withOpacity(0.1) // Subtle white for dark mode
              : Colors.grey.shade300;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: isSelected
                    ? colors.primary.withOpacity(0.08)
                    : colors.surface,
                child: Text(
                  text,
                  // style: theme.textTheme.bodyMedium?.copyWith(
                  //   color: isDisabled
                  //       ? colors.onSurface.withOpacity(0.4)
                  //       : colors.onSurface,
                  // ),
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: dividerColor,
                indent: 12,
                endIndent: 12,
              ),
            ],
          );
        },
      ),
    );
  }
}
