import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final double height;
  final bool isLight;

  const BrandLogo({super.key, this.height = 60, this.isLight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(8), 
        boxShadow: isLight ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/nxn_logo.jpg',
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
}
