import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/localization_service.dart';
import 'package:provider/provider.dart';

/// Professional UI/UX enhancement widgets
/// Provides modern, polished UI components

/// Pull to refresh wrapper
class PullToRefreshWrapper extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? refreshColor;

  const PullToRefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.refreshColor,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: refreshColor ?? Theme.of(context).colorScheme.primary,
      child: child,
    );
  }
}

/// Swipe action item
class SwipeActionItem extends StatelessWidget {
  final Widget child;
  final List<SwipeAction> rightActions;
  final List<SwipeAction> leftActions;
  final VoidCallback? onTap;

  const SwipeActionItem({
    super.key,
    required this.child,
    this.rightActions = const [],
    this.leftActions = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // For now, return child with tap handler
    // Full swipe-to-dismiss would require a package like flutter_slidable
    return InkWell(
      onTap: onTap,
      child: child,
    );
  }
}

/// Swipe action model
class SwipeAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const SwipeAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

/// Haptic feedback helper
class HapticFeedbackHelper {
  /// Light impact
  static void light() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact
  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  /// Selection feedback
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Vibrate
  static void vibrate() {
    HapticFeedback.vibrate();
  }
}

/// Enhanced button with haptic feedback
class EnhancedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool enableHaptic;

  const EnhancedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.enableHaptic = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        if (enableHaptic) {
          HapticFeedbackHelper.selection();
        }
        onPressed?.call();
      },
      style: style,
      child: child,
    );
  }
}

/// Smooth scroll to top button
class ScrollToTopButton extends StatelessWidget {
  final ScrollController scrollController;
  final Duration duration;
  final Curve curve;

  const ScrollToTopButton({
    super.key,
    required this.scrollController,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOut,
  });

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    return FloatingActionButton.small(
      onPressed: () {
        HapticFeedbackHelper.light();
        scrollController.animateTo(
          0,
          duration: duration,
          curve: curve,
        );
      },
      child: const Icon(Icons.arrow_upward),
      tooltip: loc.getString('scroll_to_top'),
    );
  }
}

/// Animated counter widget
class AnimatedCounter extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = IntTween(begin: _previousValue, end: widget.value)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _animation = IntTween(begin: _previousValue, end: widget.value)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${_animation.value}',
          style: widget.style,
        );
      },
    );
  }
}

/// Gradient card widget
class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;

  const GradientCard({
    super.key,
    required this.child,
    required this.colors,
    this.padding,
    this.margin,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: padding != null
          ? Padding(padding: padding!, child: child)
          : child,
    );
  }
}

/// Badge widget
class BadgeWidget extends StatelessWidget {
  final int count;
  final Color? color;
  final double? fontSize;

  const BadgeWidget({
    super.key,
    required this.count,
    this.color,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final badgeColor = color ?? theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: TextStyle(
          color: theme.colorScheme.onError,
          fontSize: fontSize ?? 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Search bar with debounce
class DebouncedSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String? hintText;
  final TextEditingController? controller;

  const DebouncedSearchBar({
    super.key,
    required this.onChanged,
    this.hintText,
    this.controller,
  });

  @override
  State<DebouncedSearchBar> createState() => _DebouncedSearchBarState();
}

class _DebouncedSearchBarState extends State<DebouncedSearchBar> {
  late TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      widget.onChanged(_controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: widget.hintText ?? loc.getString('search'),
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
              )
            : null,
      ),
    );
  }
}

