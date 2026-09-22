//#TEMPLATE reuseable_dropdown_field
/*
TODO:
default value masih belum benar
Conntoh value +61213213123
Harus dipisah ke variabel code dan value
*/
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:get/get.dart';
import '../../../../core.dart';

class QDropdownField extends StatefulWidget {
  const QDropdownField({
    required this.label,
    required this.items,
    required this.onChanged,
    super.key,
    this.value,
    this.validator,
    this.emptyMode = true,
    this.hint,
    this.helper,
    this.margin,
  });
  final String label;
  final String? hint;
  final String? helper;
  final List<Map<String, dynamic>> items;
  final String? Function(Map<String, dynamic>? value)? validator;
  final dynamic value;
  final bool emptyMode;
  final Function(dynamic value, String? label) onChanged;
  final EdgeInsetsGeometry? margin;

  @override
  State<QDropdownField> createState() => _QDropdownFieldState();
}

class _QDropdownFieldState extends State<QDropdownField> {
  List<Map<String, dynamic>> items = [];
  Map<String, dynamic>? selectedValue;
  @override
  void initState() {
    super.initState();

    items = [];
    for (final item in widget.items) {
      items.add(item);
    }

    final values = widget.items
        .where((i) => i['value'] == widget.value)
        .toList();
    if (values.isNotEmpty) {
      selectedValue = values.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin ?? const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField2<Map<String, dynamic>>(
        isExpanded: true,
        decoration: InputDecoration(
          labelText: widget.label,
          helperText: widget.helper,
          hintText: widget.hint,
          fillColor: Colors.white,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 0,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryColor),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryColor),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: dangerColor),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryColor),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          suffixIcon: selectedValue != null
              ? IconButton(
                  onPressed: () {
                    selectedValue = null;
                    setState(() {});
                    widget.onChanged(null, null);
                  },
                  icon: const Icon(Icons.close, color: Colors.grey),
                )
              : null,
        ),
        hint: widget.hint != null
            ? Text(widget.hint!, style: TextStyle(fontSize: 14))
            : null,
        items: items
            .map(
              (item) => DropdownMenuItem<Map<String, dynamic>>(
                value: item,
                enabled: item['disabled'] != true,
                child: Text(
                  item['label'],
                  style: TextStyle(
                    fontSize: 14,
                    color: item['disabled'] == true ? Colors.grey : null,
                  ),
                ),
              ),
            )
            .toList(),
        validator: (value) {
          if (widget.validator != null) {
            return widget.validator!(value);
          }
          return null;
        },
        onChanged: (value) {
          // Check if the selected item is disabled
          if (value != null && value['disabled'] == true) {
            // Don't update selection, show error
            Get.snackbar(
              "Error",
              "Wallet dengan balance 0 tidak bisa dipilih",
              snackPosition: SnackPosition.BOTTOM,
            );
            return;
          }

          selectedValue = value;
          setState(() {});

          if (value != null) {
            final label = selectedValue!['label'];
            final val = selectedValue!['value'];
            widget.onChanged(val, label);
          } else {
            widget.onChanged(null, null);
          }
        },
        onSaved: (value) {
          selectedValue = value;
        },
        buttonStyleData: const ButtonStyleData(
          padding: EdgeInsets.only(right: 8),
        ),
        iconStyleData: const IconStyleData(
          icon: Icon(Icons.arrow_drop_down, color: Colors.black45),
          iconSize: 24,
        ),
        dropdownStyleData: DropdownStyleData(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
        ),
        menuItemStyleData: const MenuItemStyleData(
          padding: EdgeInsets.symmetric(horizontal: 16),
        ),
        value: selectedValue,
      ),
    );
  }
}

//#END
