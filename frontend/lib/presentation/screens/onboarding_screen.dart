import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:portfolio_ai/config/theme.dart';
import 'package:portfolio_ai/presentation/providers/auth_provider.dart';
import 'package:portfolio_ai/presentation/providers/portfolio_provider.dart';
import 'package:portfolio_ai/presentation/widgets/glass_card.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final Widget? customWidget;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.customWidget,
  });
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final List<ChatMessage> _messages = [];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  
  // Data State
  String _fullName = '';
  String _title = '';
  String _email = '';
  String _location = '';
  String _about = '';
  final List<String> _skills = [];
  Uint8List? _resumeBytes;
  String? _resumeName;
  
  // Design preferences
  String _selectedTemplate = 'Glassmorphism';
  String _primaryColor = '#00FFCC';
  String _secondaryColor = '#8B5CF6';

  int _interviewStep = 0;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    _fullName = auth.fullName ?? '';
    _email = auth.email ?? '';
    
    // Initial welcome message from AI
    _messages.add(
      ChatMessage(
        text: "Hi! I am your AI Portfolio Engineer. I will interview you, design your website, enhance your copy, run QA tests, deploy to Vercel, and review it like a recruiter.\n\nLet's get started. To speed things up, you can upload your resume directly, or tell me: What is your full name?",
        isUser: false,
        customWidget: _buildResumeUploadButton(),
      ),
    );
  }

  Widget _buildResumeUploadButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: OutlinedButton.icon(
        onPressed: _pickResume,
        icon: const Icon(Icons.upload_file, color: AppTheme.neonCyan),
        label: Text(_resumeName ?? 'Upload Resume (PDF/TXT)'),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.neonCyan),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
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
        _messages.add(ChatMessage(text: "Uploaded resume: $_resumeName", isUser: true));
      });
      _scrollToBottom();
      
      // Simulate AI analyzing resume
      _addSystemMessage("Analyzing your resume structure... Extracting work history, skills, and projects.");
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Pre-populate mock fields extracted from resume
      setState(() {
        _title = "Senior Software Engineer";
        _location = "San Francisco, CA";
        _about = "Passionate engineer focusing on building scalable systems.";
        _skills.addAll(["Python", "JavaScript", "Flutter", "React", "Docker"]);
      });

      _addSystemMessage("Extracted successfully! I found 5 core skills: Python, JavaScript, Flutter, React, Docker. \n\nNext, let's select a design template. Which theme do you like best? (Glassmorphism, Cyberpunk, Minimalist, Corporate, Apple Style)");
      setState(() {
        _interviewStep = 4; // jump to template selection step
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addSystemMessage(String text, {Widget? customWidget}) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: false, customWidget: customWidget));
    });
    _scrollToBottom();
  }

  void _handleUserMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _textController.clear();
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 600));

    // Conversational state loop
    switch (_interviewStep) {
      case 0: // Full name response
        _fullName = text;
        _interviewStep = 1;
        _addSystemMessage("Nice to meet you, $_fullName! What is your professional title? (e.g. Fullstack Developer)");
        break;
      case 1: // Title response
        _title = text;
        _interviewStep = 2;
        _addSystemMessage("Awesome. What is your contact email for hiring managers?");
        break;
      case 2: // Email response
        _email = text;
        _interviewStep = 3;
        _addSystemMessage("Got it. Tell me a bit about your top technical skills. Write them down separated by commas.");
        break;
      case 3: // Skills response
        final parsedSkills = text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        _skills.addAll(parsedSkills);
        _interviewStep = 4;
        _addSystemMessage(
          "Got it. Let's decide your design aesthetic. Which layout template fits your brand?",
          customWidget: _buildTemplatePicker(),
        );
        break;
      case 4: // Design preferences selection
        _selectedTemplate = text;
        _interviewStep = 5;
        _addSystemMessage(
          "Perfect! I have designed your site. Click 'Assemble & Deploy' below to run the AI Portfolio Engineering loop.",
          customWidget: _buildDeployWidget(),
        );
        break;
      default:
        _addSystemMessage("I am ready to build! Click 'Assemble & Deploy' in the chat options to host your website.");
    }
  }

  Widget _buildTemplatePicker() {
    final templates = ['Glassmorphism', 'Cyberpunk', 'Minimal', 'Creative', 'Apple Style'];
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Wrap(
        spacing: 8,
        children: templates.map((t) {
          return ChoiceChip(
            label: Text(t),
            selected: _selectedTemplate == t,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedTemplate = t;
                });
                _handleUserMessage(t);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDeployWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: AppTheme.primaryGradient,
        ),
        child: ElevatedButton.icon(
          onPressed: _startOrchestrator,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.bolt, color: Colors.black),
          label: const Text('Assemble & Deploy Website', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _startOrchestrator() async {
    final auth = ref.read(authProvider);
    if (auth.userId == null) return;

    final profile = {
      'full_name': _fullName,
      'professional_title': _title,
      'email': _email,
      'location': _location.isNotEmpty ? _location : 'Remote',
      'about_me': _about.isNotEmpty ? _about : 'Experienced professional creating digital products.',
      'skills': _skills.isNotEmpty ? _skills : ['Flutter', 'Python', 'FastAPI'],
      'experience': [
        {
          'company': 'Company Inc.',
          'role': _title,
          'start_date': '2023',
          'end_date': 'Present',
          'description': 'Designed and implemented full-stack cloud workflows.',
          'skills_used': _skills,
        }
      ],
      'projects': [
        {
          'title': 'Autonomous AI Agent System',
          'description': 'Constructed real-time agent workflow orchestration schemas.',
          'technologies': _skills,
        }
      ]
    };

    final design = {
      'template': _selectedTemplate.toLowerCase(),
      'primary_color': _primaryColor,
      'secondary_color': _secondaryColor,
      'font': 'Inter',
      'inspiration_description': 'Interactive conversational engineering design.',
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
        title: const Text('AI Portfolio Engineer', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Row(
        children: [
          // Chat Main Panel
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildChatBubble(msg);
                    },
                  ),
                ),
                _buildInputBar(),
              ],
            ),
          ),
          // side details visualization panel on larger screens
          if (MediaQuery.of(context).size.width > 800)
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  border: const Border(left: BorderSide(color: AppTheme.glassBorder)),
                  color: Colors.white.withOpacity(0.01),
                ),
                padding: const EdgeInsets.all(20),
                child: _buildCollectedSummaryPanel(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final align = message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = message.isUser ? AppTheme.neonPurple.withOpacity(0.2) : AppTheme.glassCardBg;
    final textColor = message.isUser ? Colors.white : Colors.white.withOpacity(0.9);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                const CircleAvatar(
                  backgroundColor: AppTheme.neonCyan,
                  radius: 14,
                  child: Icon(Icons.auto_awesome, color: Colors.black, size: 14),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: GlassCard(
                  color: bubbleColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(color: textColor, fontSize: 14),
                      ),
                      if (message.customWidget != null) message.customWidget!,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.glassBorder)),
        color: AppTheme.darkBg,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Type your message...',
                border: InputBorder.none,
              ),
              onSubmitted: _handleUserMessage,
            ),
          ),
          IconButton(
            onPressed: () => _handleUserMessage(_textController.text),
            icon: const Icon(Icons.send, color: AppTheme.neonCyan),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectedSummaryPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Engineering Snapshot',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.neonCyan),
        ),
        const SizedBox(height: 24),
        _buildSummaryItem('Name', _fullName, Icons.person),
        _buildSummaryItem('Title', _title, Icons.badge),
        _buildSummaryItem('Email', _email, Icons.email),
        _buildSummaryItem('Resume', _resumeName ?? 'None', Icons.description),
        _buildSummaryItem('Template', _selectedTemplate, Icons.palette),
        const SizedBox(height: 20),
        const Text('Skills:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white54)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: _skills.map((s) => Chip(
            label: Text(s, style: const TextStyle(fontSize: 10)),
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    final hasValue = value.isNotEmpty && value != 'None';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: hasValue ? AppTheme.neonCyan : Colors.white24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
              Text(
                hasValue ? value : 'Awaiting interview...',
                style: TextStyle(color: hasValue ? Colors.white : Colors.white24, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
