import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_theme.dart';
import '../../components/custom_app_bar.dart';

class ChatScreen extends StatefulWidget {
  final String name;
  final String? peerEmail;

  const ChatScreen({super.key, required this.name, this.peerEmail});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String? _myEmail = FirebaseAuth.instance.currentUser?.email?.toLowerCase();

  String get _chatId {
    final String peer = (widget.peerEmail ?? 'tutor@umindanao.edu.ph').toLowerCase();
    final String me = (_myEmail ?? 'anonymous').toLowerCase();
    final List<String> ids = [me, peer];
    ids.sort();
    return ids.join('_');
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty || _myEmail == null) return;

    final text = _controller.text.trim();
    _controller.clear();

    final String peerEmail = (widget.peerEmail ?? 'tutor@umindanao.edu.ph').toLowerCase();

    await FirebaseFirestore.instance.collection('messages').add({
      'chatId': _chatId,
      'senderId': _myEmail?.toLowerCase(),
      'receiverId': peerEmail,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(
        centerTitle: false,
        customTitleWidget: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                  child: Text(
                    widget.name[0],
                    style: const TextStyle(
                      color: AppTheme.primaryRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.name,
                  style: GoogleFonts.manrope(
                    color: AppTheme.neutralColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Active now',
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF2ECC71),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.video, color: AppTheme.primaryRed, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(LucideIcons.phone, color: AppTheme.primaryRed, size: 20),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('chatId', isEqualTo: _chatId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
                }

                final docs = snapshot.data?.docs ?? [];

                // Mark received messages as read
                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['receiverId'] == _myEmail && (data['isRead'] == false || data['isRead'] == null)) {
                    doc.reference.update({'isRead': true});
                  }
                }
                
                // Sort client-side to avoid needing a composite index and to handle null timestamps
                final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
                sortedDocs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['timestamp'] as Timestamp?;
                  final bTime = bData['timestamp'] as Timestamp?;
                  if (aTime == null) return 1; // Put nulls at the end
                  if (bTime == null) return -1;
                  return aTime.compareTo(bTime);
                });

                if (sortedDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.messageCircle, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: GoogleFonts.manrope(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Start the conversation!',
                          style: GoogleFonts.manrope(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: sortedDocs.length,
                  itemBuilder: (context, index) {
                    final data = sortedDocs[index].data() as Map<String, dynamic>;
                    final bool isMe = data['senderId'] == _myEmail;
                    return _buildMessageBubble(data, isMe);
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe) {
    final String text = data['text'] ?? '';
    final timestamp = data['timestamp'] as Timestamp?;
    String timeStr = '';
    if (timestamp != null) {
      final date = timestamp.toDate();
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final ampm = date.hour >= 12 ? 'PM' : 'AM';
      timeStr = '$hour:$minute $ampm';
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              Container(
                margin: const EdgeInsets.only(right: 8, bottom: 2),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                  child: Text(
                    widget.name[0],
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryRed,
                    ),
                  ),
                ),
              ),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? AppTheme.primaryRed : const Color(0xFFF1F3F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      text,
                      style: GoogleFonts.manrope(
                        color: isMe ? Colors.white : const Color(0xFF1A1C1E),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                  if (timeStr.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                      child: Text(
                        timeStr,
                        style: GoogleFonts.manrope(
                          color: const Color(0xFFA0AEC0),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(LucideIcons.plus, color: Colors.grey, size: 22),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(LucideIcons.image, color: Colors.grey, size: 22),
              onPressed: () {},
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _sendMessage(),
                  style: GoogleFonts.manrope(
                    fontSize: 13.5,
                    color: AppTheme.neutralColor,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      color: Color(0xFFADB5BD),
                      fontSize: 13.5,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 36,
              width: 36,
              decoration: const BoxDecoration(
                color: AppTheme.primaryRed,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(LucideIcons.send, color: Colors.white, size: 16),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
