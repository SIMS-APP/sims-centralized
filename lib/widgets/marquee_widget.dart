import 'package:flutter/material.dart';

/// Scrolling marquee text widget for bottom of screen
class MarqueeWidget extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double height;
  final Color backgroundColor;

  const MarqueeWidget({
    super.key,
    required this.text,
    this.style,
    this.height = 48,
    this.backgroundColor = const Color(0xDD000000),
  });

  @override
  State<MarqueeWidget> createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _animation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: const Offset(-1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      color: widget.backgroundColor,
      child: ClipRect(
        child: SlideTransition(
          position: _animation,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 2,
            child: Center(
              child: Text(
                '${widget.text}          ${widget.text}',
                maxLines: 1,
                softWrap: false,
                style: widget.style ??
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
