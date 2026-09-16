import 'issa_library_screen.dart';
import '../services/issa_library.dart';
import '../services/coaching_context_service.dart';
import '../services/adaptive_plan_service.dart';
import '../services/word_plan_export.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/body_stats_model.dart';
import '../services/local_coach_service.dart';
import '../services/plan_export_service.dart';

class AiCoachChatScreen extends StatefulWidget {
  const AiCoachChatScreen({super.key});

  @override
  State<AiCoachChatScreen> createState() => _AiCoachChatScreenState();
}

class _AiCoachChatScreenState extends State<AiCoachChatScreen> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _loading = false;
  bool _word = true;
  AdaptivePlan? _plan;
  bool _downloading = false;
  BodyStats? _stats;
  bool _contextLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContext();
    _addMessage(
      role: 'assistant',
      text:
          "Welcome! I can help you review your workout plan, nutrition targets, habits and recovery.\n\n"
          "My guidance uses your assessment and reviewed ISSA principles. Topic questions also search all six supplied textbooks, with source pages you can open. It is educational software, not a live AI or certified professional.\n\n"
          "Save your diet, workout or everything as a Word document or PDF below.",
    );
  }

  Future<void> _loadContext() async {
    BodyStats? stats;
    try {
      _plan = await CoachingContextService.load();
      stats = _plan?.stats;
    } catch (_) {
      if (mounted) {
        _addMessage(
          role: 'assistant',
          text:
              'Your saved profile could not load. General guidance is available; reopen this screen after checking your connection to load your plans.',
        );
      }
    }
    if (mounted) {
      setState(() {
        _stats = stats;
        _contextLoading = false;
      });
    }
  }

  void _addMessage({
    required String role,
    required String text,
    List<IssaPassage> passages = const [],
  }) {
    setState(
      () => _messages.add(
        _ChatMessage(role: role, text: text, passages: passages),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _loading || _contextLoading || _downloading) return;
    _input.clear();
    _addMessage(role: 'user', text: text);
    setState(() => _loading = true);
    try {
      _plan = await CoachingContextService.load();
      if (!mounted) return;
      _stats = _plan?.stats;
      final response = await LocalCoachService.replyWithSources(
        text,
        _stats,
        plan: _plan,
      );
      if (!mounted) return;
      _addMessage(
        role: 'assistant',
        text: response.text,
        passages: response.passages,
      );
    } catch (_) {
      if (mounted) {
        _addMessage(
          role: 'assistant',
          text:
              'Your current coaching data could not load. Please check your connection and retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _downloadPlan(String planType) async {
    if (_downloading || _contextLoading || _loading) return;
    setState(() => _downloading = true);
    try {
      final plan = await CoachingContextService.load();
      if (!mounted) return;
      if (plan == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Set up your body profile before creating a plan.'),
          ),
        );
        return;
      }
      if (_word) {
        final message = await WordPlanExport.save(plan, planType);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      } else {
        await PlanExportService.shareAdaptive(plan, planType);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The document could not be saved. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white24,
              radius: 16,
              child: Text(
                'Fit',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fitness Coach',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Built-in fitness guidance',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.navy,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) return _buildTyping();
                return _buildBubble(_messages[i]);
              },
            ),
          ),
          _buildDownloadBar(),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    final isUser = msg.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.88,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: isUser
            ? Text(
                msg.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCoachText(msg.text),
                  if (msg.passages.isNotEmpty) ...[
                    const Divider(),
                    const Text(
                      'From your ISSA library',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text('Source excerpts · educational context'),
                    for (final passage in msg.passages)
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(
                          passage.citation,
                          style: const TextStyle(fontSize: 13),
                        ),
                        children: [
                          SelectableText(passage.excerpt),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => IssaReaderScreen(
                                  book: passage.book,
                                  initialPage: passage.page,
                                ),
                              ),
                            ),
                            child: const Text('Read source page'),
                          ),
                        ],
                      ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildCoachText(String text) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 6));
      } else if (line.startsWith('---') && line.endsWith('---')) {
        // Day headers like --- Monday ---
        final label = line.replaceAll('-', '').trim();
        widgets.add(
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        );
      } else if (line.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Text(
              line.substring(3),
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        );
      } else if (line.startsWith('### ') ||
          (line.startsWith('**') &&
              line.endsWith('**') &&
              !line.contains(' **'))) {
        final label = line
            .replaceAll('**', '')
            .replaceAll('### ', '')
            .replaceAll('# ', '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        );
      } else if (line.trim().startsWith('•') || line.trim().startsWith('-')) {
        final content = line.trim().replaceFirst(RegExp(r'^[•\-]\s*'), '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(child: _richLine(content)),
              ],
            ),
          ),
        );
      } else if (line.startsWith('  ')) {
        // Indented sub-content (exercise descriptions)
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 2),
            child: Text(
              line.trim(),
              style: const TextStyle(
                color: Color(0xFF555555),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
      } else if (line.startsWith('(From ISSA')) {
        widgets.add(
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF5FB),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF2E86AB).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              line,
              style: const TextStyle(
                color: Color(0xFF2E86AB),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: _richLine(line),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _richLine(String line) {
    // Handle **bold** inline
    if (!line.contains('**')) {
      return Text(
        line,
        style: TextStyle(color: AppColors.textDark, fontSize: 14, height: 1.5),
      );
    }
    final parts = line.split('**');
    final spans = <TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            fontWeight: i.isOdd ? FontWeight.bold : FontWeight.normal,
            color: i.isOdd ? AppColors.navy : AppColors.textDark,
            fontSize: 14,
          ),
        ),
      );
    }
    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildTyping() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              child: LinearProgressIndicator(
                color: AppColors.navy,
                backgroundColor: Color(0xFFE2E8F0),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Coach is thinking...',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadBar() {
    return Container(
      color: const Color(0xFFF0F4F8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Save Plan:',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          DropdownButton<bool>(
            value: _word,
            items: const [
              DropdownMenuItem(value: true, child: Text('Word (.docx)')),
              DropdownMenuItem(value: false, child: Text('PDF')),
            ],
            onChanged: _downloading
                ? null
                : (v) => setState(() => _word = v ?? true),
          ),
          const SizedBox(width: 8),
          _downloadBtn(
            'Workout',
            'workout',
            Icons.fitness_center,
            AppColors.navy,
          ),
          const SizedBox(width: 6),
          _downloadBtn(
            'Nutrition',
            'nutrition',
            Icons.restaurant,
            Colors.green.shade700,
          ),
          const SizedBox(width: 6),
          _downloadBtn(
            'Full Plan',
            'full',
            Icons.download_rounded,
            Colors.deepOrange,
          ),
        ],
      ),
    );
  }

  Widget _downloadBtn(String label, String type, IconData icon, Color color) {
    return SizedBox(
      width: 110,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _downloading ? null : () => _downloadPlan(type),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: _downloading
                ? const Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Ask about your plan or a training topic...',
                hintStyle: TextStyle(
                  color: AppColors.muted.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AppColors.bg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.navy,
                    ),
                  ),
                )
              : IconButton(
                  onPressed: _contextLoading ? null : _send,
                  icon: const Icon(Icons.send_rounded),
                  color: AppColors.navy,
                  iconSize: 26,
                ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }
}

class _ChatMessage {
  final String role;
  final String text;
  final List<IssaPassage> passages;
  const _ChatMessage({
    required this.role,
    required this.text,
    this.passages = const [],
  });
}
