import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../../../core/widgets/custom_toast.dart';

/// 🎨 Login View - Estética Premium Ultra-refinada
class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).login(
            _usernameController.text.trim(),
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthError) {
        CustomToast.show(
          context,
          message: next.message,
          type: ToastType.error,
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cabecera / Marca
                    Center(
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/icon/isotipo.png',
                            width: 72.0,
                            height: 72.0,
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            'Gestobar',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            'Inicia sesión para comenzar',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40.0),

                    // Mensaje de Error si existiera
                    if (authState is AuthError) ...[
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.1),
                          border: Border.all(
                            color: theme.colorScheme.error,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: theme.colorScheme.error),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Text(
                                authState.message,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20.0),
                    ],

                    // Input de Usuario
                    Text(
                      'Usuario o Celular',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _usernameController,
                      keyboardType: TextInputType.text,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'ej. juanperez, 985623147',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: theme.colorScheme.outline, width: 1.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: theme.colorScheme.error, width: 1.0),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: theme.colorScheme.error, width: 2.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa tu usuario';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24.0),

                    // Input de Contraseña
                    Text(
                      'Contraseña',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: theme.colorScheme.outline, width: 1.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: theme.colorScheme.error, width: 1.0),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: theme.colorScheme.error, width: 2.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu contraseña';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32.0),

                    // Botón de Inicio de Sesión Tactil Grande
                    ElevatedButton(
                      onPressed: authState is AuthLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.brightness == Brightness.dark
                            ? const Color(0xFF261A00) // on-primary-fixed dark color
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 4.0,
                        shadowColor: theme.colorScheme.primary.withOpacity(0.4),
                      ),
                      child: authState is AuthLoading
                          ? const SizedBox(
                              width: 24.0,
                              height: 24.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.login),
                                const SizedBox(width: 12.0),
                                Text(
                                  'Ingresar al Sistema',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.brightness == Brightness.dark
                                        ? const Color(0xFF261A00)
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
