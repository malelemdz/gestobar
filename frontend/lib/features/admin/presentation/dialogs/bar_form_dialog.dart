import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestobar/core/network/dio_client.dart';
import 'package:gestobar/core/widgets/custom_toast.dart';
import 'package:gestobar/core/widgets/responsive_modal.dart';
import 'package:gestobar/core/widgets/styled_text_field.dart';
import 'package:gestobar/core/utils/currency_helper.dart';
import 'package:gestobar/features/admin/data/models/bar_model.dart';
import 'package:dio/dio.dart';

class BarFormDialog extends ConsumerStatefulWidget {
  final BarModel? bar; // Si es null, es modo Creación
  final VoidCallback onSaved;

  const BarFormDialog({
    super.key,
    this.bar,
    required this.onSaved,
  });

  @override
  ConsumerState<BarFormDialog> createState() => _BarFormDialogState();
}

class _BarFormDialogState extends ConsumerState<BarFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de los campos simplificados del Bar
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _ciudadCtrl;

  bool _moduloDamasActivo = true;
  bool _estado = true;
  String? _selectedOwnerId;

  // Divisas soportadas oficiales (Sincronizadas con OperacionesTab)
  final List<String> _currenciesIso = [
    'USD', 'BOB', 'BRL', 'CLP', 'COP', 'CRC', 'CUP', 'DOP', 'EUR', 'GTQ',
    'HNL', 'MXN', 'NIO', 'PAB', 'PEN', 'PYG', 'SVC', 'UYU', 'VES'
  ];

  String _selectedCurrencyIso = 'BOB';
  String _selectedCurrencySymbol = 'Bs';

  // Zonas horarias oficiales (Sincronizadas con OperacionesTab)
  final List<String> _timezones = [
    'America/New_York', 'America/Chicago', 'America/Denver', 'America/Los_Angeles',
    'Europe/Madrid', 'Atlantic/Canary', 'America/La_Paz', 'America/Lima',
    'America/Santiago', 'America/Bogota', 'America/Mexico_City', 'America/Monterrey',
    'America/Tijuana', 'America/Argentina/Buenos_Aires', 'America/Sao_Paulo',
    'America/Manaus', 'America/Costa_Rica', 'America/El_Salvador', 'America/Guatemala',
    'America/Tegucigalpa', 'America/Managua', 'America/Panama', 'America/Asuncion',
    'America/Caracas', 'America/Montevideo', 'America/Guayaquil', 'America/Santo_Domingo',
    'America/Puerto_Rico', 'America/Havana'
  ];
  String _selectedTimezone = 'America/La_Paz';

  // Estado de caja abierta
  bool _isCajaAbierta = false;
  bool _isLoadingCajaState = false;

  // Listas cargadas dinámicamente
  List<dynamic> _adminsList = [];
  bool _isLoadingAdmins = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.bar?.nombre ?? '');
    _ciudadCtrl = TextEditingController(text: widget.bar?.ciudad ?? '');

    if (widget.bar != null) {
      _moduloDamasActivo = widget.bar!.moduloDamasActivo;
      _estado = widget.bar!.estado;
      _selectedCurrencyIso = widget.bar!.monedaIso;
      _selectedCurrencySymbol = widget.bar!.monedaSimbolo;
      _selectedTimezone = widget.bar!.timezone;
      _checkCajaStatus();
    }

    _loadAdmins();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _ciudadCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkCajaStatus() async {
    setState(() => _isLoadingCajaState = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/cajas/estado', options: Options(
        headers: {
          'x-bar-id': widget.bar!.id,
        },
      ));
      setState(() {
        _isCajaAbierta = res.data['abierta'] == true;
        _isLoadingCajaState = false;
      });
    } catch (e) {
      setState(() => _isLoadingCajaState = false);
      debugPrint('Error al verificar estado de caja en BarFormDialog: $e');
    }
  }

  Future<void> _loadAdmins() async {
    try {
      final dio = ref.read(dioProvider);

      // Cargar todos los usuarios del sistema
      final usersRes = await dio.get('/users');
      final List<dynamic> users = usersRes.data ?? [];

      setState(() {
        // Filtrar usuarios que pertenecen al rol ADMIN
        _adminsList = users.where((u) {
          final rol = u['rol'];
          return rol != null && rol['nombre'].toString().toUpperCase() == 'ADMIN';
        }).toList();

        if (_adminsList.isNotEmpty) {
          _selectedOwnerId = _adminsList.first['id'];
        }
        _isLoadingAdmins = false;
      });
    } catch (e) {
      setState(() => _isLoadingAdmins = false);
      if (mounted) {
        CustomToast.show(context, message: 'Error al cargar lista de administradores', type: ToastType.error);
      }
    }
  }

  // Generador automático de slug a partir del nombre del bar
  String _slugify(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '') // Quitar caracteres especiales
        .replaceAll(RegExp(r'\s+'), '-')         // Reemplazar espacios por guiones
        .replaceAll(RegExp(r'-+'), '-');         // Reducir guiones repetidos
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() != true) return;
    
    if (_selectedOwnerId == null && widget.bar == null) {
      CustomToast.show(context, message: 'Debes seleccionar un Administrador dueño del bar', type: ToastType.error);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dio = ref.read(dioProvider);
      String? ownerId = _selectedOwnerId;

      // Armar payload simplificado del Bar
      final String barName = _nombreCtrl.text.trim();
      final String generatedSlug = _slugify(barName);

      final barPayload = {
        'nombre': barName,
        'slug': generatedSlug,
        'ciudad': _ciudadCtrl.text.trim(),
        'modulo_damas_activo': _moduloDamasActivo,
        'estado': _estado,
        'moneda_simbolo': _selectedCurrencySymbol,
        'moneda_iso': _selectedCurrencyIso,
        'timezone': _selectedTimezone,
        if (widget.bar == null) ...{
          // Valores por defecto únicamente en creación
          'direccion': '',
          'comision_porcentaje': _moduloDamasActivo ? 50.0 : null,
          if (ownerId != null) 'owner_id': ownerId,
        }
      };

      if (widget.bar == null) {
        // Crear Bar nuevo
        await dio.post('/bars', data: barPayload);
        if (mounted) {
          CustomToast.show(context, message: 'Sucursal registrada con éxito', type: ToastType.success);
        }
      } else {
        // Actualizar Bar existente (excluyendo campos de creación y owner_id)
        await dio.patch('/bars/${widget.bar!.id}', data: barPayload);
        if (mounted) {
          CustomToast.show(context, message: 'Sucursal actualizada con éxito', type: ToastType.success);
        }
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        String errorMsg = e.toString().replaceAll('Exception: ', '');
        if (e is DioException) {
          final serverMessage = e.response?.data?['message'];
          if (serverMessage != null) errorMsg = serverMessage.toString();
        }
        CustomToast.show(context, message: 'Fallo al guardar sucursal: $errorMsg', type: ToastType.error);
      }
    }
  }

  Widget _buildNombreField() {
    return StyledTextField(
      controller: _nombreCtrl,
      hintText: 'Nombre del Bar',
      icon: Icons.storefront,
      validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
    );
  }

  Widget _buildCiudadField() {
    return StyledTextField(
      controller: _ciudadCtrl,
      hintText: 'Ciudad',
      icon: Icons.location_city,
      validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
    );
  }

  Widget _buildCurrencyDropdown() {
    final bool blockDropdown = widget.bar != null && _isCajaAbierta;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: blockDropdown ? const Color(0xFF1E2024) : const Color(0xFF22252A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _selectedCurrencyIso,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E2024),
          style: GoogleFonts.inter(
            color: blockDropdown ? Colors.white30 : Colors.white,
            fontSize: 13,
          ),
          decoration: const InputDecoration(
            icon: Icon(Icons.payments, color: Colors.white30, size: 16),
            border: InputBorder.none,
          ),
          items: _currenciesIso.map((iso) {
            return DropdownMenuItem<String>(
              value: iso,
              child: Text(
                CurrencyHelper.getCurrencyLabel(iso),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: blockDropdown
              ? null
              : (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCurrencyIso = val;
                      _selectedCurrencySymbol = CurrencyHelper.getSymbolFromIso(val);
                    });
                  }
                },
        ),
      ),
    );
  }

  Widget _buildTimezoneField() {
    final bool blockDropdown = widget.bar != null && _isCajaAbierta;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: blockDropdown ? const Color(0xFF1E2024) : const Color(0xFF22252A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _selectedTimezone,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E2024),
          style: GoogleFonts.inter(
            color: blockDropdown ? Colors.white30 : Colors.white,
            fontSize: 13,
          ),
          decoration: const InputDecoration(
            icon: Icon(Icons.access_time, color: Colors.white30, size: 16),
            border: InputBorder.none,
          ),
          items: _timezones.map((tz) {
            return DropdownMenuItem<String>(
              value: tz,
              child: Text(
                tz,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: blockDropdown
              ? null
              : (val) {
                  if (val != null) setState(() => _selectedTimezone = val);
                },
        ),
      ),
    );
  }

  Widget _buildModuloDamasToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF22252A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Módulo de Damas',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
          Switch(
            value: _moduloDamasActivo,
            activeColor: const Color(0xFF00F0FF),
            activeTrackColor: const Color(0xFF00F0FF).withOpacity(0.3),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.white10,
            onChanged: (val) => setState(() => _moduloDamasActivo = val),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF22252A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Estado Sucursal Activa',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Si se desactiva, se bloqueará el acceso al POS y turnos.',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: _estado,
            activeColor: const Color(0xFF00F0FF),
            activeTrackColor: const Color(0xFF00F0FF).withOpacity(0.3),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.white10,
            onChanged: (val) => setState(() => _estado = val),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerDropdown() {
    if (_adminsList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF22252A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orangeAccent, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No hay administradores creados. Crea uno primero en la pestaña de Administradores.',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF22252A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _selectedOwnerId,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E2024),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          decoration: const InputDecoration(
            icon: Icon(Icons.person, color: Colors.white30, size: 16),
            border: InputBorder.none,
          ),
          items: _adminsList.map((admin) {
            return DropdownMenuItem<String>(
              value: admin['id'],
              child: Text(
                '${admin['nombre']} ${admin['apellido']} (@${admin['username']})',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedOwnerId = val);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isTablet = MediaQuery.of(context).size.width >= 720;

    return ResponsiveModalContainer(
      title: widget.bar == null ? 'Registrar Sucursal' : 'Editar Sucursal',
      subtitle: widget.bar == null ? 'Agrega una nueva sucursal SaaS al sistema' : 'Modifica los parámetros de configuración',
      isDialog: isTablet,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white10),
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
            onPressed: _isSaving || _isLoadingAdmins || _isLoadingCajaState ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F0FF),
              foregroundColor: const Color(0xFF0C0E12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0C0E12)),
                  )
                : Text(
                    widget.bar == null ? 'REGISTRAR' : 'GUARDAR CAMBIOS',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      child: (_isLoadingAdmins || _isLoadingCajaState)
          ? const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: Color(0xFF00F0FF))))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner de Advertencia si la caja está abierta (Edición)
                    if (widget.bar != null && _isCajaAbierta) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_clock, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Existe una caja abierta actualmente en esta sucursal. Para evitar descuadres en el arqueo, debes cerrarla antes de modificar la Moneda o Zona Horaria.',
                                style: GoogleFonts.inter(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    Text('DATOS GENERALES DE LA SUCURSAL', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF00F0FF))),
                    const SizedBox(height: 12),
                    
                    _buildNombreField(),
                    const SizedBox(height: 12),
                    
                    _buildCiudadField(),
                    const SizedBox(height: 20),

                    // Divisa y Zona Horaria (Visibles en creación y edición)
                    Text('DIVISA Y ZONA HORARIA', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF00F0FF))),
                    const SizedBox(height: 12),

                    if (isTablet)
                      Row(
                        children: [
                          Expanded(child: _buildCurrencyDropdown()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTimezoneField()),
                        ],
                      )
                    else ...[
                      _buildCurrencyDropdown(),
                      const SizedBox(height: 12),
                      _buildTimezoneField(),
                    ],
                    const SizedBox(height: 20),

                    Text('CONFIGURACIÓN OPERATIVA', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF00F0FF))),
                    const SizedBox(height: 12),

                    _buildModuloDamasToggle(),
                    const SizedBox(height: 12),

                    _buildEstadoToggle(),
                    const SizedBox(height: 20),

                    // Dropdown de Dueño / Admin del Bar (Únicamente en creación)
                    if (widget.bar == null) ...[
                      Text('ADMINISTRADOR / DUEÑO DEL BAR', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF00F0FF))),
                      const SizedBox(height: 12),
                      _buildOwnerDropdown(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
