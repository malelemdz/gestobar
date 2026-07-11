import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium_fab.dart';
import '../../admin/providers/menu_admin_provider.dart';
import 'widgets/categories_panel.dart';
import 'widgets/products_panel.dart';
import 'dialogs/add_edit_product_dialog.dart';
import '../../../core/widgets/custom_toast.dart';

class MenuPage extends ConsumerStatefulWidget {
  const MenuPage({super.key});

  @override
  ConsumerState<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends ConsumerState<MenuPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final menuAdminState = ref.watch(menuAdminProvider);

    // Listen to success/error messages from Menu Admin Provider
    ref.listen<MenuAdminState>(menuAdminProvider, (previous, next) {
      if (next.successMessage != null && next.successMessage != previous?.successMessage) {
        CustomToast.show(
          context,
          message: next.successMessage!,
          type: ToastType.success,
        );
      }
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        CustomToast.show(
          context,
          message: next.errorMessage!,
          type: ToastType.error,
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF111317), // Deep Dark background
      floatingActionButton: PremiumFAB(
        label: 'Nuevo Producto',
        icon: Icons.add,
        onPressed: () => _openAddEditProductDialog(context),
      ),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isTablet = constraints.maxWidth >= 900;

            return Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Unified Header
                    _buildHeader(theme, isTablet),

                    Expanded(
                      child: isTablet
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Bento Pane: Categories (30% or 320px)
                                Container(
                                  width: 320,
                                  padding: const EdgeInsets.fromLTRB(24, 0, 12, 12),
                                  child: const CategoriesPanel(),
                                ),
                                // Elegant vertical divider line
                                Container(
                                  width: 1,
                                  color: Colors.white.withOpacity(0.04),
                                ),
                                // Right Bento Pane: Products grid (70%)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(12, 0, 24, 12),
                                    child: ProductsPanel(searchQuery: _searchQuery),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                // Mobile view horizontal scroll categories
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                                  child: MobileCategoriesCarousel(),
                                ),
                                const SizedBox(height: 12),
                                // Expanded mobile products grid
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: ProductsPanel(searchQuery: _searchQuery),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
                if (menuAdminState.isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.4),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00F0FF),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // =========================================================================
  // 🏷️ HEADER SECTION
  // =========================================================================
  Widget _buildHeader(ThemeData theme, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24.0 : 16.0,
        vertical: 12.0,
      ),
      child: Row(
        children: [
          // Search Input Box
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1E2024),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar productos...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF00F0FF), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAddEditProductDialog(BuildContext context) {
    final bool isTabletLandscape = MediaQuery.of(context).size.width >= 720;
    if (isTabletLandscape) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.85),
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: AddEditProductDialog(product: null, isDialog: true),
            ),
          );
        },
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withOpacity(0.75),
        builder: (context) {
          return const AddEditProductDialog(product: null, isDialog: false);
        },
      );
    }
  }
}
