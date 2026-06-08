import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardBottomBar extends StatelessWidget {
  final List<Map<String, dynamic>> navItems;
  final String activeView;
  final void Function(String) onViewChanged;

  const DashboardBottomBar({
    super.key,
    required this.navItems,
    required this.activeView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Filtrar 'audit' y 'analytics' para no mostrarlos en barra inferior (manteniendo comportamiento original)
    final filteredItems = navItems.where((item) => item['view'] != 'audit' && item['view'] != 'analytics').toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16.0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 12.0,
        right: 12.0,
        top: 12.0,
        bottom: MediaQuery.of(context).padding.bottom + 12.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: filteredItems.map((item) {
          final String viewId = item['view'] as String;
          final bool isSelected = activeView == viewId;
          final IconData icon = isSelected ? item['icon_active'] as IconData : item['icon'] as IconData;
          final String label = item['label'] as String;

          if (isSelected) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0x2600F0FF),
                borderRadius: BorderRadius.circular(100.0),
                border: Border.all(
                  color: const Color(0x3300F0FF),
                  width: 1.0,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: const Color(0xFF00F0FF),
                    size: 18.0,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF00F0FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
            );
          }

          return InkWell(
            borderRadius: BorderRadius.circular(100.0),
            onTap: () => onViewChanged(viewId),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: Colors.white.withOpacity(0.4),
                    size: 20.0,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withOpacity(0.4),
                      fontWeight: FontWeight.w500,
                      fontSize: 10.0,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
