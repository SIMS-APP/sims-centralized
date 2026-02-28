import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

/// A button widget optimized for Android TV D-pad navigation.
/// Shows clear visual feedback when focused.
class TvFocusButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool autofocus;
  final double width;
  final double height;
  final Color? backgroundColor;
  final Color? focusColor;

  const TvFocusButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.autofocus = false,
    this.width = 200,
    this.height = 56,
    this.backgroundColor,
    this.focusColor,
  });

  @override
  State<TvFocusButton> createState() => _TvFocusButtonState();
}

class _TvFocusButtonState extends State<TvFocusButton>
    with SingleTickerProviderStateMixin {
  bool _isFocused = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: AppConstants.unfocusedScale,
      end: AppConstants.focusedScale,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (hasFocus) {
        setState(() => _isFocused = hasFocus);
        if (hasFocus) {
          _scaleController.forward();
        } else {
          _scaleController.reverse();
        }
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: widget.onPressed,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: _isFocused
                      ? (widget.focusColor ??
                          const Color(AppConstants.accentColor))
                      : (widget.backgroundColor ??
                          const Color(AppConstants.surfaceColor)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isFocused
                        ? const Color(AppConstants.focusBorderColor)
                        : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: const Color(AppConstants.accentColor)
                                .withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A card widget with TV-optimized focus behavior
class TvFocusCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool autofocus;
  final EdgeInsets padding;

  const TvFocusCard({
    super.key,
    required this.child,
    this.onPressed,
    this.autofocus = false,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<TvFocusCard> createState() => _TvFocusCardState();
}

class _TvFocusCardState extends State<TvFocusCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (hasFocus) {
        setState(() => _isFocused = hasFocus);
      },
      onKeyEvent: (node, event) {
        if (widget.onPressed != null &&
            event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onPressed!();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isFocused ? AppConstants.focusedScale : AppConstants.unfocusedScale,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: widget.padding,
            decoration: BoxDecoration(
              color: const Color(AppConstants.surfaceColor),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFocused
                    ? const Color(AppConstants.focusBorderColor)
                    : Colors.grey.shade800,
                width: _isFocused ? 3 : 1,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: const Color(AppConstants.accentColor)
                            .withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 4,
                      )
                    ]
                  : [],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
