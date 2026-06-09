import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/models/user_model.dart';
import '../../../admin/providers/staff_provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/widgets/styled_text_field.dart';
import 'reset_password_bottom_sheet.dart';
import '../../../../core/widgets/responsive_modal.dart';
import '../../../../core/widgets/custom_toast.dart';

Future<void> showAddEditStaffDialog({
  required BuildContext context,
  required WidgetRef ref,
  UserModel? user,
}) async {
  final bool isEdit = user != null;
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController(text: user?.nombre);
  final lastNameController = TextEditingController(text: user?.apellido);
  final usernameController = TextEditingController(text: user?.username);
  final passwordController = TextEditingController();
  final phoneController = TextEditingController(text: user?.celular);
  final dniController = TextEditingController(text: user?.identificacion);
  final countryController = TextEditingController(text: user?.nacionalidad ?? 'Bolivia');
  final addressController = TextEditingController(text: user?.direccion);

  String selectedGender = user?.genero ?? 'PREFIERO_NO_DECIRLO';
  String? selectedRoleId = user?.rolId;

  String? localImagePath;
  bool isSaving = false;

  // Get assignable roles
  final rolesList = ref.read(rolesListProvider).value ?? [];

  final bool isTabletLandscape = MediaQuery.of(context).size.width >= 720;

  Widget buildModalContent(BuildContext context, StateSetter setModalState, bool isDialog) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final size = MediaQuery.of(context).size;
    final maxModalHeight = size.height * (isDialog ? 0.85 : 0.9);

    // Dynamically calculate changes in edit mode
    final bool hasChanges = !isEdit ||
        nameController.text.trim() != user.nombre ||
        lastNameController.text.trim() != user.apellido ||
        (usernameController.text.trim().toLowerCase() != user.username.toLowerCase()) ||
        (dniController.text.trim() != (user.identificacion ?? '')) ||
        (phoneController.text.trim() != (user.celular ?? '')) ||
        (countryController.text.trim() != (user.nacionalidad ?? 'Bolivia')) ||
        (addressController.text.trim() != (user.direccion ?? '')) ||
        selectedGender != (user.genero ?? 'PREFIERO_NO_DECIRLO') ||
        selectedRoleId != user.rolId ||
        localImagePath != null;

    final Widget formBody = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Avatar picker with zero latency
                          Center(
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF00F0FF), width: 1.5),
                                  ),
                                  child: CircleAvatar(
                                    radius: 46,
                                    backgroundColor: Colors.black45,
                                    backgroundImage: localImagePath != null
                                        ? FileImage(File(localImagePath!)) as ImageProvider
                                        : (user?.fotoUrl != null && user!.fotoUrl!.isNotEmpty)
                                            ? NetworkImage(ApiConstants.resolveImageUrl(user.fotoUrl)!)
                                            : null,
                                    child: localImagePath == null && (user?.fotoUrl == null || user!.fotoUrl!.isEmpty)
                                        ? const Icon(Icons.person, size: 40, color: Colors.white38)
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: InkWell(
                                    onTap: () async {
                                      final picker = ImagePicker();
                                      final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                                      if (img != null) {
                                        setModalState(() {
                                          localImagePath = img.path;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF00F0FF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Form Fields Layout:
                          // Line 1: Nombre
                          Text(
                            'NOMBRE',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFB9CACB),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          StyledTextField(
                            controller: nameController,
                            hintText: 'Ej. Juan',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El nombre es obligatorio';
                              }
                              return null;
                            },
                            onChanged: (_) => setModalState(() {}),
                          ),
                          const SizedBox(height: 16),

                          // Line 2: Apellido
                          Text(
                            'APELLIDO',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFB9CACB),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          StyledTextField(
                            controller: lastNameController,
                            hintText: 'Ej. Pérez',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                    return 'El apellido es obligatorio';
                              }
                              return null;
                            },
                            onChanged: (_) => setModalState(() {}),
                          ),
                          const SizedBox(height: 16),

                          // Line 3: ROL
                          Text(
                            'ROL',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFB9CACB),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildDropdownField<String>(
                            value: selectedRoleId,
                            dropdownColor: const Color(0xFF1E2024),
                            hint: 'Seleccionar Rol',
                            items: rolesList.map((r) {
                              return DropdownMenuItem(
                                value: r.id,
                                child: Text(r.nombre),
                              );
                            }).toList(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'El rol es obligatorio';
                              }
                              return null;
                            },
                            onChanged: (val) {
                              setModalState(() {
                                selectedRoleId = val;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Line 4: Row with Username & Contraseña
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NOMBRE DE USUARIO',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFFB9CACB),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    StyledTextField(
                                      controller: usernameController,
                                      hintText: 'Ej. juan.perez',
                                      icon: Icons.alternate_email,
                                      enabled: true,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'El nombre de usuario es obligatorio';
                                        }
                                        return null;
                                      },
                                      onChanged: (_) => setModalState(() {}),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CONTRASEÑA',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFFB9CACB),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (isEdit)
                                      StyledTextField(
                                        controller: TextEditingController(text: '••••••••'),
                                        hintText: 'Toca para cambiar',
                                        icon: Icons.lock_outline,
                                        isPassword: true,
                                        readOnly: true,
                                        onTap: () {
                                          showResetPasswordBottomSheet(context: context, ref: ref, user: user);
                                        },
                                      )
                                    else
                                      StyledTextField(
                                        controller: passwordController,
                                        hintText: 'Mínimo 6 caracteres',
                                        icon: Icons.lock_outline,
                                        isPassword: true,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'La contraseña es obligatoria';
                                          }
                                          if (value.length < 6) {
                                            return 'Mínimo 6 caracteres';
                                          }
                                          return null;
                                        },
                                        onChanged: (_) => setModalState(() {}),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Line 5: Row with Celular & DNI
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CELULAR',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFFB9CACB),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    StyledTextField(
                                      controller: phoneController,
                                      hintText: 'Ej. +591 70000000',
                                      icon: Icons.phone_android_outlined,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'El celular es obligatorio';
                                        }
                                        return null;
                                      },
                                      onChanged: (_) => setModalState(() {}),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CÉDULA / DNI',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFFB9CACB),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    StyledTextField(
                                      controller: dniController,
                                      hintText: 'Ej. 1234567',
                                      icon: Icons.badge_outlined,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'El DNI es obligatorio';
                                        }
                                        return null;
                                      },
                                      onChanged: (_) => setModalState(() {}),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Line 6: Row with Nacionalidad & Género
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NACIONALIDAD',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFFB9CACB),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    StyledTextField(
                                      controller: countryController,
                                      hintText: 'Ej. Bolivia',
                                      icon: Icons.flag_outlined,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'La nacionalidad es obligatoria';
                                        }
                                        return null;
                                      },
                                      onChanged: (_) => setModalState(() {}),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'GÉNERO',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFFB9CACB),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _buildDropdownField<String>(
                                      value: selectedGender,
                                      dropdownColor: const Color(0xFF1E2024),
                                      hint: 'Género',
                                      items: const [
                                        DropdownMenuItem(value: 'MASCULINO', child: Text('Masculino')),
                                        DropdownMenuItem(value: 'FEMENINO', child: Text('Femenino')),
                                        DropdownMenuItem(value: 'PREFIERO_NO_DECIRLO', child: Text('Prefiero no decirlo')),
                                      ],
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'El género es obligatorio';
                                        }
                                        return null;
                                      },
                                      onChanged: (val) {
                                        if (val != null) {
                                          setModalState(() {
                                            selectedGender = val;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Line 7: Dirección
                          Text(
                            'DIRECCIÓN',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFB9CACB),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          StyledTextField(
                            controller: addressController,
                            hintText: 'Ej. Av. Siempre Viva 123',
                            icon: Icons.home_outlined,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'La dirección es obligatoria';
                              }
                              return null;
                            },
                            onChanged: (_) => setModalState(() {}),
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
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: hasChanges ? const Color(0xFF00F0FF) : Colors.white.withOpacity(0.08),
            foregroundColor: hasChanges ? const Color(0xFF0C0E12) : Colors.white24,
            disabledBackgroundColor: Colors.white.withOpacity(0.04),
            disabledForegroundColor: Colors.white12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            elevation: 0,
          ),
          onPressed: (isSaving || !hasChanges)
              ? null
              : () async {
                  // Validation
                  if (!formKey.currentState!.validate()) {
                    return;
                  }

                  if (!isEdit && localImagePath == null) {
                    CustomToast.show(
                      context,
                      message: 'Por favor selecciona una foto de perfil',
                      type: ToastType.warning,
                    );
                    return;
                  }

                  setModalState(() {
                    isSaving = true;
                  });

                  try {
                    String? remotePhotoUrl = user?.fotoUrl;

                    // Upload image first if changed
                    if (localImagePath != null) {
                      remotePhotoUrl = await ref
                          .read(staffListProvider.notifier)
                          .uploadPhoto(localImagePath!);
                    }

                    final payload = {
                      'nombre': nameController.text.trim(),
                      'apellido': lastNameController.text.trim(),
                      'username': usernameController.text.trim().toLowerCase(),
                      'rol_id': selectedRoleId,
                      'genero': selectedGender,
                      'celular': phoneController.text.trim(),
                      'identificacion': dniController.text.trim(),
                      'nacionalidad': countryController.text.trim(),
                      'direccion': addressController.text.trim(),
                      if (remotePhotoUrl != null) 'foto_url': remotePhotoUrl,
                    };

                    if (!isEdit && passwordController.text.isNotEmpty) {
                      payload['password'] = passwordController.text;
                    }

                    bool success;
                    if (isEdit) {
                      success = await ref
                          .read(staffListProvider.notifier)
                          .updateStaff(user.id, payload);
                    } else {
                      success = await ref
                          .read(staffListProvider.notifier)
                          .createStaff(payload);
                    }

                    if (success && context.mounted) {
                      CustomToast.show(
                        context,
                        message: isEdit
                            ? 'Usuario actualizado con éxito'
                            : 'Usuario registrado con éxito',
                        type: ToastType.success,
                      );
                      Navigator.pop(context);
                    } else {
                      setModalState(() {
                        isSaving = false;
                      });
                      CustomToast.show(
                        context,
                        message: 'Error al guardar el usuario. Comprueba tus datos.',
                        type: ToastType.error,
                      );
                    }
                  } catch (e) {
                    setModalState(() {
                      isSaving = false;
                    });
                    CustomToast.show(
                      context,
                      message: 'Error: ${e.toString()}',
                      type: ToastType.error,
                    );
                  }
                },
          child: isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
                )
              : Text(
                  isEdit ? 'GUARDAR CAMBIOS' : 'REGISTRAR USUARIO',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );

    return ResponsiveModalContainer(
      title: isEdit ? 'Editar Usuario' : 'Nuevo Usuario',
      isDialog: isDialog,
      footer: footer,
      child: formBody,
    );
  }

  await showResponsiveDialog(
    context: context,
    maxWidth: 550,
    child: StatefulBuilder(
      builder: (context, setModalState) {
        return buildModalContent(context, setModalState, isTabletLandscape);
      },
    ),
  );
}

Widget _buildDropdownField<T>({
  required T? value,
  required Color dropdownColor,
  required String hint,
  required List<DropdownMenuItem<T>> items,
  required void Function(T?) onChanged,
  String? Function(T?)? validator,
}) {
  return DropdownButtonFormField<T>(
    value: value,
    dropdownColor: dropdownColor,
    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
    decoration: InputDecoration(
      filled: true,
      fillColor: const Color(0xFF22252A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
    ),
    items: items,
    validator: validator,
    onChanged: onChanged,
  );
}
