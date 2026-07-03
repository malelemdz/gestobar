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

  // Controladores de los campos del Bar
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _slugCtrl;
  late final TextEditingController _ciudadCtrl;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _simboloCtrl;
  late final TextEditingController _isoCtrl;
  late final TextEditingController _comisionCtrl;

  String _selectedTimezone = 'America/La_Paz';
  bool _moduloDamasActivo = true;
  bool _estado = true;
  String? _selectedOwnerId;

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

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.bar?.nombre ?? '');
    _slugCtrl = TextEditingController(text: widget.bar?.slug ?? '');
    _ciudadCtrl = TextEditingController(text: widget.bar?.ciudad ?? '');
    _direccionCtrl = TextEditingController(text: widget.bar?.direccion ?? '');
    _simboloCtrl = TextEditingController(text: widget.bar?.monedaSimbolo ?? 'Bs');
    _isoCtrl = TextEditingController(text: widget.bar?.monedaIso ?? 'BOB');
    _comisionCtrl = TextEditingController(text: widget.bar != null ? widget.bar!.comisionPorcentaje.toStringAsFixed(0) : '50');

    if (widget.bar != null) {
      _selectedTimezone = widget.bar!.timezone;
      _moduloDamasActivo = widget.bar!.moduloDamasActivo;
      _estado = widget.bar!.estado;
    }

    _loadAdmins();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _slugCtrl.dispose();
    _ciudadCtrl.dispose();
    _direccionCtrl.dispose();
    _simboloCtrl.dispose();
    _isoCtrl.dispose();
    _comisionCtrl.dispose();
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

      // 2. Armar payload del Bar
      final double comisionVal = double.tryParse(_comisionCtrl.text) ?? 50.0;
      final barPayload = {
        'nombre': _nombreCtrl.text.trim(),
        'slug': _slugCtrl.text.trim().toLowerCase(),
        'ciudad': _ciudadCtrl.text.trim(),
        'direccion': _direccionCtrl.text.trim(),
        'moneda_simbolo': _simboloCtrl.text.trim(),
        'moneda_iso': _isoCtrl.text.trim().toUpperCase(),
        'timezone': _selectedTimezone,
        'comision_porcentaje': comisionVal,
        'modulo_damas_activo': _moduloDamasActivo,
        'estado': _estado,
        if (ownerId != null) 'owner_id': ownerId,
      };

      if (widget.bar == null) {
        // Crear Bar nuevo
        await dio.post('/bars', data: barPayload);
        if (mounted) {
          CustomToast.show(context, message: 'Sucursal registrada con éxito', type: ToastType.success);
        }
      } else {
        // Actualizar Bar existente (excluyendo owner_id si no se desea cambiar)
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveModalContainer(
      title: widget.bar == null ? 'Registrar Sucursal' : 'Editar Sucursal',
      subtitle: widget.bar == null ? 'Agrega una nueva sucursal SaaS al sistema' : 'Modifica los parámetros de configuración',
      isDialog: MediaQuery.of(context).size.width >= 720,
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
                    
                    // Nombre del Bar
                    StyledTextField(
                      controller: _nombreCtrl,
                      hintText: 'Nombre del Bar',
                      icon: Icons.storefront,
                      validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    
                    // Tenant Slug
                    StyledTextField(
                      controller: _slugCtrl,
                      hintText: 'Slug único (ej: bar-centro)',
                      icon: Icons.link,
                      enabled: widget.bar == null, // No editar slug de bars creados
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Requerido';
                        if (!RegExp(r'^[a-z0-9\-]+$').hasMatch(val)) return 'Solo letras minúsculas, números y guiones';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Ciudad y Dirección
                    Row(
                      children: [
                        Expanded(
                          child: StyledTextField(
                            controller: _ciudadCtrl,
                            hintText: 'Ciudad',
                            icon: Icons.location_city,
                            validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StyledTextField(
                            controller: _direccionCtrl,
                            hintText: 'Dirección física',
                            icon: Icons.map,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Text('DIVISA Y ZONA HORARIA', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF00F0FF), letterSpacing: 0.5)),
                    const SizedBox(height: 12),

                    // Símbolo Moneda e ISO
                    Row(
                      children: [
                        Expanded(
                          child: StyledTextField(
                            controller: _simboloCtrl,
                            hintText: 'Símbolo Moneda (ej: Bs.)',
                            icon: Icons.attach_money,
                            validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StyledTextField(
                            controller: _isoCtrl,
                            hintText: 'ISO Moneda (ej: BOB)',
                            icon: Icons.payments,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Requerido';
                              if (val.length != 3) return 'Debe tener exactamente 3 caracteres';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Selector de Zona Horaria
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22252A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          value: _selectedTimezone,
                          dropdownColor: const Color(0xFF1E2024),
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            icon: Icon(Icons.access_time, color: Colors.white30, size: 16),
                            border: InputBorder.none,
                          ),
                          items: _timezones.map((tz) {
                            return DropdownMenuItem<String>(
                              value: tz,
                              child: Text(tz),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedTimezone = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text('REGLAS OPERATIVAS Y CONFIGURACIÓN', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF00F0FF), letterSpacing: 0.5)),
                    const SizedBox(height: 12),

                    // Comisión y Modulo Damas
                    Row(
                      children: [
                        Expanded(
                          child: StyledTextField(
                            controller: _comisionCtrl,
                            hintText: '% Comisión por defecto',
                            icon: Icons.percent,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Requerido';
                              final num = int.tryParse(val);
                              if (num == null || num < 0 || num > 100) return 'Entre 0 y 100';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SwitchListTile(
                            title: const Text('Módulo de Damas', style: TextStyle(color: Colors.white, fontSize: 12)),
                            value: _moduloDamasActivo,
                            activeColor: const Color(0xFF00F0FF),
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) => setState(() => _moduloDamasActivo = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Switch Habilitar/Deshabilitar Bar (SaaS Access)
                    SwitchListTile(
                      title: const Text('Estado Sucursal Activa (Acceso SaaS)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Si se desactiva, los empleados no podrán ingresar al POS ni turnos.', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      value: _estado,
                      activeColor: const Color(0xFF00F0FF),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _estado = val),
                    ),
                    const SizedBox(height: 20),

                    // Dropdown de Dueño / Admin del Bar
                    if (widget.bar == null) ...[
                      Text('ADMINISTRADOR / DUEÑO DEL BAR', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF00F0FF), letterSpacing: 0.5)),
                      const SizedBox(height: 12),
                      
                      if (!_showCreateAdminForm) ...[
                        Row(
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
                                    dropdownColor: const Color(0xFF1E2024),
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                    decoration: const InputDecoration(
                                      icon: Icon(Icons.person, color: Colors.white30, size: 16),
                                      border: InputBorder.none,
                                    ),
                                    items: _adminsList.map((admin) {
                                      return DropdownMenuItem<String>(
                                        value: admin['id'],
                                        child: Text('${admin['nombre']} ${admin['apellido']} (@${admin['username']})'),
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
                        ),
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

                        Form(
                          key: _adminFormKey,
                          child: Column(
                            children: [
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
                              ),
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
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
