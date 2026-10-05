import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import 'community_report_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Future<void> _markAllAsRead(String uid) async {
    try {
      final notifsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications');

      final snapshot = await notifsRef.get();
      final batch = FirebaseFirestore.instance.batch();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final isRead = (data['isRead'] as bool?) ?? (data['is_read'] as bool?) ?? false;
        if (!isRead) {
          batch.update(doc.reference, {'isRead': true, 'is_read': true});
        }
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read.')),
        );
      }
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  Future<void> _deleteNotification(String uid, String notifId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notifId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final uid = appState.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          TextButton(
            onPressed: uid.isEmpty ? null : () => _markAllAsRead(uid),
            child: const Text('Mark all as read', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
      body: uid.isEmpty || uid == 'guest_session'
          ? const Center(child: Text('Please log in as a resident to view notifications.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('notifications')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading notifications: ${snapshot.error}', style: const TextStyle(fontSize: 12, color: Colors.red)),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(snapshot.data!.docs);

                // Sort client-side by created_at / createdAt descending
                docs.sort((a, b) {
                  final aData = a.data();
                  final bData = b.data();
                  final aTime = aData['createdAt'] ?? aData['created_at'] ?? aData['timestamp'];
                  final bTime = bData['createdAt'] ?? bData['created_at'] ?? bData['timestamp'];
                  
                  DateTime aDt = DateTime.fromMillisecondsSinceEpoch(0);
                  DateTime bDt = DateTime.fromMillisecondsSinceEpoch(0);

                  if (aTime is Timestamp) aDt = aTime.toDate();
                  if (bTime is Timestamp) bDt = bTime.toDate();

                  return bDt.compareTo(aDt);
                });

                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 54, color: Color(0xFF94A3B8)),
                        SizedBox(height: 14),
                        Text('No notifications yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        SizedBox(height: 4),
                        Text('You will receive updates here for announcements & reported cases.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final notifId = doc.id;
                    final title = (data['title'] as String?) ?? 'Update';
                    final body = (data['message'] as String?) ?? (data['body'] as String?) ?? '';
                    final type = (data['type'] as String?) ?? 'announcement';
                    final isRead = (data['isRead'] as bool?) ?? (data['is_read'] as bool?) ?? false;
                    final referenceId = (data['reference_id'] as String?) ?? (data['referenceId'] as String?) ?? '';

                    final isComplaint = type == 'complaint_update' || type == 'case_update';

                    return Dismissible(
                      key: Key(notifId),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _deleteNotification(uid, notifId),
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isRead ? Colors.white : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isRead ? const Color(0xFFE2E8F0) : const Color(0xFFBFDBFE),
                          ),
                          boxShadow: const [
                            BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: ListTile(
                          onTap: () {
                            // Mark read
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .collection('notifications')
                                .doc(notifId)
                                .update({'isRead': true, 'is_read': true});

                            // Navigate to complaint details if referenceId matches a report
                            if (referenceId.isNotEmpty && isComplaint) {
                              final report = appState.getReportById(referenceId);
                              if (report != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CommunityReportDetailsScreen(report: report),
                                  ),
                                );
                              }
                            }
                          },
                          leading: CircleAvatar(
                            backgroundColor: isComplaint ? const Color(0xFFFEF3C7) : const Color(0xFFDBEAFE),
                            child: Icon(
                              isComplaint ? Icons.report_problem_outlined : Icons.campaign_outlined,
                              color: isComplaint ? const Color(0xFFD97706) : const Color(0xFF1D4ED8),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            title,
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 14,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          subtitle: Text(
                            body,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                          ),
                          trailing: !isRead
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2563EB),
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
