import 'dart:async' as dart_async;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ToastType { success, error, warning, info }

class CustomToast {
  static OverlayEntry? _currentEntry;

  /// Closes the active Toast immediately without delay.
  static void dismiss() {
    if (_currentEntry != null) {
      try {
        _currentEntry!.remove();
      } catch (_) {
        // Safe catch if already disposed/removed
      }
      _currentEntry = null;
    }
  }

  /// Displays an elegant custom Toast notification.
  ///
  /// For tablet landscape view, it appears in the top-right corner.
  /// For mobile or tablet portrait view, it appears centered at the bottom.
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Dismiss any active toast first to prevent overlap
    dismiss();

    final overlayState = Overlay.of(context);
    
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return _ToastWidget(
          message: message,
          type: type,
          duration: duration,
          onDismissComplete: () {
            try {
              entry.remove();
            } catch (_) {}
            if (_currentEntry == entry) {
              _currentEntry = null;
            }
          },
        );
      },
    );

    _currentEntry = entry;
    overlayState.insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismissComplete;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismissComplete,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  dart_async.Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _autoDismissTimer = dart_async.Timer(widget.duration, () {
      _dismiss();
    });

    _controller.forward();
  }

  void _dismiss() {
    _autoDismissTimer?.cancel();
    if (mounted) {
      _controller.reverse().then((_) {
        widget.onDismissComplete();
      });
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final bool isTabletHorizontal = size.width >= 720 && orientation == Orientation.landscape;

    // Define slide animation depending on layout
    final slideAnimation = Tween<Offset>(
      begin: isTabletHorizontal ? const Offset(1.2, 0.0) : const Offset(0.0, 1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuad,
    ));

    // Resolve color and icon based on ToastType
    Color accentColor;
    IconData iconData;

    switch (widget.type) {
      case ToastType.success:
        accentColor = const Color(0xFF00FF7F); // Spring Green
        iconData = Icons.check_circle_outline;
        break;
      case ToastType.error:
        accentColor = Colors.redAccent;
        iconData = Icons.error_outline;
        break;
      case ToastType.warning:
        accentColor = Colors.orangeAccent;
        iconData = Icons.warning_amber_outlined;
        break;
      case ToastType.info:
      default:
        accentColor = const Color(0xFF00F0FF); // Cyan
        iconData = Icons.info_outline;
        break;
    }

    final toastCard = Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: Container(
            width: isTabletHorizontal ? 360 : null,
            decoration: BoxDecoration(
              color: const Color(0xFF22252A), // Level 3 Contrast Background
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Glowing vertical colored indicator
                  Container(
                    width: 5,
                    color: accentColor,
                  ),
                  const SizedBox(width: 16),
                  Center(
                    child: Icon(
                      iconData,
                      color: accentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      child: Text(
                        widget.message,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Center(
                    child: IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.white.withOpacity(0.4),
                        size: 16,
                      ),
                      onPressed: _dismiss,
                      splashRadius: 18,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (isTabletHorizontal) {
      return Positioned(
        top: 24 + MediaQuery.of(context).padding.top,
        right: 24,
        child: toastCard,
      );
    } else {
      return Positioned(
        bottom: 40 + MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: toastCard,
          ),
        ),
      );
    }
  }
}
