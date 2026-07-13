import 'package:flutter/material.dart';
import 'package:gestobar/core/theme/app_theme.dart';
import 'package:gestobar/core/constants/api_constants.dart';
import '../config_bento_card.dart';
import '../config_text_field.dart';

class IdentidadTab extends StatelessWidget {
  final TextEditingController nombreCtrl;
  final TextEditingController ciudadCtrl;
  final TextEditingController direccionCtrl;
  final TextEditingController ubicacionCtrl;
  final TextEditingController whatsappCtrl;
  final String? logoUrl;
  final bool isUploading;
  final VoidCallback onPickImage;

  const IdentidadTab({
    super.key,
    required this.nombreCtrl,
    required this.ciudadCtrl,
    required this.direccionCtrl,
    required this.ubicacionCtrl,
    required this.whatsappCtrl,
    required this.logoUrl,
    required this.isUploading,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ConfigBentoCard(
            title: 'Identidad',
            description: 'Sube el logo de tu local y actualiza toda la información.',
            icon: Icons.storefront_outlined,
            child: Column(
              children: [
                GestureDetector(
                  onTap: isUploading ? null : onPickImage,
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.liquidSurfaceContainerHigh,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.liquidOutline),
                    ),
                    child: isUploading
                        ? const Center(child: CircularProgressIndicator())
                        : logoUrl != null && logoUrl!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  ApiConstants.resolveImageUrl(logoUrl)!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.image,
                                    size: 40,
                                    color: AppTheme.liquidOnSurfaceVariant,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: AppTheme.liquidOnSurfaceVariant,
                              ),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Logo (Toca para cambiar)', style: theme.textTheme.labelSmall),
                const SizedBox(height: 24),
                ConfigTextField(
                  label: 'Nombre Comercial',
                  controller: nombreCtrl,
                  hintText: 'ej. Neon Lounge',
                  prefixIcon: Icons.storefront,
                  validator: (v) => v != null && v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                ConfigTextField(
                  label: 'Ciudad',
                  controller: ciudadCtrl,
                  hintText: 'ej. Santa Cruz',
                  prefixIcon: Icons.location_city,
                ),
                const SizedBox(height: 12),
                ConfigTextField(
                  label: 'Dirección Física',
                  controller: direccionCtrl,
                  hintText: 'ej. Av. Bush 2do Anillo',
                  prefixIcon: Icons.map,
                ),
                const SizedBox(height: 12),
                ConfigTextField(
                  label: 'Enlace Google Maps',
                  controller: ubicacionCtrl,
                  hintText: 'https://maps.google.com/...',
                  prefixIcon: Icons.link,
                ),
                const SizedBox(height: 12),
                ConfigTextField(
                  label: 'WhatsApp',
                  controller: whatsappCtrl,
                  hintText: 'ej. +59170000000',
                  prefixIcon: Icons.phone,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
