import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/bar_provider.dart';
import '../data/models/bar_model.dart';
import '../providers/tarifas_provider.dart';

class ConfigPage extends ConsumerStatefulWidget {
  const ConfigPage({super.key});

  @override
  ConsumerState<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends ConsumerState<ConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nombreCtrl;
  late TextEditingController _whatsappCtrl;
  late TextEditingController _facebookCtrl;
  late TextEditingController _instagramCtrl;
  late TextEditingController _tiktokCtrl;
  late TextEditingController _comisionCtrl;
  late TextEditingController _ciudadCtrl;
  late TextEditingController _ubicacionCtrl;
  late TextEditingController _direccionCtrl;
  
  String? _logoUrl;
  bool _isUploading = false;

  bool _moduloDamasActivo = false;
  String? _originalIso;
  String? _originalTimezone;
  String? _selectedTarifaCompaniaId;
  
  String _currentIso = 'USD';
  String _currentTimezone = 'America/La_Paz';

  final List<String> _isoOptions = ['USD', 'BOB', 'CLP', 'COP', 'PEN', 'MXN', 'ARS', 'EUR'];
  final List<String> _timezoneOptions = ['America/La_Paz', 'America/Santiago', 'America/Bogota', 'America/Lima', 'America/Mexico_City', 'America/Argentina/Buenos_Aires'];

  final List<String> _dias = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'];
  Map<String, dynamic> _horarios = {};

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController();
    _whatsappCtrl = TextEditingController();
    _facebookCtrl = TextEditingController();
    _instagramCtrl = TextEditingController();
    _tiktokCtrl = TextEditingController();
    _comisionCtrl = TextEditingController();
    _ciudadCtrl = TextEditingController();
    _ubicacionCtrl = TextEditingController();
    _direccionCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _whatsappCtrl.dispose();
    _facebookCtrl.dispose();
    _instagramCtrl.dispose();
    _tiktokCtrl.dispose();
    _comisionCtrl.dispose();
    _ciudadCtrl.dispose();
    _ubicacionCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  void _populateControllers(BarModel bar) {
    if (!_initialized) {
      _nombreCtrl.text = bar.nombre;
      _ciudadCtrl.text = bar.ciudad ?? '';
      _direccionCtrl.text = bar.direccion ?? '';
      _ubicacionCtrl.text = bar.linkUbicacion ?? '';
      _logoUrl = bar.logoUrl;
      _whatsappCtrl.text = bar.whatsapp ?? '';
      _facebookCtrl.text = bar.facebook ?? '';
      _instagramCtrl.text = bar.instagram ?? '';
      _tiktokCtrl.text = bar.tiktok ?? '';
      _comisionCtrl.text = bar.comisionPorcentaje.toString();
      _moduloDamasActivo = bar.moduloDamasActivo;
      
      _currentIso = _isoOptions.contains(bar.monedaIso) ? bar.monedaIso : 'USD';
      _currentTimezone = _timezoneOptions.contains(bar.timezone) ? bar.timezone : 'America/La_Paz';
      
      _originalIso = _currentIso;
      _originalTimezone = _currentTimezone;
      _selectedTarifaCompaniaId = bar.tarifaCompaniaId;

      _horarios = Map<String, dynamic>.from(bar.horarios ?? _generateDefaultHorarios());

      _initialized = true;
    }
  }

  Map<String, dynamic> _generateDefaultHorarios() {
    Map<String, dynamic> defaults = {};
    for (var dia in _dias) {
      defaults[dia] = {
        'abierto': true,
        'apertura': '17:00',
        'cierre': '02:00',
      };
    }
    return defaults;
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _isUploading = true);
      final url = await ref.read(currentBarProvider.notifier).uploadLogo(image.path);
      setState(() {
        _isUploading = false;
        if (url != null) _logoUrl = url;
      });
      if (url == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al subir la imagen')));
      }
    }
  }

  Future<bool> _showCriticalWarningModal(String fieldName) async {
    bool confirm = false;
    final confirmCtrl = TextEditingController();
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.liquidSurface,
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.colorWarning),
              const SizedBox(width: 8),
              const Text('Advertencia Crítica'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estás cambiando un ajuste global ($fieldName).\n\n'
                '${fieldName == 'Moneda' 
                  ? 'Este cambio es meramente visual y de formato. NO realiza una conversión monetaria de tus precios actuales.'
                  : 'Los reportes de ventas históricos podrían desfasarse en tiempo si cambias la zona horaria.'}\n\n'
                'Escribe "CONFIRMAR" para proceder.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmCtrl,
                decoration: const InputDecoration(
                  labelText: 'Escribe CONFIRMAR',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (confirmCtrl.text.trim().toUpperCase() == 'CONFIRMAR') {
                  confirm = true;
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.colorWarning),
              child: const Text('Entendido, Cambiar'),
            ),
          ],
        );
      },
    );
    return confirm;
  }

  String _getSymbolFromIso(String iso) {
    switch (iso) {
      case 'BOB':
        return 'Bs';
      case 'PEN':
        return 'S/';
      case 'EUR':
        return '€';
      default:
        return '\$';
    }
  }

  Future<void> _saveConfig() async {
    if (_formKey.currentState!.validate()) {
      
      if (_originalIso != null && _originalIso != _currentIso) {
        final confirmed = await _showCriticalWarningModal('Moneda');
        if (!confirmed) return;
      }
      
      if (_originalTimezone != null && _originalTimezone != _currentTimezone) {
        final confirmed = await _showCriticalWarningModal('Zona Horaria');
        if (!confirmed) return;
      }

      final updates = {
        'nombre': _nombreCtrl.text.trim(),
        'ciudad': _ciudadCtrl.text.trim(),
        'direccion': _direccionCtrl.text.trim(),
        'link_ubicacion': _ubicacionCtrl.text.trim(),
        'logo_url': _logoUrl,
        'moneda_iso': _currentIso,
        'moneda_simbolo': _getSymbolFromIso(_currentIso),
        'timezone': _currentTimezone,
        'whatsapp': _whatsappCtrl.text.trim(),
        'facebook': _facebookCtrl.text.trim(),
        'instagram': _instagramCtrl.text.trim(),
        'tiktok': _tiktokCtrl.text.trim(),
        'modulo_damas_activo': _moduloDamasActivo,
        'comision_porcentaje': double.tryParse(_comisionCtrl.text) ?? 0.0,
        'tarifa_compania_id': _selectedTarifaCompaniaId,
        'horarios': _horarios,
      };

      final success = await ref.read(currentBarProvider.notifier).updateBarInfo(updates);
      if (success) {
        _originalIso = _currentIso;
        _originalTimezone = _currentTimezone;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Configuración guardada correctamente.')),
          );
        }
      }
    }
  }


  Future<void> _pickTime(String dia, String type) async {
    final currentStr = _horarios[dia][type] as String;
    final parts = currentStr.split(':');
    final initialTime = TimeOfDay(
      hour: parts.isNotEmpty ? int.parse(parts[0]) : 17, 
      minute: parts.length > 1 ? int.parse(parts[1]) : 0
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        _horarios[dia][type] = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    IconData? prefixIcon,
    String? suffixText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: AppTheme.liquidOnSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6.0),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: theme.textTheme.bodyMedium,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: AppTheme.liquidPrimary) : null,
            suffixText: suffixText,
            suffixStyle: TextStyle(color: AppTheme.liquidPrimary, fontWeight: FontWeight.bold),
            filled: true,
            fillColor: AppTheme.liquidSurfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24.0),
              borderSide: BorderSide(color: AppTheme.liquidOutline.withOpacity(0.3), width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24.0),
              borderSide: BorderSide(color: AppTheme.liquidPrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24.0),
              borderSide: BorderSide(color: AppTheme.colorDanger, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24.0),
              borderSide: BorderSide(color: AppTheme.colorDanger, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: AppTheme.liquidOnSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6.0),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          style: theme.textTheme.bodyMedium,
          icon: Icon(Icons.expand_more, color: AppTheme.liquidOnSurfaceVariant),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.liquidSurfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24.0),
              borderSide: BorderSide(color: AppTheme.liquidOutline.withOpacity(0.3), width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24.0),
              borderSide: BorderSide(color: AppTheme.liquidPrimary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePickerField({
    required String label,
    required String time,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: AppTheme.liquidOnSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6.0),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: AppTheme.liquidSurfaceContainerLow,
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: AppTheme.liquidOutline.withOpacity(0.3), width: 1.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: 16, color: AppTheme.liquidPrimary),
                const SizedBox(width: 8),
                Text(
                  time,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final barState = ref.watch(currentBarProvider);
    final tarifasState = ref.watch(barTarifasProvider);
    final theme = Theme.of(context);

    return barState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (bar) {
        _populateControllers(bar);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Configuración Global'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: FilledButton.icon(
                  onPressed: _saveConfig,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  final cardWidth = isMobile ? constraints.maxWidth : (constraints.maxWidth / 2) - 12;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      // 1. Identidad
                      _buildBentoCard(
                        width: cardWidth,
                        title: 'Identidad del Bar',
                        icon: Icons.storefront,
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _isUploading ? null : _pickImage,
                              child: Container(
                                height: 100,
                                width: 100,
                                decoration: BoxDecoration(
                                  color: AppTheme.liquidSurfaceContainerHigh,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.liquidOutline),
                                ),
                                child: _isUploading 
                                  ? const Center(child: CircularProgressIndicator())
                                  : _logoUrl != null && _logoUrl!.isNotEmpty
                                    ? ClipOval(child: Image.network('http://127.0.0.1:3000$_logoUrl', fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(Icons.image, size: 40, color: AppTheme.liquidOnSurfaceVariant)))
                                    : Icon(Icons.add_a_photo, size: 40, color: AppTheme.liquidOnSurfaceVariant),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Logo (Toca para cambiar)', style: theme.textTheme.labelSmall),
                            const SizedBox(height: 24),
                            _buildTextField(
                              label: 'Nombre Comercial',
                              controller: _nombreCtrl,
                              hintText: 'ej. Neon Lounge',
                              prefixIcon: Icons.storefront,
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              label: 'Ciudad',
                              controller: _ciudadCtrl,
                              hintText: 'ej. Santa Cruz',
                              prefixIcon: Icons.location_city,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              label: 'Dirección Física',
                              controller: _direccionCtrl,
                              hintText: 'ej. Av. Bush 2do Anillo',
                              prefixIcon: Icons.map,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              label: 'Enlace Google Maps',
                              controller: _ubicacionCtrl,
                              hintText: 'https://maps.google.com/...',
                              prefixIcon: Icons.link,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              label: 'WhatsApp',
                              controller: _whatsappCtrl,
                              hintText: 'ej. +59170000000',
                              prefixIcon: Icons.phone,
                            ),
                          ],
                        ),
                      ),
                      
                      // 2. Redes
                      _buildBentoCard(
                        width: cardWidth,
                        title: 'Redes y Contacto',
                        icon: Icons.link,
                        child: Column(
                          children: [
                            _buildTextField(
                              label: 'Facebook',
                              controller: _facebookCtrl,
                              hintText: 'https://facebook.com/lounge...',
                              prefixIcon: Icons.facebook,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              label: 'Instagram',
                              controller: _instagramCtrl,
                              hintText: 'https://instagram.com/lounge...',
                              prefixIcon: Icons.camera_alt_outlined,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              label: 'TikTok',
                              controller: _tiktokCtrl,
                              hintText: 'https://tiktok.com/@lounge...',
                              prefixIcon: Icons.music_note,
                            ),
                          ],
                        ),
                      ),

                      // 3. Operaciones
                      _buildBentoCard(
                        width: constraints.maxWidth,
                        title: 'Operaciones',
                        description: 'Gestiona el horario semanal del bar, la moneda de transacciones y la zona horaria local.',
                        icon: Icons.access_time_filled,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            isMobile
                              ? Column(
                                  children: [
                                    _buildDropdownField<String>(
                                      label: 'Moneda (ISO)',
                                      value: _currentIso,
                                      items: _isoOptions.map((iso) => DropdownMenuItem(value: iso, child: Text(iso))).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _currentIso = val);
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    _buildDropdownField<String>(
                                      label: 'Zona Horaria',
                                      value: _currentTimezone,
                                      items: _timezoneOptions.map((tz) => DropdownMenuItem(
                                        value: tz,
                                        child: Text(
                                          tz,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      )).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _currentTimezone = val);
                                      },
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: _buildDropdownField<String>(
                                        label: 'Moneda (ISO)',
                                        value: _currentIso,
                                        items: _isoOptions.map((iso) => DropdownMenuItem(value: iso, child: Text(iso))).toList(),
                                        onChanged: (val) {
                                          if (val != null) setState(() => _currentIso = val);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildDropdownField<String>(
                                        label: 'Zona Horaria',
                                        value: _currentTimezone,
                                        items: _timezoneOptions.map((tz) => DropdownMenuItem(
                                          value: tz,
                                          child: Text(
                                            tz,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        )).toList(),
                                        onChanged: (val) {
                                          if (val != null) setState(() => _currentTimezone = val);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                            const SizedBox(height: 20),
                            const Divider(height: 1, thickness: 0.5),
                            const SizedBox(height: 16),
                            Text(
                              'HORARIOS SEMANALES',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: AppTheme.liquidOnSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._dias.map((dia) {
                              final data = _horarios[dia];
                              if (data == null) return const SizedBox();
                              
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: isMobile 
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              dia.toUpperCase(),
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.0,
                                                color: data['abierto'] ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.4),
                                              ),
                                            ),
                                            Transform.scale(
                                              scale: 0.8,
                                              child: Switch.adaptive(
                                                value: data['abierto'],
                                                activeColor: AppTheme.liquidPrimary,
                                                onChanged: (v) => setState(() => data['abierto'] = v),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (data['abierto']) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildTimePickerField(
                                                  label: 'Apertura',
                                                  time: data['apertura'],
                                                  onTap: () => _pickTime(dia, 'apertura'),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: _buildTimePickerField(
                                                  label: 'Cierre',
                                                  time: data['cierre'],
                                                  onTap: () => _pickTime(dia, 'cierre'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ] else ...[
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 4.0),
                                            child: Text(
                                              'CERRADO',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 8.0),
                                          child: Divider(height: 1, thickness: 0.5),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Row(
                                                children: [
                                                  Transform.scale(
                                                    scale: 0.8,
                                                    child: Switch.adaptive(
                                                      value: data['abierto'],
                                                      activeColor: AppTheme.liquidPrimary,
                                                      onChanged: (v) => setState(() => data['abierto'] = v),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    dia.toUpperCase(),
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      letterSpacing: 1.0,
                                                      color: data['abierto'] ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.4),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              flex: 5,
                                              child: data['abierto']
                                                ? Row(
                                                    children: [
                                                      Expanded(
                                                        child: _buildTimePickerField(
                                                          label: 'Apertura',
                                                          time: data['apertura'],
                                                          onTap: () => _pickTime(dia, 'apertura'),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: _buildTimePickerField(
                                                          label: 'Cierre',
                                                          time: data['cierre'],
                                                          onTap: () => _pickTime(dia, 'cierre'),
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Padding(
                                                      padding: const EdgeInsets.only(left: 8.0),
                                                      child: Text(
                                                        'CERRADO',
                                                        style: theme.textTheme.bodySmall?.copyWith(
                                                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                                                          fontWeight: FontWeight.w600,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 6.0),
                                          child: Divider(height: 1, thickness: 0.5),
                                        ),
                                      ],
                                    ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      
                      // 4. Modulo Damas
                      _buildBentoCard(
                        width: cardWidth,
                        title: 'Módulo Damas',
                        icon: Icons.people_alt_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'MÓDULO DE COMPAÑÍA',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Habilita tickets y comisiones',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: AppTheme.liquidOnSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Transform.scale(
                                  scale: 0.8,
                                  child: Switch.adaptive(
                                    value: _moduloDamasActivo,
                                    activeColor: AppTheme.liquidPrimary,
                                    onChanged: (v) => setState(() => _moduloDamasActivo = v),
                                  ),
                                ),
                              ],
                            ),
                            if (_moduloDamasActivo) ...[
                              const SizedBox(height: 16),
                              tarifasState.when(
                                data: (tarifas) {
                                  return _buildDropdownField<String?>(
                                    label: 'Tarifa de Compañía',
                                    value: _selectedTarifaCompaniaId,
                                    items: tarifas.map((t) => DropdownMenuItem<String?>(
                                      value: t.id,
                                      child: Text(t.nombre),
                                    )).toList(),
                                    onChanged: (val) {
                                      setState(() => _selectedTarifaCompaniaId = val);
                                    },
                                  );
                                },
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (err, _) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text('Error al cargar tarifas: $err', style: const TextStyle(color: Colors.red)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                label: 'Comisión por Venta (%)',
                                controller: _comisionCtrl,
                                keyboardType: TextInputType.number,
                                suffixText: '%',
                                validator: (v) => v!.isEmpty ? 'Requerido' : null,
                              ),
                            ],
                          ],
                        ),
                      ),

                    ],
                  );
                }
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBentoCard({
    required double width,
    required String title,
    String? description,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.liquidSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.liquidOutline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.liquidPrimary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 6),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.liquidOnSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
