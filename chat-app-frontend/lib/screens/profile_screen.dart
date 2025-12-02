import 'package:chat_app_frontend/notifiers/chat_app_data_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/constants.dart';
import '../config/string_constants.dart';
import '../models/user.dart';
import '../services/snackbar_service.dart';
import '../services/api_service.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  final List<ThemeOption> _themeOptions = [
    ThemeOption('Amber', AppColors.amber),
    ThemeOption('Neon Yellow', AppColors.neonYellow),
    ThemeOption('Neon Green', AppColors.neonGreen),
    ThemeOption('Neon Cyan', AppColors.neonCyan),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppAnimations.slow,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppAnimations.slide,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => _buildLogoutConfirmDialog(),
    );

    if (shouldLogout == true && mounted) {
      await ApiService.clearToken();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildLogoutConfirmDialog() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Dialog(
      backgroundColor: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.standard),
        side: const BorderSide(color: AppColors.backgroundBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.logout,
              color: Color(0xFFE74C3C),
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Logout',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Are you sure you want to logout?',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.backgroundBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE74C3C),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Logout'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        color: AppColors.backgroundCard,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: _buildProfileContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: AppConstants.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(
          bottom: BorderSide(
            color: AppColors.backgroundBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Provider.of<ChatAppDataNotifier>(context, listen: false)
                .profileVisible.value = false,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 16),
          const Text(
            StringConstants.profile,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return Column(
      children: [
        const SizedBox(height: 32),
        _buildProfilePicture(),
        const SizedBox(height: 24),
        _buildUserInfo(),
        const SizedBox(height: 32),
        _buildThemeSelector(),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Divider(height: 1, color: AppColors.backgroundBorder),
        ),
        _buildNameSection(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Divider(height: 1, color: AppColors.backgroundBorder),
        ),
        _buildAboutSection(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Divider(height: 1, color: AppColors.backgroundBorder),
        ),
        _buildEmailSection(),
        const SizedBox(height: 32),
        _buildLogoutButton(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildProfilePicture() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Stack(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.backgroundSubtle,
            border: Border.all(
              color: AppColors.backgroundBorder,
              width: 2,
            ),
          ),
          child: widget.user.avatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    widget.user.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildAvatarFallback();
                    },
                  ),
                )
              : _buildAvatarFallback(),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
              boxShadow: AppShadows.getPrimaryShadow(primaryColor),
            ),
            child: const Icon(
              Icons.camera_alt,
              size: 16,
              color: AppColors.textInverse,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarFallback() {
    return Center(
      child: Text(
        widget.user.firstName[0].toUpperCase(),
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      children: [
        Text(
          widget.user.fullName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '@${widget.user.email.split('@')[0]}',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THEME COLOR',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Consumer<FlashChatTheme>(
            builder: (context, themeProvider, _) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _themeOptions.length,
                itemBuilder: (context, index) {
                  final option = _themeOptions[index];
                  final isSelected = themeProvider.primaryColor == option.color;

                  return _buildThemeOption(
                    option.name,
                    option.color,
                    isSelected,
                    () {
                      themeProvider.setThemeColor(option.color);
                      SnackbarService.showSuccess('Theme changed to ${option.name}');
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String name, Color color, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.standard),
      child: AnimatedContainer(
        duration: AppAnimations.standard,
        curve: AppAnimations.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundSubtle,
          borderRadius: BorderRadius.circular(AppRadius.standard),
          border: Border.all(
            color: isSelected ? color : AppColors.backgroundBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameSection() {
    return _buildInfoSection(
      label: StringConstants.name,
      value: widget.user.fullName,
      icon: Icons.edit,
      onTap: _showEditNameSnackbar,
    );
  }

  Widget _buildAboutSection() {
    return _buildInfoSection(
      label: StringConstants.about,
      value: widget.user.about ?? StringConstants.aboutDefault,
      icon: Icons.edit,
      onTap: _showEditAboutSnackbar,
    );
  }

  Widget _buildEmailSection() {
    return _buildInfoSection(
      label: StringConstants.email,
      value: widget.user.email,
      icon: Icons.content_copy,
      onTap: _copyEmailToClipboard,
    );
  }

  void _showEditNameSnackbar() {
    SnackbarService.showInfo(StringConstants.editNameComingSoon);
  }

  void _showEditAboutSnackbar() {
    SnackbarService.showInfo(StringConstants.editAboutComingSoon);
  }

  void _copyEmailToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.user.email));
    SnackbarService.showSuccess(StringConstants.emailCopiedToClipboard);
  }

  Widget _buildInfoSection({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  icon,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: _handleLogout,
          icon: const Icon(Icons.logout, size: 20),
          label: const Text(
            'Logout',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFE74C3C),
            side: const BorderSide(
              color: Color(0xFFE74C3C),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.standard),
            ),
          ),
        ),
      ),
    );
  }
}

class ThemeOption {
  final String name;
  final Color color;

  ThemeOption(this.name, this.color);
}
