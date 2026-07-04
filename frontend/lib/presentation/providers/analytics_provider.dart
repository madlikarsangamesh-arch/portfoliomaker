import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:portfolio_ai/config/constants.dart';

class AnalyticsState {
  final Map<String, dynamic> summary;
  final bool isLoading;
  final String? error;

  AnalyticsState({
    this.summary = const {},
    this.isLoading = false,
    this.error,
  });

  AnalyticsState copyWith({
    Map<String, dynamic>? summary,
    bool? isLoading,
    String? error,
  }) {
    return AnalyticsState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  AnalyticsNotifier() : super(AnalyticsState());

  Future<void> loadAnalytics(String portfolioId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseApiUrl}/analytics/summary/$portfolioId'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        state = state.copyWith(summary: data, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to fetch analytics summary');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Network connection failed');
    }
  }
}

final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier();
});
