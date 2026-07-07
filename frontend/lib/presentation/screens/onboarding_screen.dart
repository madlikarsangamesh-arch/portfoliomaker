import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:portfolio_ai/config/theme.dart';
import 'package:portfolio_ai/presentation/providers/auth_provider.dart';
import 'package:portfolio_ai/presentation/providers/portfolio_provider.dart';
import 'package:portfolio_ai/presentation/widgets/glass_card.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0; // 0: Resume, 1: Basic Info, 2: Theme Select
  
  // Data State
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  
  Uint8List? _resumeBytes;
  String? _resumeName;
  
  // Photo State
  Uint8List? _photoBytes;
  String? _photoName;
  String? _photoUrl;
  int? _photoBeforeSize;
  int? _photoAfterSize;
  bool _isUploadingPhoto = false;
  
  // Design Preferences
  String _selectedTemplate = 'Minimal';
  String _primaryColor = '#8B5CF6';
  String _secondaryColor = '#00FFCC';

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    _nameController.text = auth.fullName ?? '';
    _emailController.text = auth.email ?? '';
    _titleController.text = 'Fullstack Developer';
    _locationController.text = 'Remote';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _resumeBytes = result.files.single.bytes;
        _resumeName = result.files.single.name;
      });
      
      // Auto-extract mock resume data
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Extracting details from resume...'),
          backgroundColor: AppTheme.neonCyan,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 1000));
      setState(() {
        _titleController.text = "Senior Software Engineer";
        _locationController.text = "San Francisco, CA";
        _currentStep = 1; // Auto advance to Basic Info step
      });
    }
  }

  void _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _isUploadingPhoto = true;
        _photoBytes = result.files.single.bytes;
        _photoName = result.files.single.name;
        _photoBeforeSize = result.files.single.size;
      });
      
      final uploadResult = await ref.read(portfolioProvider.notifier).uploadImage(
        bytes: _photoBytes!,
        filename: _photoName!,
        folder: 'profiles',
      );
      
      if (uploadResult != null && uploadResult['status'] == 'success') {
        setState(() {
          _photoUrl = uploadResult['url'];
          _photoAfterSize = uploadResult['compressed_size'];
          _isUploadingPhoto = false;
        });
      } else {
        setState(() {
          _isUploadingPhoto = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload and compress photo.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _skipAllAndDeploy() {
    // Fill with defaults and launch compilation
    _submitOrchestration();
  }

  void _submitOrchestration() async {
    final auth = ref.read(authProvider);
    if (auth.userId == null) return;

    final profile = {
      'full_name': _nameController.text.isNotEmpty ? _nameController.text : 'Developer',
      'professional_title': _titleController.text.isNotEmpty ? _titleController.text : 'Engineer',
      'email': _emailController.text.isNotEmpty ? _emailController.text : (auth.email ?? 'hello@portfolio.ai'),
      'location': _locationController.text.isNotEmpty ? _locationController.text : 'Remote',
      'profile_photo_url': _photoUrl,
      'about_me': 'Experienced professional creating digital products and building scalable codebases.',
      'skills': ['Flutter', 'Python', 'FastAPI', 'HTML', 'CSS', 'JavaScript'],
      'experience': [
        {
          'company': 'Tech Corp',
          'role': _titleController.text.isNotEmpty ? _titleController.text : 'Engineer',
          'start_date': '2024',
          'end_date': 'Present',
          'description': 'Engineered cloud native products and responsive web applications.',
          'skills_used': ['Flutter', 'Python', 'FastAPI'],
        }
      ],
      'projects': [
        {
          'title': 'AI Agent Compiler',
          'description': 'Orchestrated compiler backend pipelines utilizing Gemini LLM.',
          'technologies': ['Python', 'FastAPI'],
        }
      ]
    };

    final design = {
      'template': _selectedTemplate.toLowerCase(),
      'primary_color': _primaryColor,
      'secondary_color': _secondaryColor,
      'font': 'Inter',
      'inspiration_description': 'Professional step-based onboarding build.',
    };

    Navigator.pushNamed(context, '/wizard');

    await ref.read(portfolioProvider.notifier).buildAndDeployPortfolio(
      userId: auth.userId!,
      profile: profile,
      design: design,
      resumeBytes: _resumeBytes,
      resumeName: _resumeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Portfolio Wizard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _skipAllAndDeploy,
            child: const Text('Skip & Build', style: TextStyle(color: AppTheme.neonCyan)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: _buildProgressIndicator(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: _buildStepContent(),
                    ),
                  ),
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final steps = ['Resume', 'Basic Info', 'Aesthetic'];
    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = _currentStep == index;
        final isCompleted = _currentStep > index;
        return Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: isActive
                    ? AppTheme.neonCyan
                    : isCompleted
                        ? AppTheme.neonPurple
                        : Colors.white10,
                child: isCompleted
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              Text(
                steps[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? AppTheme.neonCyan : Colors.white60,
                ),
              ),
              if (index < steps.length - 1)
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Divider(color: Colors.white10, thickness: 1),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildResumeStep();
      case 1:
        return _buildBasicInfoStep();
      case 2:
        return _buildThemeStep();
      default:
        return Container();
    }
  }

  Widget _buildResumeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Resume (Optional)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.neonCyan),
        ),
        const SizedBox(height: 8),
        const Text(
          'Upload your resume (PDF/TXT) to instantly auto-fill all profile sections, skills, work experiences, and projects.',
          style: TextStyle(fontSize: 14, color: Colors.white70),
        ),
        const SizedBox(height: 32),
        Center(
          child: InkWell(
            onTap: _pickResume,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.neonCyan.withOpacity(0.5), width: 2, style: BorderStyle.solid),
                color: Colors.white.withOpacity(0.02),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_upload_outlined, size: 64, color: AppTheme.neonCyan),
                  const SizedBox(height: 16),
                  Text(
                    _resumeName ?? 'Click to upload PDF or TXT Resume',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (_resumeName == null) ...[
                    const SizedBox(height: 8),
                    const Text('Drag & drop supported on web/desktop', style: TextStyle(fontSize: 11, color: Colors.white38)),
                  ]
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.neonCyan),
        ),
        const SizedBox(height: 24),
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppTheme.glassCardBg,
                backgroundImage: _photoBytes != null ? MemoryImage(_photoBytes!) : null,
                child: _photoBytes == null
                    ? const Icon(Icons.person_outline, size: 48, color: Colors.white30)
                    : null,
              ),
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.neonCyan,
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, size: 14, color: Colors.black),
                  onPressed: _pickPhoto,
                ),
              )
            ],
          ),
        ),
        if (_isUploadingPhoto) ...[
          const SizedBox(height: 8),
          const Center(child: SizedBox(width: 100, child: LinearProgressIndicator(color: AppTheme.neonCyan))),
        ],
        if (_photoBeforeSize != null && _photoAfterSize != null) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Before: ${(_photoBeforeSize! / 1024).toStringAsFixed(1)} KB | Compressed: ${(_photoAfterSize! / 1024).toStringAsFixed(1)} KB',
              style: const TextStyle(fontSize: 11, color: Colors.greenAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
        const SizedBox(height: 24),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Professional Title',
            prefixIcon: Icon(Icons.badge_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Location / Base',
            prefixIcon: Icon(Icons.map_outlined),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeStep() {
    final templates = ['Minimal', 'Corporate', 'Creative', 'Dark'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Design Aesthetic',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.neonCyan),
        ),
        const SizedBox(height: 16),
        const Text(
          'Choose the layout aesthetic that matches your personal brand. You can fully customize color schemes and content later.',
          style: TextStyle(fontSize: 14, color: Colors.white70),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: templates.map((t) {
            final isSel = _selectedTemplate == t;
            return ChoiceChip(
              label: Text(t, style: TextStyle(color: isSel ? Colors.black : Colors.white)),
              selected: isSel,
              selectedColor: AppTheme.neonCyan,
              backgroundColor: AppTheme.glassCardBg,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedTemplate = t;
                  });
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        const Text(
          'Brand Colors',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: const Text('Primary', style: TextStyle(fontSize: 12)),
                subtitle: const Text('Hex: #8B5CF6'),
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.neonPurple,
                  radius: 16,
                ),
              ),
            ),
            Expanded(
              child: ListTile(
                title: const Text('Secondary', style: TextStyle(fontSize: 12)),
                subtitle: const Text('Hex: #00FFCC'),
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.neonCyan,
                  radius: 16,
                ),
              )
            )
          ],
        )
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.glassBorder)),
        color: Colors.transparent,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _currentStep--;
                });
              },
              child: const Text('Back'),
            )
          else
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
              child: const Text('Skip Onboarding', style: TextStyle(color: Colors.white54)),
            ),
          ElevatedButton(
            onPressed: () {
              if (_currentStep < 2) {
                setState(() {
                  _currentStep++;
                });
              } else {
                _submitOrchestration();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonCyan,
              foregroundColor: Colors.black,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: Text(_currentStep == 2 ? 'Assemble & Deploy' : 'Next'),
          ),
        ],
      ),
    );
  }
}
