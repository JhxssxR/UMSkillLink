import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/app_theme.dart';
import '../widgets/tutor_layout.dart';
import 'custom_app_bar.dart';
import 'notification_bell.dart';

class TutorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final bool centerTitle;
  final String? subtitle;

  const TutorAppBar({
    super.key,
    this.showBackButton = true,
    this.centerTitle = false,
    this.subtitle = 'TUTOR PORTAL',
  });

  @override
  Widget build(BuildContext context) {
    return CustomAppBar(
      title: 'UM SkillLink',
      subtitle: subtitle,
      centerTitle: centerTitle,
      showBackButton: showBackButton,
      actions: [
        const NotificationBell(iconColor: Color(0xFF7A7C80)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            context.findAncestorStateOfType<TutorLayoutState>()?.setIndex(4);
          },
          child: Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryRed.withOpacity(0.15),
                child: const Icon(
                  LucideIcons.user,
                  size: 18,
                  color: AppTheme.primaryRed,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
