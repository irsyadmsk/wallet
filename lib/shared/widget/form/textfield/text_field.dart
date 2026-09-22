//#TEMPLATE reuseable_text_field
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core.dart';

class QTextField extends StatefulWidget {
  const QTextField({
    required this.label,
    required this.onChanged,
    super.key,
    this.id,
    this.value,
    this.validator,
    this.hint,
    this.helper,
    this.maxLength,
    this.maxLines,
    this.onSubmitted,
    this.obscure = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
    this.horizontal,
    this.isNumberOnly,
    this.vertical,
    this.controller,
    this.isPhoneNumber,
  });
  final String? id;
  final String label;
  final bool? isNumberOnly;
  final bool? isPhoneNumber;
  final String? value;
  final String? hint;
  final String? helper;
  final String? Function(String?)? validator;
  final bool obscure;
  final bool enabled;
  final int? maxLength;
  final int? maxLines;
  final double? horizontal;
  final double? vertical;

  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Function(String) onChanged;
  final Function(String)? onSubmitted;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  @override
  State<QTextField> createState() => _QTextFieldState();
}

class _QTextFieldState extends State<QTextField> {
  late TextEditingController textEditingController;
  bool visible = false;

  @override
  void initState() {
    focusNode = widget.focusNode ?? FocusNode();
    textEditingController = widget.controller ?? TextEditingController();
    textEditingController.text = widget.value ?? '';
    super.initState();
  }

  @override
  void didUpdateWidget(QTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != null && widget.value != textEditingController.text) {
      textEditingController.text = widget.value!;
    }
  }

  String getValue() {
    return textEditingController.text;
  }

  setValue(value) {
    textEditingController.text = value;
  }

  resetValue() {
    textEditingController.text = '';
  }

  focus() {
    focusNode.requestFocus();
  }

  late FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    Widget icon = Icon(widget.suffixIcon ?? null);

    if (widget.obscure) {
      if (visible) {
        icon = InkWell(
          onTap: () {
            visible = false;
            setState(() {});
          },
          child: icon = const Icon(
            Icons.visibility_off_outlined,
            color: Colors.black,
          ),
        );
      } else {
        icon = InkWell(
          onTap: () {
            visible = true;
            setState(() {});
          },
          child: icon = const Icon(
            Icons.visibility_outlined,
            color: Colors.black,
          ),
        );
      }
    }
    bool isPaddingNull = widget.horizontal == null || widget.horizontal == null;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        keyboardType: widget.isNumberOnly ?? false
            ? TextInputType.number
            : widget.isPhoneNumber ?? false
            ? TextInputType.number
            : null,
        inputFormatters: widget.isNumberOnly ?? false
            ? <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                ThousandsFormatter(),
              ]
            : widget.isPhoneNumber ?? false
            ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
            : null,
        enabled: widget.enabled,
        controller: textEditingController,
        focusNode: focusNode,
        validator: widget.validator,
        maxLength: widget.maxLength,
        maxLines: widget.maxLines == null ? 1 : widget.maxLines,
        obscureText: visible == false && widget.obscure,
        decoration: InputDecoration(
          contentPadding: !isPaddingNull
              ? EdgeInsets.symmetric(
                  horizontal: widget.horizontal!,
                  vertical: widget.vertical!,
                )
              : EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          labelText: widget.label,
          suffixIcon: icon,
          helperText: widget.helper,
          hintText: widget.hint,
          fillColor: Colors.white,
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
        ),
        onChanged: (value) {
          widget.onChanged(value);
        },
        onFieldSubmitted: (value) {
          if (widget.onSubmitted != null) widget.onSubmitted!(value);
        },
      ),
    );
  }
}

//#END
