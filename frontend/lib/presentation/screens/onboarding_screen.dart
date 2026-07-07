import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _flowSelected = false;
  bool _isExtracting = false;
  int _currentStep = 0; // Steps 0 to 8 after selecting flow
  
  // Form controllers
  final _nameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _objectiveCtrl = TextEditingController();
  final _availStatusCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  
  // Dynamic lists
  final List<dynamic> _education = [];
  final List<dynamic> _experience = [];
  final List<dynamic> _projects = [];
  final List<dynamic> _certifications = [];
  final List<dynamic> _extracurriculars = [];
  final List<String> _competitions = [];
  final List<String> _publications = [];
  final List<String> _scholarships = [];
  final Map<String, String> _socialLinks = {};

  // Photo state
  String? _photoUrl;
  Uint8List? _photoBytes;
  String? _photoName;
  int? _photoBeforeSize;
  int? _photoAfterSize;
  bool _isUploadingPhoto = false;

  // Selected Template preferences
  String _selectedTemplate = 'minimal';
  String _cvTemplate = 'classic';
  
  // Resume info
  Uint8List? _resumeBytes;
  String? _resumeName;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    _nameCtrl.text = auth.fullName ?? '';
    _emailCtrl.text = auth.email ?? '';
    _locationCtrl.text = 'Remote';
    _availStatusCtrl.text = 'Open to opportunities';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _bioCtrl.dispose();
    _objectiveCtrl.dispose();
    _availStatusCtrl.dispose();
    _skillsCtrl.dispose();
    super.dispose();
  }

  void _onUploadCvFlowSelected() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _resumeBytes = result.files.single.bytes;
        _resumeName = result.files.single.name;
        _isExtracting = true;
        _flowSelected = true;
      });

      // Call API to parse resume
      final extractedProfile = await ref.read(portfolioProvider.notifier).extractResume(
        bytes: _resumeBytes!,
        filename: _resumeName!,
      );

      if (extractedProfile != null) {
        setState(() {
          _nameCtrl.text = extractedProfile['full_name'] ?? _nameCtrl.text;
          _titleCtrl.text = extractedProfile['professional_title'] ?? '';
          _emailCtrl.text = extractedProfile['email'] ?? _emailCtrl.text;
          _phoneCtrl.text = extractedProfile['phone'] ?? '';
          _locationCtrl.text = extractedProfile['location'] ?? _locationCtrl.text;
          _bioCtrl.text = extractedProfile['about_me'] ?? '';
          _objectiveCtrl.text = extractedProfile['career_objective'] ?? '';
          
          final skillsList = extractedProfile['skills'] as List? ?? [];
          _skillsCtrl.text = skillsList.join(', ');

          _education.addAll(extractedProfile['education'] as List? ?? []);
          _experience.addAll(extractedProfile['experience'] as List? ?? []);
          _projects.addAll(extractedProfile['projects'] as List? ?? []);
          _certifications.addAll(extractedProfile['certifications'] as List? ?? []);
          _extracurriculars.addAll(extractedProfile['extracurriculars'] as List? ?? []);
          _competitions.addAll(List<String>.from(extractedProfile['competitions'] ?? []));
          _publications.addAll(List<String>.from(extractedProfile['publications'] ?? []));
          _scholarships.addAll(List<String>.from(extractedProfile['scholarships'] ?? []));
          _socialLinks.addAll(Map<String, String>.from(extractedProfile['social_links'] ?? {}));
          
          _photoUrl = extractedProfile['profile_photo_url'];
          _isExtracting = false;
        });
      } else {
        setState(() {
          _isExtracting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to parse resume. Initializing empty manual flow.'),
            backgroundColor: Colors.amberAccent,
          ),
        );
      }
    }
  }

  void _onBuildFromScratchFlowSelected() {
    setState(() {
      _flowSelected = true;
      _currentStep = 0;
    });
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
      }
    }
  }

  void _submitBuildPipeline() async {
    final auth = ref.read(authProvider);
    if (auth.userId == null) return;

    final parsedSkills = _skillsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final profile = {
      'full_name': _nameCtrl.text,
      'professional_title': _titleCtrl.text,
      'email': _emailCtrl.text,
      'phone': _phoneCtrl.text,
      'location': _locationCtrl.text,
      'availability_status': _availStatusCtrl.text,
      'profile_photo_url': _photoUrl,
      'about_me': _bioCtrl.text,
      'career_objective': _objectiveCtrl.text,
      'skills': parsedSkills,
      'education': _education,
      'experience': _experience,
      'projects': _projects,
      'certifications': _certifications,
      'extracurriculars': _extracurriculars,
      'competitions': _competitions,
      'publications': _publications,
      'scholarships': _scholarships,
      'social_links': _socialLinks,
    };

    final design = {
      'template': _selectedTemplate,
      'portfolio_template': _selectedTemplate,
      'cv_template': _cvTemplate,
      'primary_color': '#8B5CF6',
      'secondary_color': '#00FFCC',
      'font': 'Inter',
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
    if (!_flowSelected) {
      return _buildChoiceScreen();
    }

    if (_isExtracting) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.neonCyan),
              const SizedBox(height: 24),
              const Text('AI Agent Parsing CV...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Extracting skills, projects, and work history structure...', style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Step ${_currentStep + 1} of 9: ${_getStepTitle()}', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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

  Widget _buildChoiceScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Portfolio Studio'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.palette_outlined, size: 80, color: AppTheme.neonCyan),
                const SizedBox(height: 24),
                const Text(
                  'Launch Portfolio & CV Builder',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'How would you like to set up your professional profile?',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Choice A
                InkWell(
                  onTap: _onBuildFromScratchFlowSelected,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white10),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withOpacity(0.02),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppTheme.neonPurple,
                          child: Icon(Icons.edit_note, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Build from Scratch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('Manually fill details step-by-step', style: TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white30),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Choice B
                InkWell(
                  onTap: _onUploadCvFlowSelected,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(16),
                      color: AppTheme.neonCyan.withOpacity(0.02),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppTheme.neonCyan,
                          child: Icon(Icons.upload_file, color: Colors.black),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Upload Existing CV', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.neonCyan)),
                              Text('Let AI extract and pre-fill everything in seconds', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.neonCyan),
                      ],
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

  String _getStepTitle() {
    final titles = [
      'Hero & Basic Info',
      'About & Objective',
      'Education Info',
      'Skills Details',
      'Projects Portfolio',
      'Work Experience',
      'Achievements',
      'Aesthetics',
      'Generate & Deploy'
    ];
    return titles[_currentStep];
  }

  Widget _buildProgressIndicator() {
    return LinearProgressIndicator(
      value: (_currentStep + 1) / 9.0,
      backgroundColor: Colors.white10,
      color: AppTheme.neonCyan,
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildHeroStep();
      case 1:
        return _buildAboutStep();
      case 2:
        return _buildEducationStep();
      case 3:
        return _buildSkillsStep();
      case 4:
        return _buildProjectsStep();
      case 5:
        return _buildExperienceStep();
      case 6:
        return _buildAchievementsStep();
      case 7:
        return _buildDesignStep();
      case 8:
        return _buildDeployStep();
      default:
        return Container();
    }
  }

  Widget _buildHeroStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: AppTheme.glassCardBg,
                backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                child: _photoUrl == null ? const Icon(Icons.person, size: 48) : null,
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
          const Center(child: SizedBox(width: 80, child: LinearProgressIndicator(color: AppTheme.neonCyan))),
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
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Professional Title', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextField(controller: _locationCtrl, decoration: const InputDecoration(labelText: 'Location / Base', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextField(controller: _availStatusCtrl, decoration: const InputDecoration(labelText: 'Availability Badge', border: OutlineInputBorder(), hintText: 'Available for hire / Freelance')),
      ],
    );
  }

  Widget _buildAboutStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(controller: _objectiveCtrl, decoration: const InputDecoration(labelText: 'Career Objective', border: OutlineInputBorder())),
        const SizedBox(height: 24),
        TextField(
          controller: _bioCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Biography / Professional Summary',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildEducationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Education', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppTheme.neonCyan),
              onPressed: () => _editEducationDialog(-1, {}),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_education.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No education details added.', style: TextStyle(color: Colors.white38))))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _education.length,
            itemBuilder: (context, idx) {
              final edu = _education[idx];
              return ListTile(
                title: Text(edu['degree'] ?? 'Degree'),
                subtitle: Text(edu['institution'] ?? 'Institution'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _editEducationDialog(idx, edu)),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                      onPressed: () => setState(() => _education.removeAt(idx)),
                    ),
                  ],
                ),
              );
            },
          )
      ],
    );
  }

  void _editEducationDialog(int index, Map<dynamic, dynamic> edu) {
    final instCtrl = TextEditingController(text: edu['institution'] ?? '');
    final degCtrl = TextEditingController(text: edu['degree'] ?? '');
    final gradCtrl = TextEditingController(text: edu['graduation_year'] ?? '');
    final gpaCtrl = TextEditingController(text: edu['gpa'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == -1 ? 'Add Education' : 'Edit Education'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: instCtrl, decoration: const InputDecoration(labelText: 'Institution')),
            TextField(controller: degCtrl, decoration: const InputDecoration(labelText: 'Degree')),
            TextField(controller: gradCtrl, decoration: const InputDecoration(labelText: 'Graduation Year')),
            TextField(controller: gpaCtrl, decoration: const InputDecoration(labelText: 'Grade / CGPA')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newEdu = {
                'institution': instCtrl.text,
                'degree': degCtrl.text,
                'graduation_year': gradCtrl.text,
                'gpa': gpaCtrl.text,
              };
              setState(() {
                if (index == -1) {
                  _education.add(newEdu);
                } else {
                  _education[index] = newEdu;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  Widget _buildSkillsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Technical Skills', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        const Text('Enter your skills separated by commas (e.g. Flutter, Python, Docker, UI Design)', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 24),
        TextField(
          controller: _skillsCtrl,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Python, Flutter, CSS, React...'),
        )
      ],
    );
  }

  Widget _buildProjectsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Projects Showcase', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppTheme.neonCyan),
              onPressed: () => _editProjectDialog(-1, {}),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_projects.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No projects added.', style: TextStyle(color: Colors.white38))))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _projects.length,
            itemBuilder: (context, idx) {
              final proj = _projects[idx];
              return ListTile(
                title: Text(proj['title'] ?? 'Title'),
                subtitle: Text(proj['description'] ?? 'Description'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _editProjectDialog(idx, proj)),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                      onPressed: () => setState(() => _projects.removeAt(idx)),
                    ),
                  ],
                ),
              );
            },
          )
      ],
    );
  }

  void _editProjectDialog(int index, Map<dynamic, dynamic> proj) {
    final titleCtrl = TextEditingController(text: proj['title'] ?? '');
    final descCtrl = TextEditingController(text: proj['description'] ?? '');
    final linkCtrl = TextEditingController(text: proj['link'] ?? '');
    final githubCtrl = TextEditingController(text: proj['github_link'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == -1 ? 'Add Project' : 'Edit Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Project Title')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Project Description')),
            TextField(controller: linkCtrl, decoration: const InputDecoration(labelText: 'Live Demo URL')),
            TextField(controller: githubCtrl, decoration: const InputDecoration(labelText: 'GitHub URL')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newProj = {
                'title': titleCtrl.text,
                'description': descCtrl.text,
                'link': linkCtrl.text,
                'github_link': githubCtrl.text,
                'technologies': proj['technologies'] ?? ['Flutter', 'Python'],
              };
              setState(() {
                if (index == -1) {
                  _projects.add(newProj);
                } else {
                  _projects[index] = newProj;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  Widget _buildExperienceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Work Experience', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppTheme.neonCyan),
              onPressed: () => _editExperienceDialog(-1, {}),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_experience.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No work experiences added.', style: TextStyle(color: Colors.white38))))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _experience.length,
            itemBuilder: (context, idx) {
              final exp = _experience[idx];
              return ListTile(
                title: Text(exp['role'] ?? 'Role'),
                subtitle: Text(exp['company'] ?? 'Company'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _editExperienceDialog(idx, exp)),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                      onPressed: () => setState(() => _experience.removeAt(idx)),
                    ),
                  ],
                ),
              );
            },
          )
      ],
    );
  }

  void _editExperienceDialog(int index, Map<dynamic, dynamic> exp) {
    final companyCtrl = TextEditingController(text: exp['company'] ?? '');
    final roleCtrl = TextEditingController(text: exp['role'] ?? '');
    final startCtrl = TextEditingController(text: exp['start_date'] ?? '');
    final endCtrl = TextEditingController(text: exp['end_date'] ?? '');
    final descCtrl = TextEditingController(text: exp['description'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == -1 ? 'Add Experience' : 'Edit Experience'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Company')),
            TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: 'Role')),
            TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start Date')),
            TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End Date')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description / Achievements')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newExp = {
                'company': companyCtrl.text,
                'role': roleCtrl.text,
                'start_date': startCtrl.text,
                'end_date': endCtrl.text,
                'description': descCtrl.text,
              };
              setState(() {
                if (index == -1) {
                  _experience.add(newExp);
                } else {
                  _experience[index] = newExp;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  Widget _buildAchievementsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Certifications, Competitions & Publications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        TextField(
          controller: _emailCtrl,
          decoration: const InputDecoration(labelText: 'Email Address for Contact', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneCtrl,
          decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _buildDesignStep() {
    final templates = ['minimal', 'corporate', 'creative', 'dark'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Web Portfolio Layout Template', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: templates.map((t) {
            final isSel = _selectedTemplate == t;
            return ChoiceChip(
              label: Text(t.toUpperCase(), style: TextStyle(color: isSel ? Colors.black : Colors.white)),
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
        const Text('Select CV PDF Format Template', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _cvTemplate,
          items: const [
            DropdownMenuItem(value: 'classic', child: Text('CLASSIC FORMAT')),
            DropdownMenuItem(value: 'modern', child: Text('MODERN FORMAT')),
            DropdownMenuItem(value: 'creative', child: Text('CREATIVE FORMAT')),
          ],
          onChanged: (v) {
            setState(() {
              _cvTemplate = v ?? 'classic';
            });
          },
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _buildDeployStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Complete & Ready!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.neonCyan)),
        const SizedBox(height: 12),
        const Text(
          'Your profile data structure is fully constructed. You can now publish your portfolio website or download your structured ATS PDF resume.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 40),
        
        ElevatedButton.icon(
          onPressed: _submitBuildPipeline,
          icon: const Icon(Icons.rocket_launch, color: Colors.black),
          label: const Text('Deploy as Portfolio Website', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.neonCyan,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 16),
        
        OutlinedButton.icon(
          onPressed: () {
            final url = _photoUrl; // fallback or download link
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Building CV... Click Deploy to compile and register download links.')),
            );
          },
          icon: const Icon(Icons.download, color: AppTheme.neonCyan),
          label: const Text('Download CV (PDF)', style: TextStyle(color: AppTheme.neonCyan)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.neonCyan),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
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
              onPressed: () {
                setState(() {
                  _flowSelected = false;
                });
              },
              child: const Text('Change Flow', style: TextStyle(color: Colors.white54)),
            ),
          if (_currentStep < 8)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentStep++;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonCyan,
                foregroundColor: Colors.black,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('Next'),
            ),
        ],
      ),
    );
  }
}
