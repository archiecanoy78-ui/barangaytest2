import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../validators.dart';
import '../widgets/portal_theme.dart';

class AdminMessagesPage extends StatefulWidget {
  const AdminMessagesPage({super.key});

  @override
  State<AdminMessagesPage> createState() => _AdminMessagesPageState();
}

class _AdminMessagesPageState extends State<AdminMessagesPage> {
  String _searchQuery = '';
  String? _selectedConversationId;
  String? _selectedResidentName;

  final TextEditingController _replyController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _replyController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _markConversationAsRead(String conversationId) {
    try {
      FirebaseFirestore.instance.collection('conversations').doc(conversationId).update({
        'unreadCountAdmin': 0,
      });
    } catch (e) {
      debugPrint('Error marking conversation read: $e');
    }
  }

  Future<void> _sendReply(String conversationId, String staffUid) async {
    final text = _replyController.text.trim();
    if (text.isEmpty || text.length > 200 || _isSending) return;

    setState(() => _isSending = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final convRef = FirebaseFirestore.instance.collection('conversations').doc(conversationId);
      final msgRef = convRef.collection('messages').doc();

      batch.set(msgRef, {
        'senderId': staffUid,
        'senderRole': 'staff',
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      batch.update(convRef, {
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCountResident': FieldValue.increment(1),
        'unreadCountAdmin': 0,
      });

      await batch.commit();

      _replyController.clear();
      setState(() => _isSending = false);

      Future.delayed(const Duration(milliseconds: 200), () {
        if (_chatScrollController.hasClients) {
          _chatScrollController.animateTo(
            _chatScrollController.position.maxScrollExtent,
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
    final currentUser = appState.currentUser;
    final staffUid = currentUser?.id ?? 'admin';

    return Row(
      children: [
        // Left Column: Conversations List
        SizedBox(
          width: 360,
          child: Container(
            decoration: const BoxDecoration(
              color: PortalColors.surface,
              border: Border(right: BorderSide(color: PortalColors.border)),
            ),
            child: Column(
              children: [
                // Header & Search Bar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: PortalColors.border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resident Messages',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: PortalColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'Search resident by name...',
                          prefixIcon: const Icon(Icons.search, size: 18, color: PortalColors.textMuted),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Conversations List
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('conversations')
                        .orderBy('lastMessageAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(fontSize: 12, color: Colors.red)));
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var docs = snapshot.data!.docs;
                      if (_searchQuery.isNotEmpty) {
                        docs = docs.where((d) {
                          final name = (d.data()['residentName'] as String?)?.toLowerCase() ?? '';
                          return name.contains(_searchQuery);
                        }).toList();
                      }

                      if (docs.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.forum_outlined, size: 42, color: PortalColors.textMuted),
                              SizedBox(height: 12),
                              Text('No messages yet', style: TextStyle(color: PortalColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: PortalColors.border),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();
                          final convId = doc.id;
                          final residentName = (data['residentName'] as String?) ?? 'Resident';
                          final lastMsg = (data['lastMessage'] as String?) ?? '';
                          final unreadAdmin = (data['unreadCountAdmin'] as int?) ?? 0;
                          final isSelected = _selectedConversationId == convId;

                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: const Color(0xFFEFF6FF),
                            onTap: () {
                              setState(() {
                                _selectedConversationId = convId;
                                _selectedResidentName = residentName;
                              });
                              _markConversationAsRead(convId);
                            },
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFDBEAFE),
                              child: Text(
                                residentName.isNotEmpty ? residentName[0].toUpperCase() : 'R',
                                style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    residentName,
                                    style: TextStyle(
                                      fontWeight: unreadAdmin > 0 ? FontWeight.bold : FontWeight.w600,
                                      fontSize: 14,
                                      color: PortalColors.textDark,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (unreadAdmin > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$unreadAdmin',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              lastMsg,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: unreadAdmin > 0 ? PortalColors.textDark : PortalColors.textMuted,
                                fontWeight: unreadAdmin > 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Column: Chat View
        Expanded(
          child: _selectedConversationId == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mark_chat_read_outlined, size: 64, color: PortalColors.textMuted),
                      SizedBox(height: 16),
                      Text('Select a conversation to view messages', style: TextStyle(color: PortalColors.textMuted, fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              : Container(
                  color: const Color(0xFFF8FAFC),
                  child: Column(
                    children: [
                      // Chat Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(bottom: BorderSide(color: PortalColors.border)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFFDBEAFE),
                              child: Text(
                                (_selectedResidentName ?? 'R')[0].toUpperCase(),
                                style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedResidentName ?? 'Resident',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: PortalColors.textDark),
                                ),
                                const Text(
                                  'Verified Resident Chat',
                                  style: TextStyle(fontSize: 11, color: PortalColors.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Messages Feed
                      Expanded(
                        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('conversations')
                              .doc(_selectedConversationId)
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
                                child: Text('No messages in this conversation yet.', style: TextStyle(color: PortalColors.textMuted, fontSize: 13)),
                              );
                            }

                            return ListView.builder(
                              controller: _chatScrollController,
                              padding: const EdgeInsets.all(24),
                              itemCount: msgs.length,
                              itemBuilder: (context, index) {
                                final msg = msgs[index].data();
                                final text = (msg['text'] as String?) ?? '';
                                final senderRole = (msg['senderRole'] as String?) ?? 'resident';
                                final isStaff = senderRole == 'staff' || senderRole == 'admin';

                                return Align(
                                  alignment: isStaff ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    constraints: const BoxConstraints(maxWidth: 420),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isStaff ? const Color(0xFF2563EB) : Colors.white,
                                      borderRadius: BorderRadius.circular(16).copyWith(
                                        bottomRight: isStaff ? Radius.zero : const Radius.circular(16),
                                        bottomLeft: isStaff ? const Radius.circular(16) : Radius.zero,
                                      ),
                                      border: isStaff ? null : Border.all(color: PortalColors.border),
                                      boxShadow: const [
                                        BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2)),
                                      ],
                                    ),
                                    child: Text(
                                      text,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isStaff ? Colors.white : PortalColors.textDark,
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

                      // Input Reply Bar
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(top: BorderSide(color: PortalColors.border)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _replyController,
                                maxLength: 200,
                                inputFormatters: [LengthLimitingTextInputFormatter(200)],
                                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => Text(
                                  '$currentLength / 200',
                                  style: const TextStyle(fontSize: 10, color: PortalColors.textMuted),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Type an official staff reply (max 200 chars)...',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onSubmitted: (_) => _sendReply(_selectedConversationId!, staffUid),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _isSending ? null : () => _sendReply(_selectedConversationId!, staffUid),
                              icon: _isSending
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.send_rounded, size: 18),
                              label: const Text('Send Reply'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
