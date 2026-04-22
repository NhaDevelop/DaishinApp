import 'package:flutter/material.dart';

/// A reusable DAISHIN logo widget for use in app bars and other locations
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? textColor;
  final Axis orientation;

  const AppLogo({
    super.key,
    this.size = 40,
    this.showText = true,
    this.textColor,
    this.orientation = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: orientation,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // DAISHIN Logo
        Container(
          height: size,
          width: size,
          padding: EdgeInsets.all(size * 0.1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.2),
            color: Colors.white,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.1),
            child: Image.asset(
              'assets/images/daishin_logo.jpg',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.shopping_bag,
                  color: const Color(0xFF8B1E1E),
                  size: size * 0.6,
                );
              },
            ),
          ),
        ),
        if (showText) ...[
          SizedBox(
            width: orientation == Axis.horizontal ? size * 0.3 : 0,
            height: orientation == Axis.vertical ? size * 0.2 : 0,
          ),
          Text(
            'DAISHIN',
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

/// A smaller logo widget specifically for use as a leading icon in app bars
/// A reusable DAISHIN logo widget that acts as a consistent back button
class AppBarLogo extends StatelessWidget {
  final VoidCallback? onTap;

  const AppBarLogo({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: GestureDetector(
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        child: Container(
          width: 45, // Slightly bigger touch target
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(6), // Inner padding
          child: const Center(
            child: AppLogo(
              size: 30, // Inner logo size
              showText: false,
            ),
          ),
        ),
      ),
    );
  }
}
