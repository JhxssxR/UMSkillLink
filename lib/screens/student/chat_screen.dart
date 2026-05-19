import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';
import '../../components/custom_app_bar.dart';

class ChatScreen extends StatefulWidget {
  final String name;
  const ChatScreen({super.key, required this.name});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late List<Map<String, dynamic>> _messages;
  bool _isDownloading = false;
  bool _isDownloaded = false;

  @override
  void initState() {
    super.initState();
    _initializeMessages();
  }

  void _initializeMessages() {
    if (widget.name == 'Marco Santos' || widget.name.contains('Marco')) {
      _messages = [
        {'isDateDivider': true, 'text': 'Today'},
        {
          'text':
              'Hi Juan! Are we still good for our Calculus II tutoring session today at 2:00 PM?',
          'isMe': false,
          'time': '10:12 AM',
        },
        {
          'text':
              'Yes, Marco! All set. I already prepared my questions on double integrals.',
          'isMe': true,
          'time': '10:15 AM',
        },
        {
          'text':
              'Awesome! Here is a quick calculus reference sheet we can use during the session. Please download and review it beforehand.',
          'isMe': false,
          'time': '10:16 AM',
        },
        {
          'isAttachment': true,
          'attachmentName': 'Calculus_Ref_Sheet.pdf',
          'attachmentSize': '1.2 MB • PDF Document',
          'isMe': false,
          'time': '10:16 AM',
        },
        {'isBookingBanner': true, 'text': 'Booking Confirmed: Today, 2:00 PM'},
        {
          'text': 'Thanks, downloaded it! See you at 2:00 PM.',
          'isMe': true,
          'time': '10:20 AM',
        },
      ];
    } else {
      _messages = [
        {'isDateDivider': true, 'text': 'Today'},
        {
          'text': 'Hello! Thanks for reaching out. How can I help you today?',
          'isMe': false,
          'time': 'Just now',
        },
      ];
    }
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    final text = _controller.text.trim();
    _controller.clear();

    setState(() {
      _messages.add({'text': text, 'isMe': true, 'time': _formatCurrentTime()});
    });

    _scrollToBottom();

    // Trigger premium auto-reply for immersive experience
    Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'text':
              'Sounds good! I am checking my dashboard now. Let\'s make sure we are ready.',
          'isMe': false,
          'time': _formatCurrentTime(),
        });
      });
      _scrollToBottom();
    });
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12
        ? now.hour - 12
        : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
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

  void _handleDownload() {
    if (_isDownloaded) return;
    setState(() {
      _isDownloading = true;
    });

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _isDownloaded = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Calculus_Ref_Sheet.pdf downloaded successfully!',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
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
                Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: const BoxDecoration(
                    color: AppTheme.secondaryGold,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: NetworkImage(
                      widget.name.contains('Marco')
                          ? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150'
                          : 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
                    ),
                    onBackgroundImageError: (exception, stackTrace) {},
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
            icon: const Icon(
              LucideIcons.video,
              color: AppTheme.primaryRed,
              size: 20,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              LucideIcons.phone,
              color: AppTheme.primaryRed,
              size: 20,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              LucideIcons.moreVertical,
              color: Colors.grey,
              size: 20,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];

                // Render Date Divider
                if (message['isDateDivider'] == true) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9ECEF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message['text'],
                        style: GoogleFonts.manrope(
                          color: const Color(0xFF6C757D),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }

                // Render Booking Banner
                if (message['isBookingBanner'] == true) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E6),
                        border: Border.all(
                          color: AppTheme.secondaryGold.withOpacity(0.4),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.secondaryGold.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.calendar,
                            color: AppTheme.secondaryGold,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            message['text'],
                            style: GoogleFonts.manrope(
                              color: const Color(0xFF8F6000),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final isMe = message['isMe'] == true;

                // Render Attachment Card
                if (message['isAttachment'] == true) {
                  return _buildAttachmentCard(message);
                }

                return _buildMessageBubble(message, isMe);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              Container(
                margin: const EdgeInsets.only(right: 8, bottom: 4),
                padding: const EdgeInsets.all(1),
                decoration: const BoxDecoration(
                  color: AppTheme.secondaryGold,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: NetworkImage(
                    widget.name.contains('Marco')
                        ? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150'
                        : 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
                  ),
                  onBackgroundImageError: (exception, stackTrace) {},
                ),
              ),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? AppTheme.primaryRed : Colors.white,
                      border: isMe
                          ? null
                          : Border.all(
                              color: AppTheme.primaryRed.withOpacity(0.08),
                              width: 1,
                            ),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      message['text'],
                      style: GoogleFonts.manrope(
                        color: isMe ? Colors.white : const Color(0xFF2D3748),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message['time'],
                          style: GoogleFonts.manrope(
                            color: const Color(0xFFA0AEC0),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            LucideIcons.checkCheck,
                            color: AppTheme.primaryRed,
                            size: 13,
                          ),
                        ],
                      ],
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

  Widget _buildAttachmentCard(Map<String, dynamic> message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 32),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: AppTheme.primaryRed.withOpacity(0.12),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.fileText,
                      color: AppTheme.primaryRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['attachmentName'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message['attachmentSize'],
                          style: GoogleFonts.manrope(
                            color: const Color(0xFF718096),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleDownload,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isDownloaded
                            ? const Color(0xFFE8F5E9)
                            : AppTheme.primaryRed.withOpacity(0.05),
                        border: Border.all(
                          color: _isDownloaded
                              ? const Color(0xFF81C784)
                              : AppTheme.primaryRed.withOpacity(0.12),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isDownloading) ...[
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryRed,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Downloading...',
                              style: GoogleFonts.manrope(
                                color: AppTheme.primaryRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ] else if (_isDownloaded) ...[
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF2E7D32),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Downloaded',
                              style: GoogleFonts.manrope(
                                color: const Color(0xFF2E7D32),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ] else ...[
                            const Icon(
                              LucideIcons.download,
                              color: AppTheme.primaryRed,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Download Reference Sheet',
                              style: GoogleFonts.manrope(
                                color: AppTheme.primaryRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
                icon: const Icon(
                  LucideIcons.send,
                  color: Colors.white,
                  size: 16,
                ),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
