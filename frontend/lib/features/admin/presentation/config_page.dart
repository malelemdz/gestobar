import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gestobar/core/theme/app_theme.dart';
import 'package:gestobar/core/utils/currency_helper.dart';
import 'package:gestobar/core/widgets/premium_fab.dart';
import 'package:gestobar/features/auth/providers/auth_provider.dart';
import 'package:gestobar/features/auth/providers/auth_state.dart';

import '../providers/bar_provider.dart';
import '../providers/menu_admin_provider.dart';
import '../data/models/bar_model.dart';
import '../providers/tarifas_provider.dart';
import '../data/models/tarifa_model.dart';
import '../../pos/providers/catalog_provider.dart';
import '../../caja/providers/caja_provider.dart';
import '../../caja/providers/ventas_activas_provider.dart';

// Importación de Tabs
import 'widgets/tabs/identidad_tab.dart';
import 'widgets/tabs/redes_tab.dart';
import 'widgets/tabs/operaciones_tab.dart';
import 'widgets/tabs/horario_tab.dart';
import 'widgets/tabs/compania_tab.dart';
import 'widgets/tabs/tarifas_tab.dart';
import 'widgets/tabs/permisos_tab.dart';

// Importación de Diálogos
import 'dialogs/tarifa_dialog.dart';
import 'dialogs/delete_tarifa_dialog.dart';
import 'dialogs/config_warning_sheet.dart';

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

  Map<String, dynamic> _horarios = {};
  bool _initialized = false;
  BarModel? _initialBar;

  // Control de permisos de pestañas por bar (SuperAdmin control)
  Map<String, bool> _permittedTabs = {};
  Map<String, bool> _initialPermittedTabs = {};

  void _onInputChanged() {
    setState(() {}); // Re-evaluar cambios pendientes para habilitar el FAB
  }

  @override
  void initState() {
    super.initState();
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
      _instagramCtrl.text = bar.instagram ?? '';
      _tiktokCtrl.text = bar.tiktok ?? '';
      _comisionCtrl.text = bar.comisionPorcentaje.toInt().toString();
      _moduloDamasActivo = bar.moduloDamasActivo;

      _currentIso = bar.monedaIso;
      _currentTimezone = bar.timezone;

      _originalIso = _currentIso;
      _originalTimezone = _currentTimezone;
      _selectedTarifaCompaniaId = bar.tarifaCompaniaId;

      _horarios = Map<String, dynamic>.from(bar.horarios ?? _generateDefaultHorarios());

      // Pre-diseño de carga de permisos de pestañas (asociados al bar)
      // En el futuro, esto se leerá desde un campo 'configuracion_tabs_permitidas' en el BarModel
      _permittedTabs = {
        'identidad': true,
        'redes': true,
        'operaciones': true,
        'horario': true,
        'compania': true,
        'tarifas': true,
      };
      _initialPermittedTabs = Map<String, bool>.from(_permittedTabs);

      _initialized = true;
    }
  }

  Map<String, dynamic> _generateDefaultHorarios() {
    final List<String> dias = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'];
    Map<String, dynamic> defaults = {};
    for (var dia in dias) {
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
        if (url != null) {
          _logoUrl = url;
          _onInputChanged();
        }
      });
      if (url == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al subir la imagen')),
        );
      }
    }
  }

  Future<bool> _showUnifiedWarningModal(bool changedCurrency, bool changedTimezone) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ConfigWarningSheet(
          changedCurrency: changedCurrency,
          changedTimezone: changedTimezone,
        );
      },
    );
    return result ?? false;
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
    final List<String> dias = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'];
    for (var dia in dias) {
      final cur = _horarios[dia];
      final init = initialHorarios[dia];
      if (cur == null || init == null) continue;
      if (cur['abierto'] != init['abierto']) return true;
      if (cur['apertura'] != init['apertura']) return true;
      if (cur['cierre'] != init['cierre']) return true;
    }

    // Comprobar cambios en permisos de pestañas (SuperAdmin)
    for (var key in _permittedTabs.keys) {
      if (_permittedTabs[key] != _initialPermittedTabs[key]) return true;
    }

    return false;
  }

  Future<void> _saveConfig() async {
    if (_formKey.currentState!.validate()) {
      final bool changedCurrency = _originalIso != null && _originalIso != _currentIso;
      final bool changedTimezone = _originalTimezone != null && _originalTimezone != _currentTimezone;

      if (changedCurrency || changedTimezone) {
        final confirmed = await _showUnifiedWarningModal(changedCurrency, changedTimezone);
        if (!confirmed) return;
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withOpacity(0.8),
          builder: (context) => Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2024),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF00F0FF)),
                    const SizedBox(height: 24),
                    Text(
                      changedCurrency
                          ? 'Migrando precios...\nEsto puede tomar unos segundos.'
                          : 'Guardando configuración...',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      double conversionRate = 1.0;
      if (changedCurrency) {
        int oldDecimals = CurrencyHelper.getDecimalDigits(_originalIso!);
        int newDecimals = CurrencyHelper.getDecimalDigits(_currentIso);
        if (oldDecimals == 2 && newDecimals == 0) conversionRate = 1000.0;
        if (oldDecimals == 0 && newDecimals == 2) conversionRate = 0.001;
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
        'tasa_conversion': conversionRate,
        // Guardamos los permisos configurados para las pestañas de este bar
        'configuracion_tabs_permitidas': _permittedTabs,
      };

      final success = await ref.read(currentBarProvider.notifier).updateBarInfo(updates);

      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga
      }

      if (success) {
        _originalIso = _currentIso;
        _originalTimezone = _currentTimezone;
        _initialPermittedTabs = Map<String, bool>.from(_permittedTabs);

        ref.invalidate(currentBarProvider);
        ref.invalidate(menuAdminProvider);
        ref.invalidate(productsProvider);
        ref.invalidate(filteredProductsProvider);
        ref.invalidate(posFilteredProductsProvider);
        ref.invalidate(cajaStateProvider);
        ref.invalidate(cajaHistoryProvider);
        ref.invalidate(ventasActivasProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Configuración guardada y precios migrados. La interfaz se actualizará automáticamente.',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF7000FF),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _openTarifaDialog(BuildContext context, TarifaModel? tarifa) {
    final bar = ref.read(currentBarProvider).value;
    if (bar == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return TarifaDialog(
          barId: bar.id,
          tarifa: tarifa,
        );
      },
    );
  }

  void _confirmDeleteTarifa(BuildContext context, TarifaModel tarifa) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return DeleteTarifaDialog(
          tarifa: tarifa,
        );
      },
    );
  }

  Future<void> _pickTime(String dia, String type) async {
    final currentStr = _horarios[dia][type] as String;
    final parts = currentStr.split(':');
    final initialTime = TimeOfDay(
        hour: parts.isNotEmpty ? int.parse(parts[0]) : 17,
        minute: parts.length > 1 ? int.parse(parts[1]) : 0);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        _horarios[dia][type] =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        _onInputChanged();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final barState = ref.watch(currentBarProvider);
    final tarifasState = ref.watch(barTarifasProvider);
    final cajaState = ref.watch(cajaStateProvider);
    final isCajaAbierta = cajaState.value?.abierta ?? false;

    // Obtener el rol del usuario conectado
    final authState = ref.watch(authProvider);
    final String role = authState is AuthAuthenticated ? authState.user.rolNombre.toUpperCase() : 'ADMIN';

    return barState.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF))),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (bar) {
        _populateControllers(bar);
        final hasChanges = _hasUnsavedChanges();

        // 1. Construir lista dinámica de pestañas según rol y permisos
        final List<Map<String, dynamic>> tabs = [];

        if (role == 'SUPERADMIN') {
          // El SuperAdmin tiene acceso completo más la gestión de permisos
          tabs.addAll([
            {
              'id': 'identidad',
              'text': 'Identidad',
              'widget': IdentidadTab(
                nombreCtrl: _nombreCtrl,
                ciudadCtrl: _ciudadCtrl,
                direccionCtrl: _direccionCtrl,
                ubicacionCtrl: _ubicacionCtrl,
                whatsappCtrl: _whatsappCtrl,
                logoUrl: _logoUrl,
                isUploading: _isUploading,
                onPickImage: _pickImage,
              ),
            },
            {
              'id': 'redes',
              'text': 'Redes Sociales',
              'widget': RedesTab(
                facebookCtrl: _facebookCtrl,
                instagramCtrl: _instagramCtrl,
                tiktokCtrl: _tiktokCtrl,
              ),
            },
            {
              'id': 'operaciones',
              'text': 'Operaciones',
              'widget': OperacionesTab(
                currentIso: _currentIso,
                currentTimezone: _currentTimezone,
                isCajaAbierta: isCajaAbierta,
                onIsoChanged: (val) => setState(() {
                  _currentIso = val;
                  _onInputChanged();
                }),
                onTimezoneChanged: (val) => setState(() {
                  _currentTimezone = val;
                  _onInputChanged();
                }),
              ),
            },
            {
              'id': 'horario',
              'text': 'Horario',
              'widget': HorarioTab(
                horarios: _horarios,
                onDiaToggle: (dia, val) => setState(() {
                  _horarios[dia]['abierto'] = val;
                  _onInputChanged();
                }),
                onPickTime: _pickTime,
              ),
            },
            {
              'id': 'compania',
              'text': 'Compañía',
              'widget': CompaniaTab(
                moduloDamasActivo: _moduloDamasActivo,
                selectedTarifaCompaniaId: _selectedTarifaCompaniaId,
                comisionCtrl: _comisionCtrl,
                tarifasState: tarifasState,
                onModuloDamasActivoChanged: (val) => setState(() {
                  _moduloDamasActivo = val;
                  _onInputChanged();
                }),
                onSelectedTarifaCompaniaIdChanged: (val) => setState(() {
                  _selectedTarifaCompaniaId = val;
                  _onInputChanged();
                }),
              ),
            },
            {
              'id': 'tarifas',
              'text': 'Tarifas',
              'widget': TarifasTab(
                selectedTarifaCompaniaId: _selectedTarifaCompaniaId,
                tarifasState: tarifasState,
                onOpenTarifaDialog: (t) => _openTarifaDialog(context, t),
                onDeleteTarifa: (t) => _confirmDeleteTarifa(context, t),
              ),
            },
            {
              'id': 'permisos',
              'text': 'Permisos Admin',
              'widget': PermisosTab(
                permittedTabs: _permittedTabs,
                onTabToggle: (id, val) => setState(() {
                  _permittedTabs[id] = val;
                  _onInputChanged();
                }),
              ),
            },
          ]);
        } else {
          // El Admin ve solo las pestañas que tengan permiso para este bar
          if (_permittedTabs['identidad'] ?? true) {
            tabs.add({
              'id': 'identidad',
              'text': 'Identidad',
              'widget': IdentidadTab(
                nombreCtrl: _nombreCtrl,
                ciudadCtrl: _ciudadCtrl,
                direccionCtrl: _direccionCtrl,
                ubicacionCtrl: _ubicacionCtrl,
                whatsappCtrl: _whatsappCtrl,
                logoUrl: _logoUrl,
                isUploading: _isUploading,
                onPickImage: _pickImage,
              ),
            });
          }
          if (_permittedTabs['redes'] ?? true) {
            tabs.add({
              'id': 'redes',
              'text': 'Redes Sociales',
              'widget': RedesTab(
                facebookCtrl: _facebookCtrl,
                instagramCtrl: _instagramCtrl,
                tiktokCtrl: _tiktokCtrl,
              ),
            });
          }
          if (_permittedTabs['operaciones'] ?? true) {
            tabs.add({
              'id': 'operaciones',
              'text': 'Operaciones',
              'widget': OperacionesTab(
                currentIso: _currentIso,
                currentTimezone: _currentTimezone,
                isCajaAbierta: isCajaAbierta,
                onIsoChanged: (val) => setState(() {
                  _currentIso = val;
                  _onInputChanged();
                }),
                onTimezoneChanged: (val) => setState(() {
                  _currentTimezone = val;
                  _onInputChanged();
                }),
              ),
            });
          }
          if (_permittedTabs['horario'] ?? true) {
            tabs.add({
              'id': 'horario',
              'text': 'Horario',
              'widget': HorarioTab(
                horarios: _horarios,
                onDiaToggle: (dia, val) => setState(() {
                  _horarios[dia]['abierto'] = val;
                  _onInputChanged();
                }),
                onPickTime: _pickTime,
              ),
            });
          }
          if (_permittedTabs['compania'] ?? true) {
            tabs.add({
              'id': 'compania',
              'text': 'Compañía',
              'widget': CompaniaTab(
                moduloDamasActivo: _moduloDamasActivo,
                selectedTarifaCompaniaId: _selectedTarifaCompaniaId,
                comisionCtrl: _comisionCtrl,
                tarifasState: tarifasState,
                onModuloDamasActivoChanged: (val) => setState(() {
                  _moduloDamasActivo = val;
                  _onInputChanged();
                }),
                onSelectedTarifaCompaniaIdChanged: (val) => setState(() {
                  _selectedTarifaCompaniaId = val;
                  _onInputChanged();
                }),
              ),
            });
          }
          if (_permittedTabs['tarifas'] ?? true) {
            tabs.add({
              'id': 'tarifas',
              'text': 'Tarifas',
              'widget': TarifasTab(
                selectedTarifaCompaniaId: _selectedTarifaCompaniaId,
                tarifasState: tarifasState,
                onOpenTarifaDialog: (t) => _openTarifaDialog(context, t),
                onDeleteTarifa: (t) => _confirmDeleteTarifa(context, t),
              ),
            });
          }
        }

        // Si no hay pestañas permitidas para mostrar, mostramos un mensaje de bloqueo
        if (tabs.isEmpty) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, color: Color(0xFF00F0FF), size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'CONFIGURACIÓN DESACTIVADA',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'El SuperAdmin ha desactivado las secciones de configuración para este bar.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
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
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: const Color(0xFF00F0FF),
                      unselectedLabelColor: Colors.white54,
                      indicatorColor: const Color(0xFF00F0FF),
                      labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                      tabs: tabs.map((t) => Tab(text: t['text'] as String)).toList(),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: tabs.map((t) => t['widget'] as Widget).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
