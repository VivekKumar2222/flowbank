import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/api_service.dart';

class FinancialChatScreen extends StatefulWidget {
  const FinancialChatScreen({super.key});

  @override
  State<FinancialChatScreen> createState() => _FinancialChatScreenState();
}

class _FinancialChatScreenState extends State<FinancialChatScreen> {
  static const _dark    = Color(0xFF0A0A0F);
  static const _surface = Color(0xFF13131A);
  static const _border  = Color(0xFF1E1E2E);

  final _scrollCtrl = ScrollController();
  final _inputCtrl  = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _sending = false;
  bool _minLoadDone = false;
  String _userName = 'there';

  static const _suggestions = [
    'Should I buy a PS5 right now?',
    'Am I saving enough this month?',
    'Can I afford a vacation next month?',
    'What\'s eating most of my budget?',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _minLoadDone = true);
    });
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _userName = prefs.getString('userName') ?? 'there');
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _history => _messages
      .where((m) => !m.isTyping)
      .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
      .toList();

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _sending) return;
    _inputCtrl.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _messages.add(_ChatMessage(text: '', isUser: false, isTyping: true));
      _sending = true;
    });
    _scrollToBottom();

    try {
      // ignore: use_build_context_synchronously
      final res = await ApiService.post('/api/ai/chat', {
        'message': text,
        'history': _history.take(_history.length - 1).toList(),
      }, context);

      if (mounted) {
        final reply = res.statusCode == 200
            ? jsonDecode(res.body)['reply'] as String
            : 'Sorry, I\'m having trouble right now. Try again in a moment.';
        setState(() {
          _messages.removeLast(); // remove typing
          _messages.add(_ChatMessage(text: reply, isUser: false));
          _sending = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() {
        _messages.removeLast();
        _messages.add(_ChatMessage(text: 'Connection error. Please try again.', isUser: false));
        _sending = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: _dark,
      resizeToAvoidBottomInset: true,
      body: !_minLoadDone
          ? Center(child: Lottie.asset('assets/ai-loading.json', width: 160, height: 160))
          : SafeArea(
              child: Column(children: [
                _buildAppBar(),
                Expanded(
                  child: _messages.isEmpty ? _buildEmptyState() : _buildMessages(),
                ),
                _buildInput(bottom),
              ]),
            ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.white70),
          ),
        ),
        // const SizedBox(width: 14),
        // Image.asset('assets/ai-iocn-1.png', width: 28, height: 28),
        // const SizedBox(width: 10),
        // Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        //   const Text('Finara', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Manrope')),
        //   Text('Financial AI', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45))),
        // ]
        // ),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Image.asset('assets/ai-iocn-1.png', width: 32, height: 32),
        const SizedBox(height: 20),
        Text('Hi $_userName, \nwelcome!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Manrope', )),
        const SizedBox(height: 8),
        Text(
          'Your AI financial advisor, ask me anything about your Finance.',
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.45), height: 1.5),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: _suggestions.map((s) => GestureDetector(
            onTap: () => _send(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: Text(s, style: const TextStyle(fontSize: 13, color: Colors.white70)),
            ),
          )).toList(),
        ),
      ]),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildBubble(_messages[i]),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    if (msg.isTyping) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10, right: 60),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18),
            ),
          ),
          child: _TypingIndicator(),
        ),
      );
    }

    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 10,
          left: msg.isUser ? 50 : 0,
          right: msg.isUser ? 0 : 50,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: msg.isUser
              ? const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF2563EB)])
              : null,
          color: msg.isUser ? null : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 18),
          ),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            fontSize: 14, color: msg.isUser ? Colors.white : Colors.white.withOpacity(0.88),
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildInput(double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
      decoration: BoxDecoration(
        color: Color(0xFF1B242D).withOpacity(0.0),
        //border: Border(top: BorderSide(color: _border, width: 1)),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _inputCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            cursorColor: const Color.fromARGB(255, 165, 165, 165),
            maxLines: null,
            textInputAction: TextInputAction.send,
            onSubmitted: _send,
            decoration: InputDecoration(
              hintText: 'Ask Finara…',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color.fromARGB(255, 125, 125, 125), width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _sending ? null : () => _send(_inputCtrl.text),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: _sending ? null : const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF2563EB)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              color: _sending ? Colors.white12 : null,
              borderRadius: BorderRadius.circular(13),
            ),
            child: _sending
                ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)))
                : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isTyping;
  _ChatMessage({required this.text, required this.isUser, this.isTyping = false});
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(3, (i) => AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true, period: Duration(milliseconds: 1000 + i * 200)));
    _anims = _ctrls.map((c) => Tween<double>(begin: 0, end: 6).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () { if (mounted) _ctrls[i].repeat(reverse: true); });
    }
  }

  @override
  void dispose() { for (final c in _ctrls) c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) =>
      AnimatedBuilder(
        animation: _anims[i],
        builder: (_, __) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Transform.translate(
            offset: Offset(0, -_anims[i].value),
            child: Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    ));
  }
}
