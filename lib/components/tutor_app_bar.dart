import 'package:flutter/material.dart';
import 'custom_app_bar.dart';

class TutorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final bool centerTitle;
  final Widget? leading;
  final List<Widget>? actions;

  const TutorAppBar({
    super.key,
    this.showBackButton = true,
    this.centerTitle = false,
    this.leading,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return CustomAppBar(
      title: 'UM SkillLink',
      subtitle: 'TUTOR PORTAL',
      centerTitle: centerTitle,
      showBackButton: showBackButton,
      leading: leading,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
