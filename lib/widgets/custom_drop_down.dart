import 'package:booksmart/constant/exports.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:get/get.dart';

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
  });

  final GlobalKey<DropdownSearchState<T>> dropDownKey;
  final String? label;
  final String? hint;
  final T? selectedItem;
  final List<T> items;
  final String Function(T)? itemAsString;
  final bool showSearchBox;

  @override
  State<CustomDropDownWidget<T>> createState() =>
      _CustomDropDownWidgetState<T>();
}

class _CustomDropDownWidgetState<T> extends State<CustomDropDownWidget<T>> {
  @override
  Widget build(BuildContext context) {
    return DropdownSearch<T>(
      key: widget.dropDownKey,
      selectedItem: widget.selectedItem,
      itemAsString: widget.itemAsString,
      items: (filter, infiniteScrollProps) => widget.items,
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: widget.label,
          hint: widget.hint == null ? null : FittedText(widget.hint!),
          isDense: true,
        ),
      ),
      popupProps: PopupProps.menu(
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
            decoration: BoxDecoration(
              color: () {
                if (isDisabled) {
                  return Colors.grey;
                } else if (isSelected) {
                  return Get.theme.primaryColor;
                }
              }(),
            ),
            child: Text(item.toString(), style: TextStyle()),
          );
        },
      ),
      validator: (value) => value == null ? 'Required' : null,
    );
  }
}
