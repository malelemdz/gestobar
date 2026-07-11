import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/styled_text_field.dart';
import '../../../../core/widgets/responsive_modal.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../pos/models/category_model.dart';
import '../../../pos/models/product_model.dart';
import '../../../pos/providers/catalog_provider.dart';
import '../../../caja/providers/caja_provider.dart';
import '../../../admin/providers/menu_admin_provider.dart';
import '../../../admin/providers/tarifas_provider.dart';
import '../../../admin/data/models/tarifa_model.dart';

class AddEditProductDialog extends ConsumerStatefulWidget {
  final ProductModel? product;
  final bool isDialog;

  const AddEditProductDialog({super.key, this.product, this.isDialog = false});

  @override
  ConsumerState<AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends ConsumerState<AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String? _selectedCategoryId;
  String? _fotoUrl;
  String? _localImagePath;
  bool _isUploadingImage = false;

  final List<Map<String, dynamic>> _localVariants = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.nombre ?? '');
    _descriptionController = TextEditingController(text: widget.product?.descripcion ?? '');
    _selectedCategoryId = widget.product?.categoriaId;
    _fotoUrl = widget.product?.fotoUrl;

    if (widget.product != null && widget.product!.variantes.isNotEmpty) {
      for (final variant in widget.product!.variantes) {
        final pricesMap = <String, double>{};
        for (final p in variant.precios) {
          pricesMap[p.tarifaId] = p.precioUnitario;
        }

        _localVariants.add({
          'id': variant.id,
          'nombre': variant.nombre,
          'disponible': variant.disponible,
          'precios': pricesMap,
        });
      }
    }

    if (_selectedCategoryId == null) {
      final currentSelected = ref.read(selectedCategoryIdProvider);
      if (currentSelected != null) {
        _selectedCategoryId = currentSelected;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file == null) return;

      setState(() {
        _localImagePath = file.path;
        _isUploadingImage = true;
      });

      final url = await ref.read(menuAdminProvider.notifier).uploadImage(file.path, 'productos');

      if (mounted) {
        setState(() {
          _fotoUrl = url;
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
        CustomToast.show(
          context,
          message: 'Error al subir imagen: $e',
          type: ToastType.error,
        );
      }
    }
  }

  void _addLocalVariant(List<TarifaModel> tariffs) {
    final pricesMap = <String, double>{};
    for (final tariff in tariffs) {
      pricesMap[tariff.id] = 0.0;
    }

    setState(() {
      _localVariants.add({
        'id': null,
        'nombre': _localVariants.isEmpty ? 'Único' : '',
        'disponible': true,
        'precios': pricesMap,
      });
    });
  }

  void _removeLocalVariant(int index) {
    setState(() {
      _localVariants.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? [];
    final tariffs = ref.watch(barTarifasProvider).value ?? [];
    final currencyIso = ref.watch(currencyIsoProvider);

    if (_localVariants.isEmpty && tariffs.isNotEmpty) {
      _addLocalVariant(tariffs);
    }

    final Widget formBody = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'FOTO EN PORTADA',
                    style: GoogleFonts.poppins(
                      color: AppTheme.liquidOnSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _isUploadingImage ? null : _pickImage,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22252A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_localImagePath != null)
                            Image.file(
                              File(_localImagePath!),
                              fit: BoxFit.cover,
                            )
                          else if (_fotoUrl != null && _fotoUrl!.isNotEmpty)
                            Image.network(
                              ApiConstants.resolveImageUrl(_fotoUrl)!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.redAccent.withOpacity(0.4),
                                      size: 32,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Foto no disponible (Toca para cambiar)',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white30,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  ],
                                );
                              },
                            )
                          else
                            Center(
                              child: SizedBox(
                                width: 52,
                                height: 52,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Icon(
                                        Icons.image_outlined,
                                        color: Colors.white.withOpacity(0.3),
                                        size: 44,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF00F0FF),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          size: 12,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_isUploadingImage)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black54,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF00F0FF),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'NOMBRE DEL PRODUCTO',
              style: GoogleFonts.poppins(
                color: AppTheme.liquidOnSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            StyledTextField(
              controller: _nameController,
              hintText: 'Ej. Mojito Cubano Classic',
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'El nombre es obligatorio' : null,
            ),
            const SizedBox(height: 16),

            Text(
              'DESCRIPCIÓN',
              style: GoogleFonts.poppins(
                color: AppTheme.liquidOnSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            StyledTextField(
              controller: _descriptionController,
              hintText: 'Ej. Ron blanco, hierbabuena fresca, azúcar...',
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            Text(
              'CATEGORÍA',
              style: GoogleFonts.poppins(
                color: AppTheme.liquidOnSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF22252A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                dropdownColor: const Color(0xFF1E2024),
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(border: InputBorder.none),
                hint: const Text('Selecciona una categoría...', style: TextStyle(color: Colors.white30, fontSize: 14)),
                items: categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat.id,
                    child: Text(cat.nombre),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategoryId = val;
                  });
                },
                validator: (val) => val == null ? 'La categoría es obligatoria' : null,
              ),
            ),

            const SizedBox(height: 24),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'VARIANTES',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF00F0FF),
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addLocalVariant(tariffs),
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00F0FF), size: 16),
                  label: Text(
                    'Agregar Variante',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF00F0FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_localVariants.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'No se han configurado variantes. Agrega una para establecer precios.',
                    style: GoogleFonts.poppins(color: Colors.white30, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _localVariants.length,
                itemBuilder: (context, vIndex) {
                  final variant = _localVariants[vIndex];
                  final pricesMap = variant['precios'] as Map<String, double>;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2024),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NOMBRE DE LA VARIANTE',
                                    style: GoogleFonts.poppins(
                                      color: AppTheme.liquidOnSurfaceVariant,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    initialValue: variant['nombre'],
                                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFF22252A),
                                      hintText: 'Ej. Vaso, Botella, Único...',
                                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.0),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF00F0FF), width: 1.0),
                                      ),
                                    ),
                                    onChanged: (val) {
                                      variant['nombre'] = val.trim();
                                    },
                                    validator: (val) => val == null || val.trim().isEmpty
                                        ? 'El nombre de variante es obligatorio'
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              children: [
                                Text(
                                  'DISPONIBLE',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.liquidOnSurfaceVariant,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Switch(
                                  value: variant['disponible'] as bool? ?? true,
                                  activeColor: const Color(0xFF00F0FF),
                                  onChanged: (val) {
                                    setState(() {
                                      variant['disponible'] = val;
                                    });
                                  },
                                ),
                              ],
                            ),
                            if (_localVariants.length > 1)
                              Padding(
                                padding: const EdgeInsets.only(top: 14.0, left: 8.0),
                                child: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () => _removeLocalVariant(vIndex),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 8),

                        Text(
                          'MATRIZ DE PRECIOS POR TARIFA',
                          style: GoogleFonts.poppins(
                            color: AppTheme.liquidOnSurfaceVariant,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        tariffs.isEmpty
                            ? const Text(
                                'Cargando tarifas de bar...',
                                style: TextStyle(color: Colors.white24, fontSize: 11),
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 220,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 1.8,
                                ),
                                itemCount: tariffs.length,
                                itemBuilder: (context, tIndex) {
                                  final tariff = tariffs[tIndex];
                                  final double price = pricesMap[tariff.id] ?? 0.0;

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tariff.nombre.toUpperCase(),
                                        style: GoogleFonts.poppins(
                                          color: tariff.esDefault
                                              ? const Color(0xFF00F0FF)
                                              : Colors.white60,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: price > 0 ? CurrencyHelper.formatAmount(price, currencyIso) : '',
                                          style: GoogleFonts.jetBrainsMono(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          inputFormatters: [
                                            CurrencyInputFormatter(iso: currencyIso),
                                          ],
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: const Color(0xFF22252A),
                                            hintText: CurrencyHelper.getDecimalDigits(currencyIso) == 0 ? '0' : '0.00',
                                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.0),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.0),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(color: Color(0xFF00F0FF), width: 1.0),
                                            ),
                                          ),
                                          onChanged: (val) {
                                            final double pNum = CurrencyHelper.parseAmount(val, currencyIso);
                                            pricesMap[tariff.id] = pNum;
                                          },
                                          validator: (val) {
                                            if (val == null || val.trim().isEmpty) return 'Requerido';
                                            final double pNum = CurrencyHelper.parseAmount(val, currencyIso);
                                            if (pNum <= 0) return 'Inválido';
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );

    final Widget footer = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            'Cancelar',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _saveProduct,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00F0FF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: Text(
            'Guardar Producto',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0C0E12),
            ),
          ),
        ),
      ],
    );

    return ResponsiveModalContainer(
      title: widget.product == null ? 'Registrar Producto' : 'Editar ${widget.product!.nombre}',
      isDialog: widget.isDialog,
      footer: footer,
      child: formBody,
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) return;

    final notifier = ref.read(menuAdminProvider.notifier);
    bool overallSuccess = false;

    final List<Map<String, dynamic>> variantsPayload = [];
    for (final v in _localVariants) {
      final pricesPayload = <Map<String, dynamic>>[];
      final pricesMap = v['precios'] as Map<String, double>;

      pricesMap.forEach((tariffId, priceVal) {
        pricesPayload.add({
          'tarifa_id': tariffId,
          'precio_unitario': priceVal,
        });
      });

      variantsPayload.add({
        'nombre': v['nombre'],
        'disponible': v['disponible'],
        'precios': pricesPayload,
      });
    }

    if (widget.product == null) {
      overallSuccess = await notifier.createProduct(
        nombre: _nameController.text.trim(),
        descripcion: _descriptionController.text.trim(),
        fotoUrl: _fotoUrl,
        categoriaId: _selectedCategoryId!,
        disponible: true,
        variantes: variantsPayload,
      );
    } else {
      final Map<String, dynamic> updates = {
        'nombre': _nameController.text.trim(),
        'descripcion': _descriptionController.text.trim(),
        'foto_url': _fotoUrl,
        'categoria_id': _selectedCategoryId,
      };

      overallSuccess = await notifier.updateProduct(widget.product!.id, updates);

      if (overallSuccess) {
        final List<String> dialogVariantIds = [];

        for (final v in _localVariants) {
          final String? variantId = v['id'] as String?;
          final pricesPayload = <Map<String, dynamic>>[];
          final pricesMap = v['precios'] as Map<String, double>;

          pricesMap.forEach((tariffId, priceVal) {
            pricesPayload.add({
              'tarifa_id': tariffId,
              'precio_unitario': priceVal,
            });
          });

          final Map<String, dynamic> vPayload = {
            'nombre': v['nombre'],
            'disponible': v['disponible'],
            'precios': pricesPayload,
          };

          if (variantId == null) {
            await notifier.addVariant(widget.product!.id, vPayload);
          } else {
            await notifier.updateVariant(variantId, vPayload);
            dialogVariantIds.add(variantId);
          }
        }

        for (final originalV in widget.product!.variantes) {
          if (!dialogVariantIds.contains(originalV.id)) {
            await notifier.deleteVariant(originalV.id);
          }
        }
      }
    }

    if (mounted) {
      if (overallSuccess) {
        CustomToast.show(
          context,
          message: widget.product == null
              ? 'Producto registrado con éxito'
              : 'Producto actualizado con éxito',
          type: ToastType.success,
        );
        Navigator.pop(context);
      } else {
        CustomToast.show(
          context,
          message: 'Error al guardar el producto',
          type: ToastType.error,
        );
      }
    }
  }
}
