import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_helper.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_state.dart';

// Provider global para consultar las sucursales del sistema
final barsFutureProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.bars);
  return response.data as List<dynamic>;
});

class BarSelectorView extends ConsumerWidget {
  const BarSelectorView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final barsAsync = ref.watch(barsFutureProvider);
    final authState = ref.watch(authProvider) as AuthAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestobar Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.background,
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20.0),
                Text(
                  'Hola, ${authState.user.nombre}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  'Selecciona una sucursal / bar para ingresar a la terminal operativa:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32.0),
                Expanded(
                  child: barsAsync.when(
                    data: (bars) {
                      if (bars.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.storefront,
                                size: 64.0,
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16.0),
                              Text(
                                'No hay sucursales registradas aún.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 350.0,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: 1.4,
                        ),
                        itemCount: bars.length,
                        itemBuilder: (context, index) {
                          final bar = bars[index];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                              side: BorderSide(
                                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                              ),
                            ),
                            elevation: 0,
                            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                            child: InkWell(
                              onTap: () {
                                ref.read(authProvider.notifier).selectBar(bar['id'] as String);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8.0),
                                          ),
                                          child: Icon(
                                            Icons.local_bar,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                        Text(
                                          CurrencyHelper.cleanCurrencySymbol(
                                            bar['moneda_simbolo'],
                                            bar['moneda_iso'],
                                          ),
                                          style: theme.textTheme.labelMedium?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bar['nombre'] ?? 'Sin Nombre',
                                          style: theme.textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18.0,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4.0),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 14.0,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 4.0),
                                            Expanded(
                                              child: Text(
                                                bar['ciudad'] ?? 'Ciudad',
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (err, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48.0,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            'Error al cargar las sucursales',
                            style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            err.toString(),
                            style: theme.textTheme.labelSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: () => ref.refresh(barsFutureProvider),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
