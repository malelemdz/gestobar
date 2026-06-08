import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../pos/models/category_model.dart';
import '../../../pos/providers/catalog_provider.dart';
import '../../../admin/providers/menu_admin_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../dialogs/add_edit_category_dialog.dart';
import '../dialogs/bottom_confirmation_sheet.dart';
import '../../../../core/widgets/responsive_modal.dart';


// =========================================================================
// 🏷️ CATEGORIES SIDEBAR (TABLET / DESKTOP PANEL)
// =========================================================================
class CategoriesPanel extends ConsumerWidget {
  const CategoriesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C20),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.04),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CATEGORÍAS',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                  letterSpacing: 0.1,
                  color: AppTheme.liquidOnSurfaceVariant,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00F0FF), size: 20),
                onPressed: () => _openCategoryDialog(context, null),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: categoriesAsync.when(
              data: (categories) {
                final sortedCategories = List<CategoryModel>.from(categories)
                  ..sort((a, b) => a.orden.compareTo(b.orden));

                return ListView.builder(
                  itemCount: sortedCategories.length + 1,
                  itemBuilder: (context, index) {
                    final bool isAll = index == 0;
                    final String? catId = isAll ? null : sortedCategories[index - 1].id;
                    final String nombre = isAll ? 'Ver Todo' : sortedCategories[index - 1].nombre;
                    final bool isSelected = selectedCategoryId == catId;

                    if (isAll) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: InkWell(
                          onTap: () {
                            ref.read(selectedCategoryIdProvider.notifier).state = null;
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF1E2024) : const Color(0xFF17191C),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF00F0FF).withOpacity(0.2) : Colors.white.withOpacity(0.03),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    nombre,
                                    style: GoogleFonts.inter(
                                      color: isSelected ? Colors.white : Colors.white60,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 32), // Match footprint of PopupMenuButton
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final cat = sortedCategories[index - 1];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: InkWell(
                        onTap: () {
                          ref.read(selectedCategoryIdProvider.notifier).state = cat.id;
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Opacity(
                          opacity: cat.disponible ? 1.0 : 0.4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF1E2024) : const Color(0xFF17191C),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF00F0FF).withOpacity(0.2) : Colors.white.withOpacity(0.03),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    cat.nombre,
                                    style: GoogleFonts.inter(
                                      color: isSelected ? Colors.white : Colors.white60,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  color: const Color(0xFF1E2024),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.white.withOpacity(0.05)),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Icon(Icons.more_vert, size: 16, color: Colors.white70),
                                  ),
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'up':
                                        _swapCategoriesOrder(ref, cat, sortedCategories[index - 2]);
                                        break;
                                      case 'down':
                                        _swapCategoriesOrder(ref, cat, sortedCategories[index]);
                                        break;
                                      case 'toggle':
                                        _toggleCategoryVisibility(context, ref, cat);
                                        break;
                                      case 'edit':
                                        _openCategoryDialog(context, cat);
                                        break;
                                      case 'delete':
                                        _confirmDeleteCategory(context, ref, cat);
                                        break;
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                    PopupMenuItem<String>(
                                      value: 'up',
                                      enabled: index > 1,
                                      child: Row(
                                        children: [
                                          Icon(Icons.arrow_upward, size: 16, color: index > 1 ? Colors.white70 : Colors.white24),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Subir Posición',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: index > 1 ? Colors.white : Colors.white30,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'down',
                                      enabled: index < sortedCategories.length,
                                      child: Row(
                                        children: [
                                          Icon(Icons.arrow_downward, size: 16, color: index < sortedCategories.length ? Colors.white70 : Colors.white24),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Bajar Posición',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: index < sortedCategories.length ? Colors.white : Colors.white30,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'toggle',
                                      child: Row(
                                        children: [
                                          Icon(
                                            cat.disponible ? Icons.toggle_on : Icons.toggle_off,
                                            size: 16,
                                            color: cat.disponible ? const Color(0xFF00F0FF) : Colors.orangeAccent,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            cat.disponible ? 'Desactivar' : 'Activar',
                                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.edit, size: 16, color: Color(0xFF00F0FF)),
                                          const SizedBox(width: 8),
                                          Text('Editar', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(height: 1),
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Eliminar',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ShimmerPlaceholder(
                    width: double.infinity,
                    height: 34,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              error: (err, st) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 📱 MOBILE CATEGORIES CAROUSEL WITH SETTINGS GEAR
// =========================================================================
class MobileCategoriesCarousel extends ConsumerWidget {
  const MobileCategoriesCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);

    return categoriesAsync.when(
      data: (categories) {
        final sortedCategories = List<CategoryModel>.from(categories)
          ..sort((a, b) => a.orden.compareTo(b.orden));

        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: sortedCategories.length + 1,
                  itemBuilder: (context, index) {
                    final bool isAll = index == 0;
                    final String? catId = isAll ? null : sortedCategories[index - 1].id;
                    final String nombre = isAll ? 'Todos' : sortedCategories[index - 1].nombre;
                    final bool isSelected = selectedCategoryId == catId;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: () {
                          ref.read(selectedCategoryIdProvider.notifier).state = catId;
                        },
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [Color(0xFF7000FF), Color(0xFF00F0FF)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isSelected ? null : const Color(0xFF1E2024),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF00F0FF).withOpacity(0.3)
                                  : Colors.white.withOpacity(0.05),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            nombre,
                            style: GoogleFonts.plusJakartaSans(
                              color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _openMobileCategoryManager(context, ref, sortedCategories),
              borderRadius: BorderRadius.circular(100),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2024),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: const Icon(Icons.settings, color: Color(0xFF00F0FF), size: 20),
              ),
            ),
          ],
        );
      },
      loading: () => SizedBox(
        height: 38,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ShimmerPlaceholder(
              width: index == 0 ? 60 : 90,
              height: 38,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
      ),
      error: (err, st) => const SizedBox(height: 38),
    );
  }
}

// =========================================================================
// ⚙️ MOBILE REORDERABLE CATEGORY MANAGER BOTTOM SHEET
// =========================================================================
class MobileCategoryManagerBottomSheet extends ConsumerStatefulWidget {
  final List<CategoryModel> categories;

  const MobileCategoryManagerBottomSheet({
    super.key,
    required this.categories,
  });

  @override
  ConsumerState<MobileCategoryManagerBottomSheet> createState() => _MobileCategoryManagerBottomSheetState();
}

class _MobileCategoryManagerBottomSheetState extends ConsumerState<MobileCategoryManagerBottomSheet> {
  late List<CategoryModel> _localCategories;

  @override
  void initState() {
    super.initState();
    _localCategories = List<CategoryModel>.from(widget.categories);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Administrar Categorías',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00F0FF)),
                onPressed: () {
                  Navigator.pop(context);
                  _openCategoryDialog(context, null);
                },
              ),
            ],
          ),
          const Divider(color: Colors.white10),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: _localCategories.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = _localCategories.removeAt(oldIndex);
                  _localCategories.insert(newIndex, item);

                  // Update orders in background via Riverpod notifier
                  final notifier = ref.read(menuAdminProvider.notifier);
                  for (int i = 0; i < _localCategories.length; i++) {
                    if (_localCategories[i].orden != i + 1) {
                      notifier.updateCategory(_localCategories[i].id, _localCategories[i].nombre, i + 1);
                    }
                  }
                });
              },
              itemBuilder: (context, index) {
                final cat = _localCategories[index];
                return Padding(
                  key: ValueKey(cat.id),
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Opacity(
                    opacity: cat.disponible ? 1.0 : 0.4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF131518),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Text(
                          cat.nombre,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                cat.disponible ? Icons.toggle_on : Icons.toggle_off,
                                size: 16,
                                color: cat.disponible ? const Color(0xFF00F0FF) : Colors.orangeAccent,
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Navigator.pop(context);
                                _toggleCategoryVisibility(context, ref, cat);
                              },
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 16, color: Color(0xFF00F0FF)),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Navigator.pop(context);
                                _openCategoryDialog(context, cat);
                              },
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Navigator.pop(context);
                                _confirmDeleteCategory(context, ref, cat);
                              },
                            ),
                            const SizedBox(width: 8),
                            ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_handle, color: Colors.white30, size: 24),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// ⚡ HELPER ACTIONS
// =========================================================================
Future<void> _swapCategoriesOrder(
  WidgetRef ref,
  CategoryModel activeCat,
  CategoryModel otherCat,
) async {
  final notifier = ref.read(menuAdminProvider.notifier);
  final int activeOrder = activeCat.orden;
  final int otherOrder = otherCat.orden;

  // Swap ordering numbers
  await notifier.updateCategory(activeCat.id, activeCat.nombre, otherOrder);
  await notifier.updateCategory(otherCat.id, otherCat.nombre, activeOrder);
}

void _toggleCategoryVisibility(BuildContext context, WidgetRef ref, CategoryModel category) async {
  final bool? confirm = await BottomConfirmationSheet.show(
    context: context,
    title: category.disponible ? '¿Apagar Categoría?' : '¿Encender Categoría?',
    description: category.disponible
        ? 'Esto apagará la categoría y ocultará de forma automática (en cascada) todos sus productos en el punto de venta y Menú QR. ¿Estás seguro?'
        : 'Esto encenderá la categoría y hará visibles nuevamente todos los productos y variantes que contenga. ¿Estás seguro?',
    confirmText: category.disponible ? 'Sí, Apagar' : 'Sí, Encender',
    confirmColor: category.disponible ? Colors.orangeAccent : const Color(0xFF00F0FF),
    icon: category.disponible ? Icons.toggle_off : Icons.toggle_on,
  );

  if (confirm == true) {
    ref.read(menuAdminProvider.notifier).updateCategory(
          category.id,
          category.nombre,
          category.orden,
          disponible: !category.disponible,
        );
  }
}

void _confirmDeleteCategory(BuildContext context, WidgetRef ref, CategoryModel category) async {
  final bool? confirm = await BottomConfirmationSheet.show(
    context: context,
    title: '¿Eliminar ${category.nombre}?',
    description: '¿Estás seguro de que deseas eliminar la categoría "${category.nombre}"? Esto desvinculará sus productos y no se puede deshacer.',
    confirmText: 'Eliminar',
    confirmColor: Colors.redAccent,
    icon: Icons.delete_outline,
  );

  if (confirm == true) {
    ref.read(menuAdminProvider.notifier).deleteCategory(category.id);
  }
}

void _openCategoryDialog(BuildContext context, CategoryModel? category) {
  showResponsiveDialog(
    context: context,
    maxWidth: 450,
    child: AddEditCategoryDialog(category: category),
  );
}

void _openMobileCategoryManager(BuildContext context, WidgetRef ref, List<CategoryModel> categories) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A1C20),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return MobileCategoryManagerBottomSheet(categories: categories);
    },
  );
}
