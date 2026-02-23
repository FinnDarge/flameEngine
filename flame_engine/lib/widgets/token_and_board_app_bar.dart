import 'package:flutter/material.dart';

/// Reusable app bar with Token & Board branding
class TokenAndBoardAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final double toolbarHeight;
  final VoidCallback? onBackPressed;

  const TokenAndBoardAppBar({
    super.key,
    this.toolbarHeight = 56.0,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF2d2d2d),
      automaticallyImplyLeading: false,
      toolbarHeight: toolbarHeight,
      leading: onBackPressed != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBackPressed,
            )
          : null,
      title: Row(
        children: [
          Icon(Icons.games, color: Colors.blue.shade300, size: 24),
          const SizedBox(width: 8),
          Text(
            'Token & Board',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);
}
