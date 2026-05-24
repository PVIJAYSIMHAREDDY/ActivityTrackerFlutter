import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../theme.dart';
import '../models/body_stats_model.dart';
import '../services/firestore_service.dart';

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
  bool _downloading = false;
  Map<String, dynamic> _userContext = {};

  static const _baseUrl = 'http://192.168.4.26:5050';

  @override
  void initState() {
    super.initState();
    _loadContext();
    _addMessage(
      role: 'assistant',
      text: "Hey! I'm your ISSA-certified AI coach.\n\n"
            "I have your profile loaded and I'm ready to help you.\n\n"
            "Ask me anything:\n"
            "• Create me a workout plan\n"
            "• What should I eat today?\n"
            "• I have knee pain — what should I do?\n"
            "• How do I break through a plateau?\n"
            "• What supplements should I take?\n"
            "• Design me a cardio programme\n\n"
            "You can also download your personalised plan as a PDF using the buttons below.",
    );
  }

  Future<void> _loadContext() async {
    try {
      final bodyStats = await BodyStats.load();
      final profile   = await FirestoreService.loadProfile();
      final now       = DateTime.now();
      final dateStr   = "${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}";
      final workoutSnap = await FirestoreService.workoutsStream(dateStr).first;
      final dietSnap    = await FirestoreService.dietStream(dateStr).first;
      final habitsSnap  = await FirestoreService.habitsStream().first;
      final goalsSnap   = await FirestoreService.goalsStream().first;
      setState(() {
        _userContext = {
          'body_stats':       bodyStats?.toJson(),
          'profile':          profile,
          'recent_workouts':  workoutSnap.docs.map((d) => d.data()).toList(),
          'today_diet':       dietSnap.docs.map((d) => d.data()).toList(),
          'habits':           habitsSnap.docs.map((d) => d.data()).toList(),
          'goals':            goalsSnap.docs.map((d) => d.data()).toList(),
        };
      });
    } catch (_) {}
  }

  void _addMessage({required String role, required String text}) {
    setState(() => _messages.add(_ChatMessage(role: role, text: text)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _loading) return;
    _input.clear();
    _addMessage(role: 'user', text: text);
    setState(() => _loading = true);

    try {
      final history = _messages
          .skip(1)
          .map((m) => {'role': m.role, 'content': m.text})
          .toList();

      final res = await http.post(
        Uri.parse('$_baseUrl/api/coach/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message':      text,
          'history':      history,
          'user_context': _userContext,
        }),
      ).timeout(const Duration(seconds: 60));

      if (res.statusCode == 200) {
        final data  = jsonDecode(res.body) as Map;
        final reply = data['reply'] as String? ?? 'No response.';
        _addMessage(role: 'assistant', text: reply);
      } else {
        final err = (jsonDecode(res.body) as Map)['error'] ?? 'Server error ${res.statusCode}';
        _addMessage(role: 'assistant', text: 'Sorry, something went wrong: $err');
      }
    } catch (e) {
      _addMessage(
        role: 'assistant',
        text: 'Could not reach the coach server.\n\nMake sure the backend is running:\npython3 app.py\n\nError: $e',
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _downloadPlan(String planType) async {
    setState(() => _downloading = true);
    final label = {'workout': 'Workout Plan', 'nutrition': 'Nutrition Plan', 'full': 'Full Plan'}[planType]!;
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/coach/download'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'plan_type': planType, 'user_context': _userContext}),
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final dir      = await getApplicationDocumentsDirectory();
        final fname    = '${planType}_plan.pdf';
        final file     = File('${dir.path}/$fname');
        await file.writeAsBytes(res.bodyBytes);
        await OpenFile.open(file.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label downloaded and opened!'),
              backgroundColor: AppColors.navy,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download failed: ${res.statusCode}'),
                backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _downloading = false);
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
              child: Text('AI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Coach', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text('ISSA Certified · Always On', style: TextStyle(fontSize: 10, color: Colors.white70)),
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
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
        decoration: BoxDecoration(
          color: isUser ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(18),
            topRight:    const Radius.circular(18),
            bottomLeft:  Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: isUser
            ? Text(msg.text,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5))
            : _buildCoachText(msg.text),
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
        widgets.add(Container(
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 2),
          child: Text(line.substring(3),
              style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 15)),
        ));
      } else if (line.startsWith('### ') || (line.startsWith('**') && line.endsWith('**') && !line.contains(' **'))) {
        final label = line.replaceAll('**', '').replaceAll('### ', '').replaceAll('# ', '');
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Text(label,
              style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 13)),
        ));
      } else if (line.trim().startsWith('•') || line.trim().startsWith('-')) {
        final content = line.trim().replaceFirst(RegExp(r'^[•\-]\s*'), '');
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: TextStyle(color: AppColors.navy, fontSize: 14, fontWeight: FontWeight.bold)),
              Expanded(child: _richLine(content)),
            ],
          ),
        ));
      } else if (line.startsWith('  ')) {
        // Indented sub-content (exercise descriptions)
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 2),
          child: Text(line.trim(),
              style: const TextStyle(color: Color(0xFF555555), fontSize: 12, fontStyle: FontStyle.italic)),
        ));
      } else if (line.startsWith('(From ISSA')) {
        widgets.add(Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF5FB),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF2E86AB).withOpacity(0.3)),
          ),
          child: Text(line,
              style: const TextStyle(color: Color(0xFF2E86AB), fontSize: 12, fontStyle: FontStyle.italic)),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: _richLine(line),
        ));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  Widget _richLine(String line) {
    // Handle **bold** inline
    if (!line.contains('**')) {
      return Text(line, style: TextStyle(color: AppColors.textDark, fontSize: 14, height: 1.5));
    }
    final parts = line.split('**');
    final spans = <TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(TextSpan(
        text: parts[i],
        style: TextStyle(
          fontWeight: i.isOdd ? FontWeight.bold : FontWeight.normal,
          color: i.isOdd ? AppColors.navy : AppColors.textDark,
          fontSize: 14,
        ),
      ));
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
            topLeft: Radius.circular(18), topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 6)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 40, child: LinearProgressIndicator(
              color: AppColors.navy, backgroundColor: Color(0xFFE2E8F0))),
            const SizedBox(width: 10),
            Text('Coach is thinking...', style: TextStyle(fontSize: 13, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadBar() {
    return Container(
      color: const Color(0xFFF0F4F8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text('Download Plan:', style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          _downloadBtn('Workout', 'workout', Icons.fitness_center, AppColors.navy),
          const SizedBox(width: 6),
          _downloadBtn('Nutrition', 'nutrition', Icons.restaurant, Colors.green.shade700),
          const SizedBox(width: 6),
          _downloadBtn('Full Plan', 'full', Icons.download_rounded, Colors.deepOrange),
        ],
      ),
    );
  }

  Widget _downloadBtn(String label, String type, IconData icon, Color color) {
    return Expanded(
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _downloading ? null : () => _downloadPlan(type),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: _downloading
                ? const Center(child: SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 13),
                      const SizedBox(width: 4),
                      Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
        left: 16, right: 8, top: 10,
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
                hintText: 'Ask your coach anything...',
                hintStyle: TextStyle(color: AppColors.muted.withOpacity(0.7), fontSize: 14),
                filled: true,
                fillColor: AppColors.bg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _loading
              ? const Padding(padding: EdgeInsets.all(12),
                  child: SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.navy)))
              : IconButton(
                  onPressed: _send,
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
  const _ChatMessage({required this.role, required this.text});
}
