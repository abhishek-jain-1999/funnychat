import 'package:flutter/material.dart';
import '../../config/theme.dart';
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

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final List<String> _selectedEmails = [];
  bool _isLoading = false;
  String? _groupNameError;
  String? _emailError;

  @override
  void dispose() {
    _groupNameController.dispose();
    _emailController.dispose();
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
    final dialogWidth = isMobile ? double.infinity : 500.0;

    return Dialog(
      backgroundColor: AppTheme.secondaryBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.iconColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Group Name Field
              const Text(
                StringConstants.groupName,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _groupNameController,
                enabled: !_isLoading,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: StringConstants.enterGroupName,
                  hintStyle: const TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.primaryBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  errorText: _groupNameError,
                  errorStyle: const TextStyle(color: Colors.red),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Email Field
              const Text(
                StringConstants.addParticipants,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      enabled: !_isLoading,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: StringConstants.enterParticipantEmail,
                        hintStyle:
                            const TextStyle(color: AppTheme.textSecondary),
                        filled: true,
                        fillColor: AppTheme.primaryBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        errorText: _emailError,
                        errorStyle: const TextStyle(color: Colors.red),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _addEmail(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _addEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(StringConstants.addButton),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Selected Emails Display
              if (_selectedEmails.isNotEmpty) ...[
                Text(
                  '${StringConstants.participantsAdded} (${_selectedEmails.length})',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
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
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: AppTheme.accentColor,
                      deleteIcon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                      onDeleted: () => _removeEmail(email),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      StringConstants.noParticipantsAdded,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
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
                      style: TextStyle(color: AppTheme.textPrimary),
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
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(StringConstants.createButton),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

