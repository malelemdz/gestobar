import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../pos/models/category_model.dart';
import '../../../pos/providers/catalog_provider.dart';
import '../../../admin/providers/menu_admin_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/responsive_modal.dart';

class AddEditCategoryDialog extends ConsumerStatefulWidget {
  final CategoryModel? category;

  const AddEditCategoryDialog({
    super.key,
    this.category,
  });

  @override
  ConsumerState<AddEditCategoryDialog> createState() => _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState extends ConsumerState<AddEditCategoryDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.nombre ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDialog = MediaQuery.of(context).size.width >= 720;

    final Widget body = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'NOMBRE',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.liquidOnSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0C0E12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: TextField(
              controller: _nameController,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ej. Cócteles, Botellas...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );

    final Widget footer = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            'Cancelar',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () async {
            if (_nameController.text.trim().isEmpty) return;

            final navigator = Navigator.of(context);
            final notifier = ref.read(menuAdminProvider.notifier);
            bool success = false;

            if (widget.category == null) {
              final currentCats = ref.read(categoriesProvider).value ?? [];
              final nextOrder = currentCats.isEmpty
                  ? 1
                  : currentCats.map((c) => c.orden).reduce((a, b) => a > b ? a : b) + 1;

              success = await notifier.createCategory(
                _nameController.text.trim(),
                nextOrder,
              );
            } else {
              success = await notifier.updateCategory(
                widget.category!.id,
                _nameController.text.trim(),
                widget.category!.orden,
              );
            }

            if (success && mounted) {
              navigator.pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00F0FF),
            foregroundColor: const Color(0xFF0C0E12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            elevation: 0,
          ),
          child: Text(
            'Guardar',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0c0e12),
            ),
          ),
        ),
      ],
    );

    return ResponsiveModalContainer(
      title: widget.category == null ? 'Nueva Categoría' : 'Editar Categoría',
      isDialog: isDialog,
      footer: footer,
      child: body,
    );
  }
}
