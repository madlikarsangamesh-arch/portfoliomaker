import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:portfolio_ai/config/constants.dart';

class AdminState {
  final Map<String, dynamic> globalStats;
  final List<dynamic> users;
  final List<dynamic> portfolios;
  final List<dynamic> templates;
  final bool isLoading;
  final String? error;

  AdminState({
    this.globalStats = const {},
    this.users = const [],
    this.portfolios = const [],
    this.templates = const [],
    this.isLoading = false,
    this.error,
  });

  AdminState copyWith({
    Map<String, dynamic>? globalStats,
    List<dynamic>? users,
    List<dynamic>? portfolios,
    List<dynamic>? templates,
    bool? isLoading,
    String? error,
  }) {
    return AdminState(
      globalStats: globalStats ?? this.globalStats,
      users: users ?? this.users,
      portfolios: portfolios ?? this.portfolios,
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  AdminNotifier() : super(AdminState());

  Future<void> loadSystemOverview() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final statsRes = await http.get(Uri.parse('${AppConstants.baseApiUrl}/admin/stats'));
      final usersRes = await http.get(Uri.parse('${AppConstants.baseApiUrl}/admin/users'));
      final portRes = await http.get(Uri.parse('${AppConstants.baseApiUrl}/admin/portfolios'));
      final tempRes = await http.get(Uri.parse('${AppConstants.baseApiUrl}/admin/templates'));

      if (statsRes.statusCode == 200 && usersRes.statusCode == 200) {
        state = AdminState(
          globalStats: json.decode(statsRes.body),
          users: json.decode(usersRes.body),
          portfolios: json.decode(portRes.body),
          templates: json.decode(tempRes.body),
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed admin dashboard query');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Connection failed');
    }
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier();
});
