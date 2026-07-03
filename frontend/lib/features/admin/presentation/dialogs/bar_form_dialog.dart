import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestobar/core/network/dio_client.dart';
import 'package:gestobar/core/widgets/custom_toast.dart';
import 'package:gestobar/core/widgets/responsive_modal.dart';
import 'package:gestobar/core/widgets/styled_text_field.dart';
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

  // Divisas soportadas mapeadas
  final List<Map<String, String>> _currencies = [
    {'iso': 'BOB', 'symbol': 'Bs', 'label': 'Boliviano (BOB - Bs)'},
    {'iso': 'USD', 'symbol': '\$', 'label': 'Dólar (USD - \$)'},
    {'iso': 'EUR', 'symbol': '€', 'label': 'Euro (EUR - €)'},
    {'iso': 'PEN', 'symbol': 'S/.', 'label': 'Sol (PEN - S/.)'},
    {'iso': 'COP', 'symbol': '\$', 'label': 'Peso Colombiano (COP - \$)'},
    {'iso': 'CLP', 'symbol': '\$', 'label': 'Peso Chileno (CLP - \$)'},
    {'iso': 'ARS', 'symbol': '\$', 'label': 'Peso Argentino (ARS - \$)'},
  ];

  String _selectedCurrencyIso = 'BOB';
  String _selectedCurrencySymbol = 'Bs';

  // Zonas horarias
  final List<String> _timezones = [
    'America/La_Paz',
    'America/Bogota',
    'America/Lima',
    'America/Santiago',
    'America/Caracas',
    'America/Mexico_City',
    'America/Argentina/Buenos_Aires',
    'America/Sao_Paulo',
    'Europe/Madrid',
  ];
  String _selectedTimezone = 'America/La_Paz';

  // Listas cargadas dinámicamente
  List<dynamic> _adminsList = [];
  String? _adminRoleId;
  bool _isLoadingAdmins = true;
  bool _isSaving = false;

  // Variables para sub-formulario de creación rápida de Administrador
  bool _showCreateAdminForm = false;
  final _adminFormKey = GlobalKey<FormState>();
  final _adminNameCtrl = TextEditingController();
  final _adminLastNameCtrl = TextEditingController();
  final _adminUsernameCtrl = TextEditingController();
  final _adminPasswordCtrl = TextEditingController();
  final _adminCelularCtrl = TextEditingController();

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
    }

    _loadAdmins();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _ciudadCtrl.dispose();
    _adminNameCtrl.dispose();
    _adminLastNameCtrl.dispose();
    _adminUsernameCtrl.dispose();
    _adminPasswordCtrl.dispose();
    _adminCelularCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAdmins() async {
    try {
      final dio = ref.read(dioProvider);
      
      // 1. Cargar roles para buscar el ID de 'ADMIN'
      final rolesRes = await dio.get('/roles');
      final List<dynamic> roles = rolesRes.data ?? [];
      for (var r in roles) {
        if (r['nombre'].toString().toUpperCase() == 'ADMIN') {
          _adminRoleId = r['id'];
          break;
        }
      }

      // 2. Cargar todos los usuarios del sistema
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
    
    // Si se activa creación de admin rápido, validar sub-formulario primero
    if (_showCreateAdminForm) {
      if (_adminFormKey.currentState?.validate() != true) return;
    } else {
      if (_selectedOwnerId == null && widget.bar == null) {
        CustomToast.show(context, message: 'Debes seleccionar un Administrador dueño del bar', type: ToastType.error);
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final dio = ref.read(dioProvider);
      String? ownerId = _selectedOwnerId;

      // 1. Si se requiere crear un administrador rápido
      if (_showCreateAdminForm) {
        if (_adminRoleId == null) {
          throw Exception('No se pudo encontrar el ID del rol de Administrador. Contacte a soporte.');
        }

        final newUserPayload = {
          'username': _adminUsernameCtrl.text.trim(),
          'password': _adminPasswordCtrl.text.trim(),
          'nombre': _adminNameCtrl.text.trim(),
          'apellido': _adminLastNameCtrl.text.trim(),
          'celular': _adminCelularCtrl.text.trim(),
          'rol_id': _adminRoleId,
          'estado': true,
        };

        final newUserRes = await dio.post('/users', data: newUserPayload);
        ownerId = newUserRes.data['id'];
      }

      // 2. Armar payload simplificado del Bar
      final String barName = _nombreCtrl.text.trim();
      final String generatedSlug = _slugify(barName);

      final barPayload = {
        'nombre': barName,
        'slug': generatedSlug,
        'ciudad': _ciudadCtrl.text.trim(),
        'modulo_damas_activo': _moduloDamasActivo,
        'estado': _estado,
        if (widget.bar == null) ...{
          // Valores seleccionados y por defecto obligatorios al crear
          'direccion': '',
          'moneda_simbolo': _selectedCurrencySymbol,
          'moneda_iso': _selectedCurrencyIso,
          'timezone': _selectedTimezone,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF22252A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _selectedCurrencyIso,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E2024),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          decoration: const InputDecoration(
            icon: Icon(Icons.payments, color: Colors.white30, size: 16),
            border: InputBorder.none,
          ),
          items: _currencies.map((c) {
            return DropdownMenuItem<String>(
              value: c['iso'],
              child: Text(
                c['label']!,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedCurrencyIso = val;
                final selectedMap = _currencies.firstWhere((c) => c['iso'] == val);
                _selectedCurrencySymbol = selectedMap['symbol']!;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildTimezoneField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF22252A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _selectedTimezone,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E2024),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
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
          onChanged: (val) {
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
    return Row(
      children: [
        Expanded(
          child: Container(
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
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.person_add, color: Color(0xFF00F0FF)),
          tooltip: 'Nuevo Admin',
          onPressed: () => setState(() => _showCreateAdminForm = true),
        ),
      ],
    );
  }

  Widget _buildNewAdminForm(bool isTablet) {
    return Form(
      key: _adminFormKey,
      child: Column(
        children: [
          if (isTablet)
            Row(
              children: [
                Expanded(
                  child: StyledTextField(
                    controller: _adminNameCtrl,
                    hintText: 'Nombre',
                    icon: Icons.person,
                    validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StyledTextField(
                    controller: _adminLastNameCtrl,
                    hintText: 'Apellido',
                    icon: Icons.person_outline,
                    validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                  ),
                ),
              ],
            )
          else ...[
            StyledTextField(
              controller: _adminNameCtrl,
              hintText: 'Nombre',
              icon: Icons.person,
              validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 8),
            StyledTextField(
              controller: _adminLastNameCtrl,
              hintText: 'Apellido',
              icon: Icons.person_outline,
              validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
            ),
          ],
          const SizedBox(height: 8),
          StyledTextField(
            controller: _adminUsernameCtrl,
            hintText: 'Nombre de usuario (ej: admin_la_paz)',
            icon: Icons.alternate_email,
            validator: (val) {
              if (val == null || val.isEmpty) return 'Requerido';
              if (val.length < 4) return 'Mínimo 4 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 8),
          StyledTextField(
            controller: _adminPasswordCtrl,
            hintText: 'Contraseña para el administrador',
            isPassword: true,
            icon: Icons.lock,
            validator: (val) {
              if (val == null || val.isEmpty) return 'Requerido';
              if (val.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 8),
          StyledTextField(
            controller: _adminCelularCtrl,
            hintText: 'Número de celular (opcional)',
            icon: Icons.phone,
          ),
        ],
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
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isSaving || _isLoadingAdmins ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7000FF),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(widget.bar == null ? 'Guardar' : 'Actualizar', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      child: _isLoadingAdmins
          ? const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: Color(0xFF00F0FF))))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DATOS GENERALES DE LA SUCURSAL', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF00F0FF), letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    
                    _buildNombreField(),
                    const SizedBox(height: 12),
                    
                    _buildCiudadField(),
                    const SizedBox(height: 20),

                    // Divisa y Zona Horaria (Únicamente visibles al crear la sucursal)
                    if (widget.bar == null) ...[
                      Text('DIVISA Y ZONA HORARIA', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF00F0FF), letterSpacing: 0.5)),
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
                    ],

                    Text('CONFIGURACIÓN OPERATIVA', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF00F0FF), letterSpacing: 0.5)),
                    const SizedBox(height: 12),

                    _buildModuloDamasToggle(),
                    const SizedBox(height: 12),

                    _buildEstadoToggle(),
                    const SizedBox(height: 20),

                    // Dropdown de Dueño / Admin del Bar (Únicamente en creación)
                    if (widget.bar == null) ...[
                      Text('ADMINISTRADOR / DUEÑO DEL BAR', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF00F0FF), letterSpacing: 0.5)),
                      const SizedBox(height: 12),
                      
                      if (!_showCreateAdminForm) ...[
                        _buildOwnerDropdown(),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Registrando Nuevo Admin...', style: TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic)),
                            TextButton.icon(
                              icon: const Icon(Icons.list, size: 14, color: Color(0xFF00F0FF)),
                              label: const Text('Elegir de la lista', style: TextStyle(color: Color(0xFF00F0FF), fontSize: 12)),
                              onPressed: () => setState(() => _showCreateAdminForm = false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        _buildNewAdminForm(isTablet),
                      ],
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
