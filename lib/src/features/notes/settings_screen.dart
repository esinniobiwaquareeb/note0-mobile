import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/usage_service.dart';
import '../../core/utils/toast_utils.dart';
import '../auth/login_screen.dart';
import '../pro/subscription_history_screen.dart';


class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: isDark ? Colors.white : Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _SettingsGroup(
            title: 'Appearance',
            children: [
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                trailing: Switch.adaptive(
                  value: isDark,
                  activeColor: Colors.blue,
                  onChanged: (val) {
                    ref.read(themeProvider.notifier).toggleTheme(val);
                  },
                ),
              ),
            ],
          ),
          const Gap(24),
          _SettingsGroup(
            title: 'Account',
            children: [
              FutureBuilder<bool>(
                future: ref.read(authServiceProvider).isAuthenticated(),
                builder: (context, snapshot) {
                  final isAuthed = snapshot.data ?? false;
                  if (isAuthed) return const SizedBox.shrink();
                  
                  return _SettingsTile(
                    icon: Icons.login,
                    title: 'Log In / Sign Up',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.history,
                title: 'Subscription History',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SubscriptionHistoryScreen()),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.star_outline,
                title: 'Rate Note0',
                onTap: () => _launchURL('https://apps.apple.com/app/id6470000000'),
              ),
              _SettingsTile(
                icon: Icons.share_outlined,
                title: 'Share with Friends',
                onTap: () {
                  final box = context.findRenderObject() as RenderBox?;
                  Share.share(
                    'Check out Note0, the best AI note-taking app! https://note0.app',
                    sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.chat_bubble_outline,
                title: 'Feedback',
                onTap: () => _launchURL('mailto:support@note0.app'),
              ),
            ],
          ),
          const Gap(24),
          _SettingsGroup(
            title: 'Legal',
            children: [
              _SettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms of Use',
                onTap: () => _launchURL('https://note0.app/terms-of-use'),
              ),
              _SettingsTile(
                icon: Icons.security_outlined,
                title: 'Privacy Policy',
                onTap: () => _launchURL('https://note0.app/privacy-policy'),
              ),
              _SettingsTile(
                icon: Icons.restore,
                title: 'Restore Purchase',
                onTap: () {
                  ToastUtils.showSuccess(context, 'Purchases restored successfully');
                },
              ),
            ],
          ),
          const Gap(24),
          _SettingsGroup(
            children: [
              FutureBuilder<String>(
                future: ref.read(usageServiceProvider).getGuestId(),
                builder: (context, snapshot) {
                  final guestId = snapshot.data ?? '...';
                  final shortId = guestId.length > 8 ? '${guestId.substring(0, 8)}...' : guestId;
                  
                  return _SettingsTile(
                    icon: Icons.person_outline,
                    title: 'System ID',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          shortId,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                        const Gap(8),
                        Icon(Icons.copy, size: 18, color: Colors.grey[400]),
                      ],
                    ),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: guestId));
                      ToastUtils.showInfo(context, 'System ID copied to clipboard');
                    },
                  );
                },
              ),
            ],
          ),

        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch $url : $e');
    }
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({this.title, required this.children});
  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title!.toUpperCase(),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: isDark ? Colors.grey[400] : Colors.grey[600], size: 24),
            const Gap(16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            if (trailing != null) trailing! else Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}
