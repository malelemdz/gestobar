import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/models/analytics_resumen_model.dart';
import '../data/models/product_ranking_model.dart';
import '../data/models/dama_ranking_model.dart';
import '../data/repositories/analytics_repository.dart';

enum AnalyticsDateFilter {
  last7Days,
  last30Days,
  last90Days,
  custom,
}

final analyticsFilterProvider = StateProvider<AnalyticsDateFilter>((ref) => AnalyticsDateFilter.last7Days);

final analyticsDateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final filter = ref.watch(analyticsFilterProvider);
  final now = DateTime.now();

  switch (filter) {
    case AnalyticsDateFilter.last7Days:
      return DateTimeRange(
        start: DateTime(now.year, now.month, now.day - 6),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
    case AnalyticsDateFilter.last30Days:
      return DateTimeRange(
        start: DateTime(now.year, now.month, now.day - 29),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
    case AnalyticsDateFilter.last90Days:
      return DateTimeRange(
        start: DateTime(now.year, now.month, now.day - 89),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
    case AnalyticsDateFilter.custom:
      // Return the current range or keep the 7-day range as default until picker changes it
      return DateTimeRange(
        start: DateTime(now.year, now.month, now.day - 6),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
  }
});

// Controls active tab: 0 = Resumen, 1 = Picos, 2 = Productos, 3 = Staff
final analyticsTabProvider = StateProvider<int>((ref) => 0);

final analyticsResumenProvider = FutureProvider<AnalyticsResumenModel>((ref) async {
  final range = ref.watch(analyticsDateRangeProvider);
  final repo = ref.watch(analyticsRepositoryProvider);

  final startStr = DateFormat('yyyy-MM-ddTHH:mm:ss').format(range.start);
  final endStr = DateFormat('yyyy-MM-ddTHH:mm:ss').format(range.end);

  return repo.getResumenGeneral(startDate: startStr, endDate: endStr);
});

final analyticsProductRankingProvider = FutureProvider<List<ProductRankingModel>>((ref) async {
  final range = ref.watch(analyticsDateRangeProvider);
  final repo = ref.watch(analyticsRepositoryProvider);

  final startStr = DateFormat('yyyy-MM-ddTHH:mm:ss').format(range.start);
  final endStr = DateFormat('yyyy-MM-ddTHH:mm:ss').format(range.end);

  return repo.getRankingProductos(startDate: startStr, endDate: endStr);
});

final analyticsDamaRankingProvider = FutureProvider<List<DamaRankingModel>>((ref) async {
  final range = ref.watch(analyticsDateRangeProvider);
  final repo = ref.watch(analyticsRepositoryProvider);

  final startStr = DateFormat('yyyy-MM-ddTHH:mm:ss').format(range.start);
  final endStr = DateFormat('yyyy-MM-ddTHH:mm:ss').format(range.end);

  return repo.getRankingDamas(startDate: startStr, endDate: endStr);
});
