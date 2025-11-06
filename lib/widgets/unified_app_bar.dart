import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import 'app_drawer.dart';

/// Unified AppBar that shows both hamburger menu and back button on all screens
class UnifiedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? currentRoute;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  const UnifiedAppBar({
    super.key,
    this.title,
    this.currentRoute,
    this.actions,
    this.automaticallyImplyLeading = false,
  });

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    final canPop = Navigator.of(context).canPop();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRTL = loc.isRTL;

    return AppBar(
      backgroundColor: isDark ? const Color(0xFF161B22) : const Color(0xFFE53E3E),
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: (kIsWeb && canPop) ? 96 : 48, // Back+menu only on web
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Back button if can pop
          if (kIsWeb && canPop)
            IconButton(
              icon: Icon(isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios),
              color: Colors.white,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: loc.getString('back') == 'back' ? 'Geri' : loc.getString('back'),
            ),
          // Hamburger menu (always show)
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              color: Colors.white,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: loc.getString('menu') == 'menu' ? 'Menü' : loc.getString('menu'),
            ),
          ),
        ],
      ),
      title: Text(
        title ?? loc.getString('app_name') ?? 'HemoAI',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: Colors.white,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      actions: actions ?? [],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

