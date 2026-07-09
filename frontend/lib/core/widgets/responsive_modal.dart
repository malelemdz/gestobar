import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResponsiveModalContainer extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;
  final bool isDialog;
  final VoidCallback? onClose;

  const ResponsiveModalContainer({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.footer,
    required this.isDialog,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final size = MediaQuery.of(context).size;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    
    // Si safeAreaTop ya es 0 (porque useSafeArea consumió el espacio), dejamos 16.0 de espacio mínimo.
    // De lo contrario, dejamos safeArea + 16.0 para crear un margen elegante debajo de la barra de estado/isla.
    final topOffset = safeAreaTop > 0 ? safeAreaTop + 16.0 : 16.0;
    
    // Altura disponible real por encima del teclado y debajo de la barra de estado
    final availableHeight = size.height - viewInsets.bottom - topOffset;

    // Limitamos la altura máxima en móviles para dar espacio sin tapar la parte superior de la pantalla
    final maxModalHeight = isDialog
        ? size.height * 0.90
        : (availableHeight < size.height * 0.85 ? availableHeight : size.height * 0.85);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxModalHeight > 100.0 ? maxModalHeight : 100.0,
        ),
        margin: isDialog ? EdgeInsets.zero : EdgeInsets.only(bottom: viewInsets.bottom),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2024), // Level 2 Modal
          borderRadius: isDialog
              ? BorderRadius.circular(24.0)
              : const BorderRadius.vertical(top: Radius.circular(24.0)),
          border: isDialog
              ? Border.all(color: Colors.white.withOpacity(0.06), width: 1.0)
              : Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.0),
                ),
        ),
        child: ClipRRect(
          borderRadius: isDialog
              ? BorderRadius.circular(24.0)
              : const BorderRadius.vertical(top: Radius.circular(24.0)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isDialog)
                const SizedBox(height: 16)
              else ...[
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onClose ?? () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white70, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              // Body
              Flexible(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: (footer == null && !isDialog)
                        ? MediaQuery.of(context).padding.bottom + 12.0
                        : 0.0,
                  ),
                  child: child,
                ),
              ),
              // Footer
              if (footer != null) ...[
                const Divider(color: Colors.white10, height: 1),
                Container(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    12,
                    24,
                    12 + (isDialog ? 0.0 : MediaQuery.of(context).padding.bottom),
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E2024),
                  ),
                  child: footer!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<T?> showResponsiveModal<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required Widget child,
  Widget? footer,
  double maxWidth = 550,
  bool isScrollControlled = true,
  Color? barrierColor,
}) {
  final bool isTablet = MediaQuery.of(context).size.width >= 720;

  final modal = ResponsiveModalContainer(
    title: title,
    subtitle: subtitle,
    footer: footer,
    isDialog: isTablet,
    child: child,
  );

  return showResponsiveDialog<T>(
    context: context,
    child: modal,
    maxWidth: maxWidth,
    isScrollControlled: isScrollControlled,
    barrierColor: barrierColor,
  );
}

Future<T?> showResponsiveDialog<T>({
  required BuildContext context,
  required Widget child,
  double maxWidth = 550,
  bool isScrollControlled = true,
  Color? barrierColor,
}) {
  final bool isTablet = MediaQuery.of(context).size.width >= 720;

  if (isTablet) {
    return showDialog<T>(
      context: context,
      barrierColor: barrierColor ?? Colors.black.withOpacity(0.85),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  } else {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: barrierColor ?? Colors.black.withOpacity(0.75),
      builder: (context) => child,
    );
  }
}
