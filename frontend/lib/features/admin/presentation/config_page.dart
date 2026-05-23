import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_helper.dart';
import '../providers/bar_provider.dart';
import '../data/models/bar_model.dart';
import '../providers/tarifas_provider.dart';
import '../data/models/tarifa_model.dart';
import '../../../core/widgets/premium_fab.dart';

class ConfigPage extends ConsumerStatefulWidget {
  const ConfigPage({super.key});

  @override
  ConsumerState<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends ConsumerState<ConfigPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TabController _tabController;

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

  final List<String> _isoOptions = [
    'USD', 'BOB', 'BRL', 'CLP', 'COP', 'CRC', 'CUP', 'DOP', 'EUR', 'GTQ',
    'HNL', 'MXN', 'NIO', 'PAB', 'PEN', 'PYG', 'SVC', 'UYU', 'VES'
  ];
  final List<String> _timezoneOptions = [
    'America/New_York', 'America/Chicago', 'America/Denver', 'America/Los_Angeles',
    'Europe/Madrid', 'Atlantic/Canary', 'America/La_Paz', 'America/Lima',
    'America/Santiago', 'America/Bogota', 'America/Mexico_City', 'America/Monterrey',
    'America/Tijuana', 'America/Argentina/Buenos_Aires', 'America/Sao_Paulo',
    'America/Manaus', 'America/Costa_Rica', 'America/El_Salvador', 'America/Guatemala',
    'America/Tegucigalpa', 'America/Managua', 'America/Panama', 'America/Asuncion',
    'America/Caracas', 'America/Montevideo', 'America/Guayaquil', 'America/Santo_Domingo',
    'America/Puerto_Rico', 'America/Havana'
  ];

  final List<String> _dias = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'];
  Map<String, dynamic> _horarios = {};

  bool _initialized = false;
  BarModel? _initialBar;

  void _onInputChanged() {
    setState(() {}); // Re-evaluate _hasUnsavedChanges
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    
    _nombreCtrl = TextEditingController()..addListener(_onInputChanged);
    _whatsappCtrl = TextEditingController()..addListener(_onInputChanged);
    _facebookCtrl = TextEditingController()..addListener(_onInputChanged);
    _instagramCtrl = TextEditingController()..addListener(_onInputChanged);
    _tiktokCtrl = TextEditingController()..addListener(_onInputChanged);
    _comisionCtrl = TextEditingController()..addListener(_onInputChanged);
    _ciudadCtrl = TextEditingController()..addListener(_onInputChanged);
    _ubicacionCtrl = TextEditingController()..addListener(_onInputChanged);
    _direccionCtrl = TextEditingController()..addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      _initialBar = bar;
      _nombreCtrl.text = bar.nombre;
      _ciudadCtrl.text = bar.ciudad ?? '';
      _direccionCtrl.text = bar.direccion ?? '';
      _ubicacionCtrl.text = bar.linkUbicacion ?? '';
      _logoUrl = bar.logoUrl;
      _whatsappCtrl.text = bar.whatsapp ?? '';
      _facebookCtrl.text = bar.facebook ?? '';
      _tiktokCtrl.text = bar.tiktok ?? '';
      _comisionCtrl.text = bar.comisionPorcentaje.toInt().toString();
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
        'abierto': false,
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

  bool _hasUnsavedChanges() {
    if (_initialBar == null) return false;
    final b = _initialBar!;
    
    if (_nombreCtrl.text.trim() != b.nombre) return true;
    if (_ciudadCtrl.text.trim() != (b.ciudad ?? '')) return true;
    if (_direccionCtrl.text.trim() != (b.direccion ?? '')) return true;
    if (_ubicacionCtrl.text.trim() != (b.linkUbicacion ?? '')) return true;
    if (_whatsappCtrl.text.trim() != (b.whatsapp ?? '')) return true;
    if (_facebookCtrl.text.trim() != (b.facebook ?? '')) return true;
    if (_instagramCtrl.text.trim() != (b.instagram ?? '')) return true;
    if (_tiktokCtrl.text.trim() != (b.tiktok ?? '')) return true;
    if ((double.tryParse(_comisionCtrl.text) ?? 0.0) != b.comisionPorcentaje) return true;
    if (_moduloDamasActivo != b.moduloDamasActivo) return true;
    if (_currentIso != b.monedaIso) return true;
    if (_currentTimezone != b.timezone) return true;
    if (_selectedTarifaCompaniaId != b.tarifaCompaniaId) return true;
    if (_logoUrl != b.logoUrl) return true;

    final initialHorarios = b.horarios ?? _generateDefaultHorarios();
    for (var dia in _dias) {
      final cur = _horarios[dia];
      final init = initialHorarios[dia];
      if (cur == null || init == null) continue;
      if (cur['abierto'] != init['abierto']) return true;
      if (cur['apertura'] != init['apertura']) return true;
      if (cur['cierre'] != init['cierre']) return true;
    }
    
    return false;
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
        'moneda_simbolo': CurrencyHelper.getSymbolFromIso(_currentIso),
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
        final bool isCurrencyChanged = _originalIso != null && _originalIso != _currentIso;
        _originalIso = _currentIso;
        _originalTimezone = _currentTimezone;
        ref.invalidate(currentBarProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Configuración guardada correctamente.')),
          );
          
          if (isCurrencyChanged) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF16181C),
                title: Text('Reinicio Requerido', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF00F0FF), fontWeight: FontWeight.bold)),
                content: Text('Has cambiado la moneda del Bar.\n\nPor favor, reinicia la aplicación (Hot Restart) para que los nuevos formatos matemáticos se apliquen en todas las pantallas del sistema.', style: GoogleFonts.inter(color: Colors.white70)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Entendido', style: TextStyle(color: Color(0xFF00F0FF))),
                  ),
                ],
              ),
            );
          }
        }
      }
    }
  }

  void _openTarifaDialog(BuildContext context, TarifaModel? tarifa) {
    final barState = ref.read(currentBarProvider);
    final bar = barState.value;
    if (bar == null) return;

    final TextEditingController nameController =
        TextEditingController(text: tarifa?.nombre ?? '');
    bool esDefault = tarifa?.esDefault ?? false;
    bool activo = tarifa?.activo ?? true;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AlertDialog(
                backgroundColor: const Color(0xFF1E2024),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  side: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
                title: Text(
                  tarifa == null ? 'Nueva Tarifa' : 'Editar Tarifa',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                content: Container(
                  width: 320,
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          controller: nameController,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Ej. VIP, Especial...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TARIFA POR DEFECTO',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.liquidOnSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.1,
                            ),
                          ),
                          Switch(
                            value: esDefault,
                            activeColor: const Color(0xFF00F0FF),
                            onChanged: (val) {
                              setDialogState(() {
                                esDefault = val;
                                // Si se fuerza como default, debe estar activa obligatoriamente
                                if (esDefault) activo = true;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TARIFA ACTIVA',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.liquidOnSurfaceVariant,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.1,
                            ),
                          ),
                          Switch(
                            value: activo,
                            activeColor: const Color(0xFF00F0FF),
                            onChanged: esDefault
                                ? null // Si es default, no se puede desactivar
                                : (val) {
                                    setDialogState(() {
                                      activo = val;
                                    });
                                  },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar', style: GoogleFonts.inter(color: Colors.white60)),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) return;

                      final repo = ref.read(tarifasRepositoryProvider);
                      try {
                        if (tarifa == null) {
                          await repo.createTarifa(
                            bar.id,
                            nameController.text.trim(),
                            esDefault,
                            activo,
                          );
                        } else {
                          await repo.updateTarifa(
                            tarifa.id,
                            nameController.text.trim(),
                            esDefault,
                            activo,
                          );
                        }
                        ref.invalidate(barTarifasProvider);
                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al guardar tarifa: $e'),
                              backgroundColor: AppTheme.colorDanger,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00F0FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteTarifa(BuildContext context, TarifaModel tarifa) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: const Color(0xFF1E2024),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.0),
              side: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            title: Text(
              'Eliminar Tarifa',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            content: Text(
              '¿Estás seguro de que deseas eliminar la tarifa "${tarifa.nombre}"? Esto eliminará todos los precios asignados a esta tarifa de forma permanente.',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar', style: GoogleFonts.inter(color: Colors.white60)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final repo = ref.read(tarifasRepositoryProvider);
                  try {
                    await repo.deleteTarifa(tarifa.id);
                    ref.invalidate(barTarifasProvider);
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al eliminar tarifa: $e'),
                          backgroundColor: AppTheme.colorDanger,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Eliminar',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
        _onInputChanged();
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
    List<TextInputFormatter>? inputFormatters,
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
          inputFormatters: inputFormatters,
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
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.0,
            fontWeight: FontWeight.w600,
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
        final hasChanges = _hasUnsavedChanges();

        return Scaffold(
          floatingActionButton: PremiumFAB(
            label: 'Guardar',
            icon: Icons.save,
            isEnabled: hasChanges,
            onPressed: () {
              if (hasChanges) _saveConfig();
            },
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: const Color(0xFF00F0FF),
                    unselectedLabelColor: Colors.white54,
                    indicatorColor: const Color(0xFF00F0FF),
                    labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: 'Identidad'),
                      Tab(text: 'Redes Sociales'),
                      Tab(text: 'Operaciones'),
                      Tab(text: 'Horario'),
                      Tab(text: 'Compañía'),
                      Tab(text: 'Tarifas'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildIdentidadTab(theme),
                        _buildRedesTab(theme),
                        _buildOperacionesTab(theme),
                        _buildHorarioTab(theme),
                        _buildCompaniaTab(theme, tarifasState),
                        _buildTarifasTab(theme, tarifasState),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIdentidadTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _buildBentoCard(
            width: double.infinity,
            title: 'Identidad',
            description: 'Sube el logo de tu local y actualiza toda la información.',
            icon: Icons.storefront_outlined,
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
        ),
      ),
    );
  }

  Widget _buildRedesTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _buildBentoCard(
            width: double.infinity,
            title: 'Redes Sociales',
            description: 'Añade los enlaces de tus redes para compartirlos con tus clientes.',
            icon: Icons.link_rounded,
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
        ),
      ),
    );
  }

  Widget _buildOperacionesTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              _buildBentoCard(
                width: double.infinity,
                title: 'Operaciones',
                description: 'Configura la moneda de transacciones y la zona horaria local.',
                icon: Icons.monetization_on_outlined,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 400;
                if (isMobile) {
                  return Column(
                    children: [
                      _buildDropdownField<String>(
                        label: 'Moneda del Bar',
                        value: _currentIso,
                        items: _isoOptions.map((iso) => DropdownMenuItem(
                          value: iso, 
                          child: Text(CurrencyHelper.getCurrencyLabel(iso)),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _currentIso = val);
                            _onInputChanged();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildDropdownField<String>(
                        label: 'Zona Horaria',
                        value: _currentTimezone,
                        items: _timezoneOptions.map((tz) => DropdownMenuItem(
                          value: tz,
                          child: Text(tz, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _currentTimezone = val);
                            _onInputChanged();
                          }
                        },
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField<String>(
                          label: 'Moneda del Bar',
                          value: _currentIso,
                          items: _isoOptions.map((iso) => DropdownMenuItem(
                            value: iso, 
                            child: Text(CurrencyHelper.getCurrencyLabel(iso)),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _currentIso = val);
                              _onInputChanged();
                            }
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
                            child: Text(tz, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _currentTimezone = val);
                              _onInputChanged();
                            }
                          },
                        ),
                      ),
                    ],
                  );
                }
              }
            ),
          ),
          const SizedBox(height: 24),
          _buildCurrencyPreview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyPreview() {
    final symbol = CurrencyHelper.getSymbolFromIso(_currentIso);
    final formatted = CurrencyHelper.formatAmount(15000.5, _currentIso);
    final decimals = CurrencyHelper.getDecimalDigits(_currentIso);
    
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00F0FF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.visibility_outlined, color: Color(0xFF00F0FF), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('VISTA PREVIA DEL FORMATO', style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
                    children: [
                      const TextSpan(text: 'Los cobros de 15,000.50 se verán como: '),
                      TextSpan(text: '$symbol $formatted', style: const TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold, fontSize: 16)),
                    ]
                  ),
                ),
                const SizedBox(height: 4),
                Text('La moneda $_currentIso usa $decimals decimales.', style: GoogleFonts.inter(color: Colors.white30, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorarioTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _buildBentoCard(
            width: double.infinity,
            title: 'Horario Semanal',
            description: 'Gestiona los días de apertura y horas de atención.',
            icon: Icons.access_time_filled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._dias.map((dia) {
                  final data = _horarios[dia];
                  if (data == null) return const SizedBox();
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    padding: const EdgeInsets.only(top: 0.0, bottom: 12.0, left: 16.0, right: 16.0),
                    decoration: BoxDecoration(
                      color: AppTheme.liquidSurfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.liquidOutline.withOpacity(0.3)),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 400;
                        if (isMobile) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dia.toUpperCase(),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: data['abierto'] ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.4),
                                    ),
                                  ),
                                  Transform.scale(
                                    scale: 0.8,
                                    child: Switch.adaptive(
                                      value: data['abierto'],
                                      activeColor: AppTheme.liquidPrimary,
                                      onChanged: (v) {
                                        setState(() => data['abierto'] = v);
                                        _onInputChanged();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              if (data['abierto']) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(child: _buildTimePickerField(label: 'Apertura', time: data['apertura'], onTap: () => _pickTime(dia, 'apertura'))),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildTimePickerField(label: 'Cierre', time: data['cierre'], onTap: () => _pickTime(dia, 'cierre'))),
                                  ],
                                ),
                              ] else ...[
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text('CERRADO', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                                ),
                              ],
                            ],
                          );
                        } else {
                          return Column(
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
                                            onChanged: (v) {
                                              setState(() => data['abierto'] = v);
                                              _onInputChanged();
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          dia.toUpperCase(), 
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13, 
                                            fontWeight: FontWeight.w700, 
                                            color: data['abierto'] ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.4)
                                          )
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
                                            Expanded(child: _buildTimePickerField(label: 'Apertura', time: data['apertura'], onTap: () => _pickTime(dia, 'apertura'))),
                                            const SizedBox(width: 12),
                                            Expanded(child: _buildTimePickerField(label: 'Cierre', time: data['cierre'], onTap: () => _pickTime(dia, 'cierre'))),
                                          ],
                                        )
                                      : Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(left: 8.0), child: Text('CERRADO', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4), fontWeight: FontWeight.w600, letterSpacing: 0.5)))),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                      }
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompaniaTab(ThemeData theme, AsyncValue<List<TarifaModel>> tarifasState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _buildBentoCard(
            width: double.infinity,
            title: 'Damas de Compañía',
            description: 'Habilita tickets y comisiones.',
            icon: Icons.people_alt_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Activar', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch.adaptive(
                        value: _moduloDamasActivo,
                        activeColor: AppTheme.liquidPrimary,
                        onChanged: (v) {
                          setState(() => _moduloDamasActivo = v);
                          _onInputChanged();
                        },
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
                        items: tarifas.where((t) => !t.esDefault).map((t) => DropdownMenuItem<String?>(value: t.id, child: Text(t.nombre))).toList(),
                        onChanged: (val) {
                          setState(() => _selectedTarifaCompaniaId = val);
                          _onInputChanged();
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('Error al cargar tarifas: $err', style: const TextStyle(color: Colors.red))),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: 'Comisión por Venta (%)',
                    controller: _comisionCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    suffixText: '%',
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      final num = int.tryParse(v);
                      if (num == null || num < 1 || num > 99) return 'De 1 a 99';
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTarifasTab(ThemeData theme, AsyncValue<List<TarifaModel>> tarifasState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _buildBentoCard(
            width: double.infinity,
            title: 'Gestión de Precios',
            description: 'Crea precios infinitos (ej. Normal, VIP, Compañía) para tus productos.',
            icon: Icons.payments_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tarifasState.when(
                  data: (tarifas) {
                    if (tarifas.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text('No hay tarifas creadas. Crea una para comenzar.', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tarifas.length,
                      itemBuilder: (context, index) {
                        final tarifa = tarifas[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.liquidSurfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.liquidOutline.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    tarifa.nombre, 
                                    style: GoogleFonts.plusJakartaSans(
                                      color: tarifa.activo ? Colors.white : Colors.white30, 
                                      fontWeight: FontWeight.bold, 
                                      fontSize: 14,
                                      decoration: tarifa.activo ? null : TextDecoration.lineThrough,
                                    )
                                  ),
                                  if (tarifa.esDefault) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: const Color(0xFF00F0FF).withOpacity(0.15), borderRadius: BorderRadius.circular(100)),
                                      child: Text('Default', style: GoogleFonts.inter(color: const Color(0xFF00F0FF), fontWeight: FontWeight.bold, fontSize: 10)),
                                    ),
                                  ],
                                  if (tarifa.id == _selectedTarifaCompaniaId) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.pinkAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(100)),
                                      child: Text('Dama', style: GoogleFonts.inter(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 10)),
                                    ),
                                  ],
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit, color: Color(0xFF00F0FF), size: 18), onPressed: () => _openTarifaDialog(context, tarifa)),
                                  if (!tarifa.esDefault) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18), onPressed: () => _confirmDeleteTarifa(context, tarifa)),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF))),
                  error: (err, _) => Text('Error al cargar tarifas: $err', style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _openTarifaDialog(context, null),
                  icon: const Icon(Icons.add, size: 16, color: Color(0xFF0c0e12)),
                  label: Text('Nueva Tarifa', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF0c0e12))),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00F0FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                ),
              ],
            ),
          ),
        ),
      ),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.liquidSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.liquidOutline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.liquidPrimary, size: 24),
              const SizedBox(width: 12),
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
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.liquidOnSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.5, color: Colors.white10),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
