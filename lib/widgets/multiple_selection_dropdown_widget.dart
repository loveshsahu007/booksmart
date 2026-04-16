import 'package:booksmart/widgets/app_text.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constant/app_colors.dart';

class CustomMultiDropDownWidget<T> extends StatefulWidget {
  const CustomMultiDropDownWidget({
    super.key,
    required this.dropDownKey,
    required this.items,
    this.label,
    this.hint,
    this.selectedItems = const [],
    this.itemAsString,
    this.showSearchBox = false,
    this.onChanged,
  });

  final GlobalKey<DropdownSearchState<T>> dropDownKey;
  final String? label;
  final String? hint;
  final List<T> selectedItems;
  final List<T> items;
  final String Function(T)? itemAsString;
  final bool showSearchBox;
  final ValueChanged<List<T>>? onChanged;

  @override
  State<CustomMultiDropDownWidget<T>> createState() =>
      _CustomMultiDropDownWidgetState<T>();
}

class _CustomMultiDropDownWidgetState<T>
    extends State<CustomMultiDropDownWidget<T>> {
  late List<T> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List<T>.from(widget.selectedItems);
  }

  @override
  void didUpdateWidget(covariant CustomMultiDropDownWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If parent provides a different selectedItems list, sync it
    if (oldWidget.selectedItems != widget.selectedItems) {
      _selectedItems = List<T>.from(widget.selectedItems);
    }
  }

  void _notifyParent() {
    if (widget.onChanged != null) {
      widget.onChanged!(List<T>.from(_selectedItems));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<T>.multiSelection(
      key: widget.dropDownKey,
      selectedItems: _selectedItems,
      itemAsString: widget.itemAsString,
      items: (filter, infiniteScrollProps) => widget.items,
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          hintText: widget.hint,
          labelText: widget.label,
          isDense: false,
        ),
      ),
      suffixProps: DropdownSuffixProps(
        dropdownButtonProps: DropdownButtonProps(
          padding: EdgeInsetsGeometry.zero,
        ),
      ),

      // When dropdown_search notifies of changes, update internal list and propagate
      onChanged: (List<T> selected) {
        setState(() {
          _selectedItems = List<T>.from(selected);
        });
        _notifyParent();
      },

      popupProps: PopupPropsMultiSelection.menu(
        fit: FlexFit.loose,
        showSearchBox: widget.showSearchBox,
        showSelectedItems: true,
        searchDelay: const Duration(milliseconds: 100),
        searchFieldProps: const TextFieldProps(
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Search here ...",
          ),
        ),
        menuProps: MenuProps(
          backgroundColor: Get.isDarkMode
              ? AppColorsDark.surface
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        itemBuilder: (context, item, isDisabled, isSelected) {
          final text = widget.itemAsString?.call(item) ?? item.toString();
          Color? textColor;
          if (isDisabled) {
            textColor = Colors.grey;
          } else if (isSelected) {
            textColor = Get.theme.primaryColor;
          }
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(text, style: TextStyle(color: textColor)),
          );
        },
      ),

      // Build the selected items display using internal _selectedItems
      dropdownBuilder: (context, selected) {
        // `selected` is provided by the package too, but we prefer our internal source-of-truth.
        final chips = _selectedItems;
        return Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Wrap(
            spacing: 5,
            runSpacing: 7,
            children: chips.map((item) {
              final label = widget.itemAsString?.call(item) ?? item.toString();
              return Material(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                color: Get.theme.scaffoldBackgroundColor,
                child: InkWell(
                  onTap: () {
                    // remove item from DropdownSearch internal selection
                    widget.dropDownKey.currentState?.removeItem(item);
                    // also update our internal copy and notify parent
                    setState(() {
                      _selectedItems.remove(item);
                    });
                    _notifyParent();
                  },
                  borderRadius: BorderRadius.circular(5),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 3,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(label, fontSize: 13),
                        const SizedBox(width: 4),
                        const Icon(Icons.cancel, size: 10),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
