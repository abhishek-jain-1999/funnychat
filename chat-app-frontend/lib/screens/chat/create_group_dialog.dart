import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/string_constants.dart';
import '../../models/room.dart';
import '../../services/api_service.dart';
import '../../services/response_handler.dart';

class CreateGroupDialog extends StatefulWidget {
  final Function(Room) onGroupCreated;

  const CreateGroupDialog({
    super.key,
    required this.onGroupCreated,
  });

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> with SingleTickerProviderStateMixin {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final List<String> _selectedEmails = [];
  bool _isLoading = false;
  String? _groupNameError;
  String? _emailError;
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppAnimations.standard,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: AppAnimations.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: AppAnimations.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  void _addEmail() {
    final email = _emailController.text.trim();

    setState(() => _emailError = null);

    if (email.isEmpty) {
      setState(() => _emailError = StringConstants.enterEmail);
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() => _emailError = StringConstants.invalidEmail);
      return;
    }

    if (_selectedEmails.contains(email)) {
      setState(() => _emailError = StringConstants.duplicateEmail);
      return;
    }

    setState(() {
      _selectedEmails.add(email);
      _emailController.clear();
    });
  }

  void _removeEmail(String email) {
    setState(() {
      _selectedEmails.remove(email);
    });
  }

  Future<void> _createGroup() async {
    setState(() {
      _groupNameError = null;
      _emailError = null;
    });

    final groupName = _groupNameController.text.trim();

    if (groupName.isEmpty) {
      setState(() => _groupNameError = StringConstants.groupNameRequired);
      return;
    }

    if (_selectedEmails.isEmpty) {
      setState(() => _emailError = StringConstants.atLeastOneParticipant);
      return;
    }

    setState(() => _isLoading = true);

    await ResponseHandler.handleApiCall(
      context,
      () async {
        final room = await ApiService.createRoom(
          name: groupName,
          participantEmails: _selectedEmails,
        );
        if (mounted) {
          Navigator.of(context).pop();
          widget.onGroupCreated(room);
        }
      },
      successMessage: StringConstants.groupCreatedSuccessfully,
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final dialogWidth = isMobile ? double.infinity : 450.0;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dialog(
          backgroundColor: AppColors.backgroundCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.standard),
            side: const BorderSide(color: AppColors.backgroundBorder),
          ),
          elevation: 24,
          child: SingleChildScrollView(
            child: Container(
              width: dialogWidth,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        StringConstants.createGroup,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Group Name Field
                  _buildLabel(StringConstants.groupName),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _groupNameController,
                    enabled: !_isLoading,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g. Project Team',
                      hintStyle: const TextStyle(color: AppColors.textPlaceholder),
                      filled: true,
                      fillColor: AppColors.backgroundSubtle,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.standard),
                        borderSide: const BorderSide(color: AppColors.backgroundBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.standard),
                        borderSide: const BorderSide(color: AppColors.backgroundBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.standard),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      errorText: _groupNameError,
                      errorStyle: const TextStyle(color: Color(0xFFE74C3C)),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Email Field
                  _buildLabel(StringConstants.addParticipants),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _emailController,
                          enabled: !_isLoading,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'user@example.com',
                            hintStyle: const TextStyle(color: AppColors.textPlaceholder),
                            filled: true,
                            fillColor: AppColors.backgroundSubtle,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.standard),
                              borderSide: const BorderSide(color: AppColors.backgroundBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.standard),
                              borderSide: const BorderSide(color: AppColors.backgroundBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.standard),
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            errorText: _emailError,
                            errorStyle: const TextStyle(color: Color(0xFFE74C3C)),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _addEmail(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSubtle,
                          borderRadius: BorderRadius.circular(AppRadius.standard),
                          border: Border.all(color: AppColors.backgroundBorder),
                        ),
                        child: IconButton(
                          onPressed: _isLoading ? null : _addEmail,
                          icon: Icon(Icons.add, color: primaryColor),
                          tooltip: StringConstants.addButton,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Selected Emails Display
                  if (_selectedEmails.isNotEmpty) ...[
                    Text(
                      '${StringConstants.participantsAdded} (${_selectedEmails.length})',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedEmails.map((email) {
                        return Chip(
                          label: Text(
                            email,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: AppColors.backgroundSubtle,
                          side: const BorderSide(color: AppColors.backgroundBorder),
                          deleteIcon: const Icon(
                            Icons.close,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                          onDeleted: () => _removeEmail(email),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSubtle,
                        borderRadius: BorderRadius.circular(AppRadius.standard),
                        border: Border.all(color: AppColors.backgroundBorder),
                      ),
                      child: const Center(
                        child: Text(
                          StringConstants.noParticipantsAdded,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text(
                          StringConstants.cancel,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: (_isLoading ||
                                _groupNameController.text.trim().isEmpty ||
                                _selectedEmails.isEmpty)
                            ? null
                            : _createGroup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: AppColors.textInverse,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.standard),
                          ),
                          elevation: 4,
                          shadowColor: primaryColor.withOpacity(0.4),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.textInverse,
                                  ),
                                ),
                              )
                            : const Text(
                                StringConstants.createButton,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}
