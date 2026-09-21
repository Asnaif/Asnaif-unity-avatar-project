import 'package:flutter/material.dart';
import 'package:interprep/common/constants/styles.dart';

class OptionsContainer extends StatelessWidget {
  final String industryName;

  const OptionsContainer({
    super.key,
    required this.industryName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
      child: InkWell(
        child: Container(
          padding: const EdgeInsets.only(top: 15, left: 20),
          height: 65,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 160, 203, 224),
            border: Border.all(
              color: Colors.black,
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(10),
            ),
          ),
          child: Text(
            industryName,
            style: Styles.displayLargeBoldStyle,
          ),
        ),
        onTap: () {},
      ),
    );
  }
}

