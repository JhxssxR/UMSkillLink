import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../models/mock_data.dart';
import '../../components/custom_app_bar.dart';
import '../student/chat_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class TutorMessagesScreen extends StatelessWidget {
  const TutorMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const CustomAppBar(
        subtitle: 'Messages Inbox',
        centerTitle: false,
        showBackButton: false,
      ),
      body: ListView.builder(
        itemCount: MockData.messages.length,
        itemBuilder: (context, index) {
          final message = MockData.messages[index];
          return _buildMessageItem(
            context,
            message['name'],
            message['message'],
            message['time'],
            message['isUnread'],
          );
        },
      ),
    );
  }

  Widget _buildMessageItem(
    BuildContext context,
    String name,
    String message,
    String time,
    bool isUnread,
  ) {
    return Container(
      color: isUnread
          ? AppTheme.primaryRed.withValues(alpha: 0.05)
          : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.2),
          child: Text(
            name[0],
            style: GoogleFonts.manrope(
              color: AppTheme.primaryRed,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: GoogleFonts.manrope(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            color: isUnread ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              time,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: isUnread ? AppTheme.primaryRed : Colors.grey.shade500,
              ),
            ),
            if (isUnread) ...[
              const SizedBox(height: 4),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryRed,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatScreen(name: name)),
          );
        },
      ),
    );
  }
}
