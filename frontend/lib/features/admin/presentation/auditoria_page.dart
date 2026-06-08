import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shimmer_placeholder.dart';
import '../../caja/providers/caja_provider.dart';
import '../providers/auditoria_provider.dart';
import '../providers/bar_provider.dart';
import 'dialogs/log_detail_bottom_sheet.dart';
import 'widgets/auditoria_filter_capsules.dart';
import 'widgets/auditoria_log_card.dart';

class AuditoriaPage extends ConsumerStatefulWidget {
  const AuditoriaPage({super.key});

  @override
  ConsumerState<AuditoriaPage> createState() => _AuditoriaPageState();
}

class _AuditoriaPageState extends ConsumerState<AuditoriaPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(auditoriaListProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auditoriaState = ref.watch(auditoriaListProvider);
    final currencyIso = ref.watch(currencyIsoProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final barTimezone = ref.watch(barTimezoneProvider);

    return Scaffold(
      backgroundColor: AppTheme.liquidBg,
      body: Column(
        children: [
          // Capsule Filters Horizontal List
          const AuditoriaFilterCapsules(),
          // Log List
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.liquidPrimary,
              backgroundColor: const Color(0xFF1E2024),
              onRefresh: () async {
                await ref.read(auditoriaListProvider.notifier).loadInitial(silent: true);
              },
              child: _buildMainContent(auditoriaState, theme, currencyIso, currencySymbol, barTimezone),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    AuditoriaState state,
    ThemeData theme,
    String currencyIso,
    String currencySymbol,
    String barTimezone,
  ) {
    Widget listWidget;

    if (state.isLoading) {
      listWidget = ListView.builder(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 0.0, bottom: 24.0),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: ShimmerPlaceholder(
            width: double.infinity,
            height: 120,
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),
      );
    } else if (state.errorMessage != null && state.logs.isEmpty) {
      listWidget = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 250,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppTheme.colorDanger.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar la auditoría',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    state.errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (state.logs.isEmpty) {
      listWidget = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 250,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off, size: 64, color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 16),
                Text(
                  'No hay registros de auditoría',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      listWidget = ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 0.0, bottom: 24.0),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        itemCount: state.logs.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < state.logs.length) {
            final log = state.logs[index];
            return InkWell(
              onTap: () => showLogDetail(context, log, currencyIso, currencySymbol, barTimezone),
              borderRadius: BorderRadius.circular(16.0),
              child: AuditoriaLogCard(
                log: log,
                currencyIso: currencyIso,
                currencySymbol: currencySymbol,
                barTimezone: barTimezone,
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: AppTheme.liquidPrimary,
                  ),
                ),
              ),
            );
          }
        },
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: listWidget,
      ),
    );
  }
}
