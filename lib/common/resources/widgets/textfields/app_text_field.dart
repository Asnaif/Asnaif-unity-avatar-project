// import 'package:flutter/material.dart';
// import 'package:interprep/common/constants/styles.dart';

// class AppTextField extends StatelessWidget {
//   const AppTextField({
//     super.key,
//     required this.label,
//     required this.keyboardType,
//     required this.controller,
//     required this.validator,
//     this.obscureText = false,
//     this.maxLines = 1,
//     this.minLines,
//   });

//   final String label;
//   final TextInputType keyboardType;
//   final TextEditingController controller;
//   final String? Function(String?) validator;
//   final bool obscureText;
//   final int? maxLines;
//   final int? minLines;

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: double.infinity,
//       child: TextFormField(
//         key: Key('$key TextFormField'),
//         decoration: InputDecoration(
//           label: Text(
//             label,
//             style: Styles.displaySmNormalStyle.copyWith(
//               color: Colors.grey,
//             ),
//           ),
//           border: const OutlineInputBorder(
//             borderRadius: BorderRadius.all(
//               Radius.circular(8),
//             ),
//             borderSide: BorderSide(
//               color: Color.fromRGBO(184, 184, 184, 1),
//             ),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderSide: BorderSide(color: Styles.primaryColor),
//             borderRadius: const BorderRadius.all(
//               Radius.circular(8),
//             ),
//           ),
//           contentPadding: const EdgeInsets.only(
//             left: 20,
//             top: 19,
//             bottom: 18,
//           ),
//         ),
//         keyboardType: keyboardType,
//         controller: controller,
//         validator: validator,
//         obscureText: obscureText,
//         maxLines: maxLines,
//         minLines: minLines,
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:interprep/common/constants/styles.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.keyboardType,
    required this.controller,
    required this.validator,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.prefixIcon,
  });

  final String label;
  final TextInputType keyboardType;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final IconData? prefixIcon;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Focus(
        onFocusChange: (hasFocus) {
          setState(() {
            _isFocused = hasFocus;
          });
        },
        child: TextFormField(
          key: Key('${widget.key} TextFormField'),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: Styles.displaySmNormalStyle.copyWith(
              color: _isFocused ? Styles.primaryColor : Colors.grey.shade600,
              fontWeight: _isFocused ? FontWeight.w600 : FontWeight.normal,
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: _isFocused ? Styles.primaryColor : Colors.grey.shade400,
                    size: 22,
                  )
                : null,
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: _isFocused ? Styles.primaryColor : Colors.grey.shade400,
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Styles.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: _isFocused 
                ? Styles.primaryColor.withOpacity(0.03)
                : Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(
              horizontal: widget.prefixIcon != null ? 12 : 20,
              vertical: 18,
            ),
          ),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          keyboardType: widget.keyboardType,
          controller: widget.controller,
          validator: widget.validator,
          obscureText: widget.obscureText && _obscureText,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
        ),
      ),
    );
  }
}