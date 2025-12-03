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
  });

  final GlobalKey<DropdownSearchState<T>> dropDownKey;
  final String? label;
  final String? hint;
  final List<T> selectedItems;
  final List<T> items;
  final String Function(T)? itemAsString;
  final bool showSearchBox;

  @override
  State<CustomMultiDropDownWidget<T>> createState() =>
      _CustomMultiDropDownWidgetState<T>();
}

class _CustomMultiDropDownWidgetState<T>
    extends State<CustomMultiDropDownWidget<T>> {
  @override
  Widget build(BuildContext context) {
    return DropdownSearch<T>.multiSelection(
      key: widget.dropDownKey,
      selectedItems: [],
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
      popupProps: PopupPropsMultiSelection.menu(
        fit: FlexFit.loose,
        showSearchBox: widget.showSearchBox,
        showSelectedItems: true,
        searchDelay: Duration(milliseconds: 100),
        searchFieldProps: TextFieldProps(
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
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              item.toString(),
              style: TextStyle(
                color: () {
                  if (isDisabled) {
                    return Colors.grey;
                  } else if (isSelected) {
                    return Get.theme.primaryColor;
                  }
                }(),
              ),
            ),
          );
        },
      ),

      dropdownBuilder: (context, selectedItems) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Wrap(
            spacing: 5,
            runSpacing: 7,
            children: selectedItems.map((item) {
              return Material(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                color: Get.theme.scaffoldBackgroundColor,
                child: InkWell(
                  onTap: () {
                    widget.dropDownKey.currentState?.removeItem(item);
                  },
                  borderRadius: BorderRadius.circular(5),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 3,
                    ),
                    child: Row(
                      spacing: 4,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(item.toString(), fontSize: 13),

                        Icon(Icons.cancel, size: 10),
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
