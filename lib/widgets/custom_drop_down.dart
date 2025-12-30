import 'package:booksmart/constant/exports.dart';
import 'package:dropdown_search/dropdown_search.dart';

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
    this.onChanged, // Add this
  });

  final GlobalKey<DropdownSearchState<T>> dropDownKey;
  final String? label;
  final String? hint;
  final T? selectedItem;
  final List<T> items;
  final String Function(T)? itemAsString;
  final bool showSearchBox;
  final ValueChanged<T?>? onChanged; // Add this

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
      onChanged: widget.onChanged, // Add this
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          filled: true,
          fillColor: colors.surface,
          isDense: true,
          labelText: widget.label,
          hint: widget.hint == null ? null : FittedText(widget.hint!),
          
        ),
      ),
      // ... rest of your code
    );
  }
}
