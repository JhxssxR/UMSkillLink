import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/app_theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final bool centerTitle;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? customTitleWidget;

  const CustomAppBar({
    super.key,
    this.title = 'UM SkillLink',
    this.subtitle,
    this.showBackButton = true,
    this.centerTitle = true,
    this.actions,
    this.leading,
    this.customTitleWidget,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      automaticallyImplyLeading: false,
      centerTitle: centerTitle,
      leading:
          leading ??
          (showBackButton
              ? IconButton(
                  icon: const Icon(
                    LucideIcons.arrowLeft,
                    color: Color(0xFF1A1C1E),
                  ),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                )
              : null),
      title:
          customTitleWidget ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/um_logo.png',
                height: subtitle != null ? 32 : 28,
                errorBuilder: (context, error, stackTrace) => Icon(
                  LucideIcons.graduationCap,
                  color: AppTheme.primaryRed,
                  size: subtitle != null ? 32 : 28,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      color: AppTheme.primaryRed,
                      fontWeight: FontWeight.w800,
                      fontSize: subtitle != null ? 16 : 18,
                      letterSpacing: subtitle != null ? 0 : -0.5,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        color: const Color(0xFF7A7C80),
                        letterSpacing: 0.5,
                      ),
                    ),
                ],
              ),
            ],
          ),
      actions:
          actions ??
          [
            IconButton(
              icon: const Icon(
                LucideIcons.helpCircle,
                color: Color(0xFF7A7C80),
              ),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
          ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
