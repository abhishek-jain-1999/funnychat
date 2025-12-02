
import 'package:chat_app_frontend/notifiers/chat_app_data_notifier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/string_constants.dart';
import '../../config/app_theme.dart';
import '../../models/message.dart';
import '../../notifiers/media_upload_notifier.dart';
import '../../services/snackbar_service.dart';
import '../../widgets/media_upload_progress.dart';

class ChatPanel extends StatefulWidget {
  final VoidCallback? onBack;

  const ChatPanel({
    super.key,
    this.onBack,
  });

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final GlobalKey<OverlayState> _uploadOverlayKey = GlobalKey<OverlayState>();
  OverlayEntry? _uploadOverlayEntry;
  MediaUploadNotifier? _mediaUploadNotifier;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  final ValueNotifier<bool> _hasText = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uploader = Provider.of<ChatAppDataNotifier>(context, listen: false).mediaUploadNotifier;
    if (_mediaUploadNotifier != uploader) {
      _mediaUploadNotifier?.removeListener(_handleUploadStateChanged);
      _mediaUploadNotifier = uploader;
      _mediaUploadNotifier?.addListener(_handleUploadStateChanged);
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleUploadStateChanged());
    }
  }

  @override
  void dispose() {
    _mediaUploadNotifier?.removeListener(_handleUploadStateChanged);
    _removeUploadOverlay();
    _messageController.dispose();
    _scrollController.dispose();
    _hasText.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _hasText.value = _messageController.text
        .trim()
        .isNotEmpty;
    if (kIsWeb) {
      _handleWebEnterKey();
    }
  }

  void _handleWebEnterKey() {
    final raw = _messageController.text;
    if (raw.endsWith('\n')) {
      final cleaned = raw.trim();
      _messageController.text = cleaned;
      _messageController.selection =
          TextSelection.collapsed(offset: _messageController.text.length);
      if (cleaned.isNotEmpty) {
        _handleSendMessage();
      }
    }
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

  void _handleSendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    Provider.of<ChatAppDataNotifier>(context, listen: false).sendMessage(content: text);
    _messageController.clear();
  }

  void _handleUploadStateChanged() {
    final notifier = _mediaUploadNotifier;
    if (notifier == null) return;

    final hasActiveUploads = notifier.uploads.values.any(
      (upload) => upload.status != MediaUploadStatus.completed,
    );

    if (!hasActiveUploads) {
      _removeUploadOverlay();
      return;
    }

    final overlayState = _uploadOverlayKey.currentState;
    if (overlayState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleUploadStateChanged());
      return;
    }

    if (_uploadOverlayEntry == null) {
      _uploadOverlayEntry = OverlayEntry(
        builder: (context) => _buildUploadOverlay(),
      );
      overlayState.insert(_uploadOverlayEntry!);
    } else {
      _uploadOverlayEntry!.markNeedsBuild();
    }
  }

  void _removeUploadOverlay() {
    _uploadOverlayEntry?.remove();
    _uploadOverlayEntry = null;
  }

  Widget _buildUploadOverlay() {
    final notifier = _mediaUploadNotifier;
    if (notifier == null) return const SizedBox.shrink();

    final activeUploads = notifier.uploads.entries
        .where((entry) => entry.value.status != MediaUploadStatus.completed)
        .map((entry) => entry.key)
        .toList();

    if (activeUploads.isEmpty) {
      return const SizedBox.shrink();
    }

    final uploadWidgets = activeUploads
        .map(
          (clientId) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: MediaUploadProgress(
              clientId: clientId,
              mediaUploadNotifier: notifier, // Pass the notifier directly
            ),
          ),
        )
        .toList();

    return Positioned(
      right: 16,
      top: 16,
      child: SafeArea(
        child: Material(
          color: AppColors.backgroundCard.withOpacity(0.95),
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud_upload, color: Theme.of(context).colorScheme.primary, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Media uploads',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: AppColors.backgroundBorder),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: uploadWidgets,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatData = Provider.of<ChatAppDataNotifier>(context);
    final content = Container(
      color: AppColors.backgroundBase,
      child: Column(
        children: [
          _buildHeader(chatData),
          Expanded(
            child: buildChatArea(chatData),
          ),
          _buildInputArea(),
        ],
      ),
    );

    return Stack(
      children: [
        content,
        Positioned.fill(
          child: Overlay(
            key: _uploadOverlayKey,
            initialEntries: const [],
          ),
        ),
      ],
    );
  }

  Widget buildChatArea(ChatAppDataNotifier chatData) {
    return ValueListenableBuilder(
      valueListenable: chatData.messageNotifier,
      builder: (context, messages, child) {
        _scrollToBottom();
        return messages.isEmpty ? _buildEmptyState() : _buildMessagesListView(messages);
      },
    );
  }

  Widget _buildEmptyState() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.comments_disabled_outlined,
            size: 48,
            color: primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Welcome to FlashChat',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            StringConstants.sayHi,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesListView(List<Message> messages) {
    return Container(
      color: AppColors.backgroundBase,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) => _buildMessageRow(index, messages),
      ),
    );
  }

  Widget _buildMessageRow(int index, List<Message> messages) {
    final message = messages[index];
    final showDateHeader = index == 0 ||
        !_isSameDay(
          messages[index - 1].createdAt,
          message.createdAt,
        );

    return Column(
      children: [
        if (showDateHeader) _buildDateHeader(message.createdAt),
        _buildMessageBubble(message),
      ],
    );
  }

  Widget _buildHeader(ChatAppDataNotifier chatData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      height: AppConstants.headerHeight,
      decoration: BoxDecoration(
        color: AppColors.backgroundCard.withOpacity(0.8), // Blurred effect simulated
        border: const Border(
          bottom: BorderSide(color: AppColors.backgroundBorder),
        ),
      ),
      child: Row(
        children: [
          if (widget.onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              color: AppColors.textSecondary,
              onPressed: widget.onBack,
            ),
          _buildRoomAvatar(chatData),
          const SizedBox(width: 12),
          Expanded(child: _buildRoomInfo(chatData)),
          _buildHeaderActions(),
        ],
      ),
    );
  }

  Widget _buildRoomAvatar(ChatAppDataNotifier chatData) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return ValueListenableBuilder(
      valueListenable: chatData.roomsNotifier,
      builder: (__, room, _) {
          if (room == null) {
            return const SizedBox.shrink();
          }
          return CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.backgroundSubtle,
          child: room.type == 'GROUP'
              ? Icon(Icons.group, color: primaryColor)
              : Text(
                  room.name[0].toUpperCase(),
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        );
      }
    );
  }

  Widget _buildRoomInfo(ChatAppDataNotifier chatData) {
    return ValueListenableBuilder(
      valueListenable: chatData.roomsNotifier,
      builder: (context, room, child) {
        if (room == null) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              room.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (room.type == 'GROUP')
              Text(
                '${room.participants.length} ${StringConstants.participants}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
          ],
        );
      }
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.videocam_outlined),
          color: AppColors.textSecondary,
          onPressed: () {},
          tooltip: StringConstants.videoCall,
        ),
        IconButton(
          icon: const Icon(Icons.call_outlined),
          color: AppColors.textSecondary,
          onPressed: () {},
          tooltip: StringConstants.voiceCall,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          color: AppColors.textSecondary,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    final text = _formatDateHeader(date, difference);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.backgroundSubtle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.backgroundBorder),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateHeader(DateTime date, Duration difference) {
    if (difference.inDays == 0) {
      return StringConstants.today;
    } else if (difference.inDays == 1) {
      return StringConstants.yesterday;
    } else {
      final month = StringConstants.months[date.month - 1];
      return '$month ${date.day}, ${date.year}';
    }
  }

  Widget _buildMessageBubble(Message message) {
    final isMe = message.isUserSelf;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    
    final color = isMe
        ? primaryColor
        : AppColors.backgroundSubtle;
        
    final textColor = isMe ? AppColors.textInverse : AppColors.textPrimary;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width *
              AppConstants.maxMessageWidth,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(8),
            topRight: const Radius.circular(8),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: isMe 
            ? [BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
          border: isMe ? Border.all(color: AppColors.backgroundBorder, width: 2) : Border.all(color: primaryColor, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Show media if available
            if (message.media != null)
              _buildMediaContent(message.media!),
            // Show text content if available and not empty
            if (message.content.isNotEmpty)
              Text(
                message.content,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              _formatMessageTime(message.createdAt),
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent(MediaAttachment media) {
    if (media.url == null || media.url!.isEmpty) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.backgroundBase,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Processing image...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      );
    }
    
    if (media.mimeType.startsWith('image/')) {
      return GestureDetector(
        onTap: () {
          // Show fullscreen image viewer
          _showFullScreenImage(media.url!);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            media.url!,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.backgroundBase,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.backgroundBase,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.broken_image, color: AppColors.textSecondary),
                ),
              );
            },
          ),
        ),
      );
    } else {
      // For other media types, show a file icon with details
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.backgroundBase.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file, color: AppColors.textInverse),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    media.url?.split('/').last ?? 'Unknown',
                    style: const TextStyle(
                      color: AppColors.textInverse,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${(media.sizeBytes / 1024).round()} KB',
                    style: TextStyle(
                      color: AppColors.textInverse.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(imageUrl),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatMessageTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${formattedHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(
          top: BorderSide(color: AppColors.backgroundBorder),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            color: AppColors.textSecondary,
            onPressed: _pickImage,
            hoverColor: AppColors.backgroundSubtle,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: StringConstants.typeMessage,
                hintStyle: const TextStyle(color: AppColors.textPlaceholder),
                filled: true,
                fillColor: AppColors.backgroundSubtle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  color: AppColors.textSecondary,
                  onPressed: () {},
                ),
              ),
              onSubmitted: (_) => _handleSendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return ValueListenableBuilder<bool>(
      valueListenable: _hasText,
      builder: (context, hasText, child) {
        return Container(
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(hasText ? Icons.send : Icons.mic),
            color: AppColors.textInverse,
            onPressed: hasText
                ? _handleSendMessage
                : _showVoiceRecordingSnackbar,
          ),
        );
      },
    );
  }

  void _showVoiceRecordingSnackbar() {
    SnackbarService.showInfo(StringConstants.voiceRecordingComingSoon);
  }

  Future<void> _pickImage() async {
    try {
      final chatData = Provider.of<ChatAppDataNotifier>(context, listen: false);
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // Get file info
        final file = image;
        final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';
        
        // Generate a unique client ID for tracking
        final clientId = DateTime.now().millisecondsSinceEpoch.toString();
        
        // Start upload process
        await chatData.uploadMedia(
          clientId: clientId,
          roomId: chatData.roomsNotifier.value!.id,
          fileName: image.name,
          mimeType: mimeType,
          file: file,
        );
      }
    } catch (e,st) {
      SnackbarService.showError('Failed to pick image: $e $st');
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
