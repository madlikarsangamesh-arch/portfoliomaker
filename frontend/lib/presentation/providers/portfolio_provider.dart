import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:portfolio_ai/config/constants.dart';
import 'package:portfolio_ai/presentation/widgets/loading_animation.dart';

class PortfolioState {
  final List<dynamic> portfolios;
  final Map<String, dynamic>? activePortfolio;
  final bool isLoading;
  final String? error;
  final List<PipelineStep> pipelineSteps;
  final String? generatedUrl;
  final String? resumeUrl;
  final Map<String, dynamic>? recruiterScorecard;
  final List<dynamic> cvHistory;

  PortfolioState({
    this.portfolios = const [],
    this.activePortfolio,
    this.isLoading = false,
    this.error,
    this.pipelineSteps = const [],
    this.generatedUrl,
    this.resumeUrl,
    this.recruiterScorecard,
    this.cvHistory = const [],
  });

  PortfolioState copyWith({
    List<dynamic>? portfolios,
    Map<String, dynamic>? activePortfolio,
    bool? isLoading,
    String? error,
    List<PipelineStep>? pipelineSteps,
    String? generatedUrl,
    String? resumeUrl,
    Map<String, dynamic>? recruiterScorecard,
    List<dynamic>? cvHistory,
  }) {
    return PortfolioState(
      portfolios: portfolios ?? this.portfolios,
      activePortfolio: activePortfolio ?? this.activePortfolio,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      pipelineSteps: pipelineSteps ?? this.pipelineSteps,
      generatedUrl: generatedUrl ?? this.generatedUrl,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      recruiterScorecard: recruiterScorecard ?? this.recruiterScorecard,
      cvHistory: cvHistory ?? this.cvHistory,
    );
  }
}

class PortfolioNotifier extends StateNotifier<PortfolioState> {
  PortfolioNotifier() : super(PortfolioState());

  Future<void> loadUserPortfolios(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseApiUrl}/portfolios/user/$userId'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        state = state.copyWith(portfolios: data, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to load portfolios');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Connection failed');
    }
  }

  Future<void> fetchPortfolioDetails(String portfolioId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseApiUrl}/portfolios/detail/$portfolioId'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        state = state.copyWith(
          activePortfolio: data,
          generatedUrl: data['deployment_url'],
          resumeUrl: data['profile']['resume_url'],
          recruiterScorecard: data['recruiter_scorecard'],
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to load details');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Connection failed');
    }
  }

  Future<bool> buildAndDeployPortfolio({
    required String userId,
    required Map<String, dynamic> profile,
    required Map<String, dynamic> design,
    Uint8List? resumeBytes,
    String? resumeName,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      pipelineSteps: [
        PipelineStep(title: 'Validating Inputs', description: 'Checking form completeness...', status: 'running'),
        PipelineStep(title: 'Resume Extraction', description: 'Parsing resume text using LLM...', status: 'pending'),
        PipelineStep(title: 'Copywriting Enhancements', description: 'Polishing profile summaries...', status: 'pending'),
        PipelineStep(title: 'Theme Planning', description: 'Selecting palettes & Google Fonts...', status: 'pending'),
        PipelineStep(title: 'Web Compilation', description: 'Synthesizing responsive HTML/CSS/JS...', status: 'pending'),
        PipelineStep(title: 'Recruiter QA check', description: 'Reviewing broken links & accessibility...', status: 'pending'),
        PipelineStep(title: 'Vercel Deployment', description: 'Uploading serverless build packages...', status: 'pending'),
      ],
    );

    try {
      // Simulate progress animations while HTTP executes (real world agent status streams)
      await Future.delayed(const Duration(milliseconds: 800));
      _updateStep(0, 'completed');
      _updateStep(1, 'running');

      final uri = Uri.parse('${AppConstants.baseApiUrl}/portfolios/generate');
      final request = http.MultipartRequest('POST', uri);

      request.fields['user_id'] = userId;
      request.fields['profile_data_str'] = json.encode(profile);
      request.fields['design_prefs_str'] = json.encode(design);

      if (resumeBytes != null && resumeName != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'resume_file',
            resumeBytes,
            filename: resumeName,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Fast forward animations to look satisfying
        _updateStep(1, 'completed');
        _updateStep(2, 'running');
        await Future.delayed(const Duration(milliseconds: 600));
        _updateStep(2, 'completed');
        _updateStep(3, 'running');
        await Future.delayed(const Duration(milliseconds: 500));
        _updateStep(3, 'completed');
        _updateStep(4, 'running');
        await Future.delayed(const Duration(milliseconds: 700));
        _updateStep(4, 'completed');
        _updateStep(5, 'running');
        await Future.delayed(const Duration(milliseconds: 600));
        _updateStep(5, 'completed');
        _updateStep(6, 'running');
        await Future.delayed(const Duration(milliseconds: 1200));
        _updateStep(6, 'completed');

        state = state.copyWith(
          isLoading: false,
          generatedUrl: data['deployment_url'],
          resumeUrl: data['resume_url'],
          recruiterScorecard: data['recruiter_scorecard'],
        );
        return true;
      } else {
        _failAllPendingSteps();
        final errorMsg = json.decode(response.body)['detail'] ?? 'Generation failed';
        state = state.copyWith(isLoading: false, error: errorMsg);
        return false;
      }
    } catch (e) {
      _failAllPendingSteps();
      state = state.copyWith(isLoading: false, error: 'Connection failed during pipeline execution');
      return false;
    }
  }

  void _updateStep(int index, String status) {
    final list = List<PipelineStep>.from(state.pipelineSteps);
    list[index] = PipelineStep(
      title: list[index].title,
      description: list[index].description,
      status: status,
    );
    state = state.copyWith(pipelineSteps: list);
  }

  void _failAllPendingSteps() {
    final list = state.pipelineSteps.map((step) {
      if (step.status == 'running' || step.status == 'pending') {
        return PipelineStep(title: step.title, description: step.description, status: 'failed');
      }
      return step;
    }).toList();
    state = state.copyWith(pipelineSteps: list);
  }

  Future<bool> savePortfolioData({
    required String portfolioId,
    required String userId,
    required Map<String, dynamic> profile,
    required Map<String, dynamic> design,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseApiUrl}/portfolios/save'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'portfolio_id': portfolioId,
          'user_id': userId,
          'profile': profile,
          'design': design,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> uploadImage({
    required Uint8List bytes,
    required String filename,
    String folder = "images",
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseApiUrl}/portfolios/upload-image');
      final request = http.MultipartRequest('POST', uri);
      request.fields['folder'] = folder;
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      // fail silently
    }
    return null;
  }

  Future<String?> polishText({
    required String text,
    String context = "",
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseApiUrl}/portfolios/ai-polish'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'text': text,
          'context': context,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['polished_text'];
      }
    } catch (e) {
      // fail silently
    }
    return null;
  }

  Future<Map<String, dynamic>?> extractResume({
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseApiUrl}/portfolios/extract-resume');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['profile'] as Map<String, dynamic>?;
      }
    } catch (e) {
      // fail silently
    }
    return null;
  }

  Future<void> loadCvHistory(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseApiUrl}/portfolios/cv-history/$userId'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        state = state.copyWith(cvHistory: data);
      }
    } catch (e) {
      // fail silently
    }
  }
}

final portfolioProvider = StateNotifierProvider<PortfolioNotifier, PortfolioState>((ref) {
  return PortfolioNotifier();
});
