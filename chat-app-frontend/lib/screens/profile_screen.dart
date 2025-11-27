import 'package:chat_app_frontend/notifiers/chat_app_data_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../config/string_constants.dart';
import '../models/user.dart';
import '../services/snackbar_service.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            child: _buildProfileContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppTheme.secondaryBackground,
      height: AppConstants.headerHeight,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: ()=> Provider.of<ChatAppDataNotifier>(context, listen: false).profileVisible.value = false,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 16),
          const Text(
            StringConstants.profile,
            style: TextStyle(
              color: AppTheme.textPrimary,
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
        const SizedBox(height: 32),
        _buildNameSection(),
        const Divider(height: 1, color: AppTheme.dividerColor),
        _buildAboutSection(),
        const Divider(height: 1, color: AppTheme.dividerColor),
        _buildEmailSection(),
      ],
    );
  }

  Widget _buildProfilePicture() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 70,
          backgroundColor: AppTheme.secondaryBackground,
          backgroundImage: widget.user.avatarUrl != null
              ? NetworkImage(widget.user.avatarUrl!)
              : null,
          child: widget.user.avatarUrl == null
              ? Text(
                  widget.user.firstName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                )
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.accentColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.camera_alt, size: 20),
              color: Colors.white,
              onPressed: _showImagePickerSnackbar,
            ),
          ),
        ),
      ],
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

  void _showImagePickerSnackbar() {
    SnackbarService.showInfo(StringConstants.imagePickerComingSoon);
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
                color: AppTheme.textSecondary,
                fontSize: 13,
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
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  icon,
                  size: 20,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
