import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../validators.dart';

class ResidentChatScreen extends StatefulWidget {
  const ResidentChatScreen({super.key});

  @override
  State<ResidentChatScreen> createState() => _ResidentChatScreenState();
}

class _ResidentChatScreenState extends State<ResidentChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _resetResidentUnreadCount();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _resetResidentUnreadCount() {
    final appState = Provider.of<AppState>(context, listen: false);
    final uid = appState.currentUser?.id;
    if (uid != null) {
      try {
        FirebaseFirestore.instance.collection('conversations').doc(uid).update({
          'unreadCountResident': 0,
        });
      } catch (_) {}
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || text.length > 200 || _isSending) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final user = appState.currentUser;
    if (user == null) return;

    setState(() => _isSending = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final convRef = FirebaseFirestore.instance.collection('conversations').doc(user.id);
      final msgRef = convRef.collection('messages').doc();

      batch.set(msgRef, {
        'senderId': user.id,
        'senderRole': 'resident',
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      batch.set(
        convRef,
        {
          'residentId': user.id,
          'residentName': user.name,
          'lastMessage': text,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'unreadCountAdmin': FieldValue.increment(1),
          'unreadCountResident': 0,
          'status': 'active',
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      _messageController.clear();
      setState(() => _isSending = false);

      Future.delayed(const Duration(milliseconds: 200), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    final uid = user?.id ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Barangay Help Desk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: Column(
        children: [
          // Messages Feed
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('conversations')
                  .doc(uid)
                  .collection('messages')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final msgs = snapshot.data!.docs;
                if (msgs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Color(0xFF94A3B8)),
                          SizedBox(height: 12),
                          Text('Send a message to Barangay Staff', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                          SizedBox(height: 4),
                          Text('Staff members will reply directly to your messages in real time.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final msg = msgs[index].data();
                    final text = (msg['text'] as String?) ?? '';
                    final senderRole = (msg['senderRole'] as String?) ?? 'resident';
                    final isResident = senderRole == 'resident';

                    return Align(
                      alignment: isResident ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        constraints: const BoxConstraints(maxWidth: 320),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isResident ? const Color(0xFF2563EB) : Colors.white,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isResident ? Radius.zero : const Radius.circular(16),
                            bottomLeft: isResident ? const Radius.circular(16) : Radius.zero,
                          ),
                          border: isResident ? null : Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 14,
                            color: isResident ? Colors.white : const Color(0xFF0F172A),
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Input Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    maxLength: 200,
                    inputFormatters: [LengthLimitingTextInputFormatter(200)],
                    buildCounter: (_, {required currentLength, required isFocused, maxLength}) => Text(
                      '$currentLength / 200',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type your message (max 200 chars)...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: _isSending ? null : _sendMessage,
                  icon: _isSending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
