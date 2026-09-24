//#TEMPLATE reuseable_date_picker
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core.dart';

class QDatePicker extends StatefulWidget {
  const QDatePicker({
    required this.label,
    required this.onChanged,
    super.key,
    this.value,
    this.validator,
    this.hint,
    this.helper,
  });
  final String label;
  final DateTime? value;
  final String? hint;
  final String? helper;

  final String? Function(String?)? validator;
  final Function(DateTime) onChanged;

  @override
  State<QDatePicker> createState() => _QDatePickerState();
}

class _QDatePickerState extends State<QDatePicker> {
  DateTime? selectedValue;
  late TextEditingController controller;
  @override
  void initState() {
    super.initState();
    selectedValue = widget.value;
    controller = TextEditingController(text: getInitialValue());
  }

  String getInitialValue() {
    if (widget.value != null) {
      return DateFormat('d MMM y').format(widget.value!);
    }
    return '-';
  }

  String getFormattedValue() {
    if (selectedValue != null) {
      return DateFormat('d MMM y').format(selectedValue!);
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: widget.value ?? now,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        selectedValue = pickedDate;
        controller.text = getFormattedValue();
        setState(() {});

        if (selectedValue == null) return;
        widget.onChanged(selectedValue!);
      },
      child: AbsorbPointer(
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: controller,
            style: TextStyle(color: textColor),
            validator: (value) {
              if (widget.validator != null) {
                return widget.validator!(selectedValue.toString());
              }
              return null;
            },
            readOnly: true,
            decoration: InputDecoration(
              labelText: widget.label,
              labelStyle: TextStyle(color: secondaryTextColor),
              suffixIcon: Icon(Icons.date_range, color: secondaryTextColor),
              helperText: widget.helper,
              hintText: widget.hint,
              fillColor: inputColor,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: disabledColor),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: primaryColor),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: dangerColor),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//#END
