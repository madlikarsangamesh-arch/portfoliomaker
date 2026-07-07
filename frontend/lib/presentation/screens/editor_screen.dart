import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:portfolio_ai/config/theme.dart';
import 'package:portfolio_ai/main.dart';
import 'package:portfolio_ai/presentation/providers/auth_provider.dart';
import 'package:portfolio_ai/presentation/providers/portfolio_provider.dart';
import 'package:portfolio_ai/presentation/widgets/glass_card.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _debounce;
  bool _isSaving = false;
  bool _isPublishing = false;
  bool _isPolishing = false;

  // Form states maps
  final Map<String, dynamic> _profile = {};
  final Map<String, dynamic> _design = {};

  // Form Text Controllers to manage state & autosave
  final _nameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _objectiveCtrl = TextEditingController();
  final _availStatusCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Pre-populate fields from active portfolio
    Future.microtask(() {
      final portState = ref.read(portfolioProvider);
      final active = portState.activePortfolio;
      if (active != null) {
        setState(() {
          _profile.addAll(Map<String, dynamic>.from(active['profile'] ?? {}));
          _design.addAll(Map<String, dynamic>.from(active['design'] ?? {}));
          
          _nameCtrl.text = _profile['full_name'] ?? '';
          _titleCtrl.text = _profile['professional_title'] ?? '';
          _emailCtrl.text = _profile['email'] ?? '';
          _phoneCtrl.text = _profile['phone'] ?? '';
          _locationCtrl.text = _profile['location'] ?? '';
          _bioCtrl.text = _profile['about_me'] ?? '';
          _objectiveCtrl.text = _profile['career_objective'] ?? '';
          _availStatusCtrl.text = _profile['availability_status'] ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _debounce?.cancel();
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _bioCtrl.dispose();
    _objectiveCtrl.dispose();
    _availStatusCtrl.dispose();
    super.dispose();
  }

  void _triggerAutosave() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () async {
      _saveDataLocal();
    });
  }

  Future<void> _saveDataLocal() async {
    final auth = ref.read(authProvider);
    final portState = ref.read(portfolioProvider);
    final active = portState.activePortfolio;
    if (auth.userId == null || active == null) return;

    setState(() {
      _isSaving = true;
      
      // Update from controllers
      _profile['full_name'] = _nameCtrl.text;
      _profile['professional_title'] = _titleCtrl.text;
      _profile['email'] = _emailCtrl.text;
      _profile['phone'] = _phoneCtrl.text;
      _profile['location'] = _locationCtrl.text;
      _profile['about_me'] = _bioCtrl.text;
      _profile['career_objective'] = _objectiveCtrl.text;
      _profile['availability_status'] = _availStatusCtrl.text;
    });

    final success = await ref.read(portfolioProvider.notifier).savePortfolioData(
      portfolioId: active['id'],
      userId: auth.userId!,
      profile: _profile,
      design: _design,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  double _calculateCompleteness() {
    int totalPoints = 0;
    if (_nameCtrl.text.isNotEmpty) totalPoints += 10;
    if (_titleCtrl.text.isNotEmpty) totalPoints += 10;
    if (_emailCtrl.text.isNotEmpty) totalPoints += 10;
    if (_bioCtrl.text.isNotEmpty) totalPoints += 10;
    
    final education = _profile['education'] as List? ?? [];
    if (education.isNotEmpty) totalPoints += 15;
    
    final experience = _profile['experience'] as List? ?? [];
    if (experience.isNotEmpty) totalPoints += 15;
    
    final projects = _profile['projects'] as List? ?? [];
    if (projects.isNotEmpty) totalPoints += 15;
    
    final skills = _profile['skills_details'] as List? ?? _profile['skills'] as List? ?? [];
    if (skills.isNotEmpty) totalPoints += 15;

    return totalPoints / 100.0;
  }

  void _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      final uploadRes = await ref.read(portfolioProvider.notifier).uploadImage(
        bytes: result.files.single.bytes!,
        filename: result.files.single.name,
        folder: 'profiles',
      );
      if (uploadRes != null && uploadRes['status'] == 'success') {
        setState(() {
          _profile['profile_photo_url'] = uploadRes['url'];
        });
        _triggerAutosave();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Compressed successfully! Before: ${(result.files.single.size/1024).toStringAsFixed(1)} KB | After: ${(uploadRes['compressed_size']/1024).toStringAsFixed(1)} KB'),
            backgroundColor: Colors.greenAccent,
          ),
        );
      }
    }
  }

  void _runAIPolish(TextEditingController controller, String contextLabel) async {
    if (controller.text.isEmpty) return;
    setState(() {
      _isPolishing = true;
    });

    final polished = await ref.read(portfolioProvider.notifier).polishText(
      text: controller.text,
      context: contextLabel,
    );

    setState(() {
      _isPolishing = false;
    });

    if (polished != null && polished.isNotEmpty && mounted) {
      final originalText = controller.text;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('AI Copywriting Polish'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Original:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white60)),
                const SizedBox(height: 4),
                Text(originalText),
                const SizedBox(height: 16),
                const Text('AI Suggestion:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.neonCyan)),
                const SizedBox(height: 4),
                Text(polished),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  controller.text = polished;
                });
                _triggerAutosave();
                Navigator.pop(context);
              },
              child: const Text('Apply rewrite'),
            ),
          ],
        ),
      );
    }
  }

  void _publishPortfolio() async {
    final auth = ref.read(authProvider);
    final portState = ref.read(portfolioProvider);
    final active = portState.activePortfolio;
    if (auth.userId == null || active == null) return;

    setState(() {
      _isPublishing = true;
    });

    Navigator.pushNamed(context, '/wizard');

    await ref.read(portfolioProvider.notifier).buildAndDeployPortfolio(
      userId: auth.userId!,
      profile: _profile,
      design: _design,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final completeness = _calculateCompleteness();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio & CV Editor'),
        actions: [
          Row(
            children: [
              Icon(isDark ? Icons.dark_mode : Icons.light_mode, size: 16),
              Switch(
                value: isDark,
                onChanged: (v) {
                  ref.read(themeModeProvider.notifier).state = v ? ThemeMode.dark : ThemeMode.light;
                },
              ),
            ],
          ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.cloud_done, color: Colors.greenAccent, size: 20),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Basic Info', icon: Icon(Icons.person)),
            Tab(text: 'Experience', icon: Icon(Icons.work)),
            Tab(text: 'Projects', icon: Icon(Icons.folder)),
            Tab(text: 'Design', icon: Icon(Icons.palette)),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: Colors.black.withOpacity(0.05),
            child: Row(
              children: [
                Text('Completeness: ${(completeness * 100).toInt()}%'),
                const SizedBox(width: 16),
                Expanded(
                  child: LinearProgressIndicator(
                    value: completeness,
                    backgroundColor: Colors.white10,
                    color: AppTheme.neonCyan,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicTab(),
                _buildExperienceTab(),
                _buildProjectsTab(),
                _buildDesignTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.glassBorder)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                final url = _profile['resume_url'];
                if (url != null) {
                  final fullUrl = url.startsWith('/') 
                      ? 'https://portfoliomaker-fxke.onrender.com/api/v1/static${url.replaceFirst("/api/v1/static", "")}' 
                      : url;
                  launchUrl(Uri.parse(fullUrl));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please compile your CV once to generate download links!')),
                  );
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('Download CV PDF'),
            ),
            ElevatedButton.icon(
              onPressed: _publishPortfolio,
              icon: const Icon(Icons.bolt, color: Colors.black),
              label: const Text('Publish Portfolio Website', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 54,
                  backgroundColor: AppTheme.glassCardBg,
                  backgroundImage: _profile['profile_photo_url'] != null ? NetworkImage(_profile['profile_photo_url']) : null,
                  child: _profile['profile_photo_url'] == null ? const Icon(Icons.person, size: 54) : null,
                ),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.neonCyan,
                  child: IconButton(
                    icon: const Icon(Icons.edit, size: 14, color: Colors.black),
                    onPressed: _pickAvatar,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
            onChanged: (v) => _triggerAutosave(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Professional Title', border: OutlineInputBorder()),
            onChanged: (v) => _triggerAutosave(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _availStatusCtrl,
            decoration: const InputDecoration(labelText: 'Availability Badge', border: OutlineInputBorder(), hintText: 'Available for hire / Freelance'),
            onChanged: (v) => _triggerAutosave(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
            onChanged: (v) => _triggerAutosave(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
            onChanged: (v) => _triggerAutosave(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _locationCtrl,
            decoration: const InputDecoration(labelText: 'Location / Base', border: OutlineInputBorder()),
            onChanged: (v) => _triggerAutosave(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _objectiveCtrl,
            decoration: const InputDecoration(labelText: 'Career Objective', border: OutlineInputBorder()),
            onChanged: (v) => _triggerAutosave(),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              TextField(
                controller: _bioCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Biography / Professional Summary', border: OutlineInputBorder()),
                onChanged: (v) => _triggerAutosave(),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: FloatingActionButton.small(
                  backgroundColor: AppTheme.neonCyan,
                  onPressed: () => _runAIPolish(_bioCtrl, 'bio profile summary'),
                  child: const Icon(Icons.auto_awesome, color: Colors.black, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceTab() {
    final experiences = _profile['experience'] as List? ?? [];
    return Scaffold(
      body: experiences.isEmpty
          ? const Center(child: Text('No experiences added.'))
          : ReorderableListView.builder(
              itemCount: experiences.length,
              onReorder: (oldIdx, newIdx) {
                setState(() {
                  if (newIdx > oldIdx) newIdx -= 1;
                  final item = experiences.removeAt(oldIdx);
                  experiences.insert(newIdx, item);
                });
                _triggerAutosave();
              },
              itemBuilder: (context, index) {
                final exp = experiences[index];
                return Dismissible(
                  key: Key('exp_$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(color: Colors.redAccent, alignment: Alignment.centerRight, child: const Padding(padding: EdgeInsets.all(16), child: Icon(Icons.delete))),
                  onDismissed: (direction) {
                    setState(() {
                      experiences.removeAt(index);
                    });
                    _triggerAutosave();
                  },
                  child: ListTile(
                    key: Key('list_exp_$index'),
                    title: Text(exp['role'] ?? 'Role'),
                    subtitle: Text(exp['company'] ?? 'Company'),
                    trailing: const Icon(Icons.drag_handle),
                    onTap: () => _editExperienceDialog(index, exp),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editExperienceDialog(-1, {}),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _editExperienceDialog(int index, Map<String, dynamic> exp) {
    final companyCtrl = TextEditingController(text: exp['company'] ?? '');
    final roleCtrl = TextEditingController(text: exp['role'] ?? '');
    final startCtrl = TextEditingController(text: exp['start_date'] ?? '');
    final endCtrl = TextEditingController(text: exp['end_date'] ?? '');
    final descCtrl = TextEditingController(text: exp['description'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == -1 ? 'Add Experience' : 'Edit Experience'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: 'Company')),
              TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: 'Role')),
              TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start Date')),
              TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End Date')),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Responsibilities')),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: FloatingActionButton.small(
                      backgroundColor: AppTheme.neonCyan,
                      onPressed: () => _runAIPolish(descCtrl, 'experience achievements'),
                      child: const Icon(Icons.auto_awesome, color: Colors.black, size: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
                final experiences = _profile['experience'] as List? ?? [];
                if (index == -1) {
                  experiences.add(newExp);
                } else {
                  experiences[index] = newExp;
                }
                _profile['experience'] = experiences;
              });
              _triggerAutosave();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsTab() {
    final projects = _profile['projects'] as List? ?? [];
    return Scaffold(
      body: projects.isEmpty
          ? const Center(child: Text('No projects added.'))
          : ReorderableListView.builder(
              itemCount: projects.length,
              onReorder: (oldIdx, newIdx) {
                setState(() {
                  if (newIdx > oldIdx) newIdx -= 1;
                  final item = projects.removeAt(oldIdx);
                  projects.insert(newIdx, item);
                });
                _triggerAutosave();
              },
              itemBuilder: (context, index) {
                final proj = projects[index];
                return Dismissible(
                  key: Key('proj_$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(color: Colors.redAccent, alignment: Alignment.centerRight, child: const Padding(padding: EdgeInsets.all(16), child: Icon(Icons.delete))),
                  onDismissed: (direction) {
                    setState(() {
                      projects.removeAt(index);
                    });
                    _triggerAutosave();
                  },
                  child: ListTile(
                    key: Key('list_proj_$index'),
                    title: Text(proj['title'] ?? 'Title'),
                    subtitle: Text(proj['description'] ?? 'Description'),
                    trailing: const Icon(Icons.drag_handle),
                    onTap: () => _editProjectDialog(index, proj),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editProjectDialog(-1, {}),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _editProjectDialog(int index, Map<String, dynamic> proj) {
    final titleCtrl = TextEditingController(text: proj['title'] ?? '');
    final descCtrl = TextEditingController(text: proj['description'] ?? '');
    final linkCtrl = TextEditingController(text: proj['link'] ?? '');
    final githubCtrl = TextEditingController(text: proj['github_link'] ?? '');
    final outcomeCtrl = TextEditingController(text: proj['outcomes_or_metrics'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == -1 ? 'Add Project' : 'Edit Project'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Project Title')),
              TextField(controller: linkCtrl, decoration: const InputDecoration(labelText: 'Live Link')),
              TextField(controller: githubCtrl, decoration: const InputDecoration(labelText: 'GitHub Link')),
              TextField(controller: outcomeCtrl, decoration: const InputDecoration(labelText: 'Key Outcomes / Metrics')),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Project Summary')),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: FloatingActionButton.small(
                      backgroundColor: AppTheme.neonCyan,
                      onPressed: () => _runAIPolish(descCtrl, 'portfolio project developer description'),
                      child: const Icon(Icons.auto_awesome, color: Colors.black, size: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
                'outcomes_or_metrics': outcomeCtrl.text,
                'technologies': proj['technologies'] ?? ['Flutter', 'Firebase'],
              };
              setState(() {
                final projects = _profile['projects'] as List? ?? [];
                if (index == -1) {
                  projects.add(newProj);
                } else {
                  projects[index] = newProj;
                }
                _profile['projects'] = projects;
              });
              _triggerAutosave();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignTab() {
    final templates = ['minimal', 'corporate', 'creative', 'dark'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose Portfolio Web Template', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _design['portfolio_template'] ?? _design['template'] ?? 'minimal',
            items: templates.map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
            onChanged: (v) {
              setState(() {
                _design['portfolio_template'] = v;
                _design['template'] = v;
              });
              _triggerAutosave();
            },
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          const Text('Choose CV PDF Format Template', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _design['cv_template'] ?? 'classic',
            items: const [
              DropdownMenuItem(value: 'classic', child: Text('CLASSIC')),
              DropdownMenuItem(value: 'modern', child: Text('MODERN')),
              DropdownMenuItem(value: 'creative', child: Text('CREATIVE')),
            ],
            onChanged: (v) {
              setState(() {
                _design['cv_template'] = v;
              });
              _triggerAutosave();
            },
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }
}
