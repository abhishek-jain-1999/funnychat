import 'package:chat_app_frontend/notifiers/chat_app_data_notifier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../config/string_constants.dart';
import '../../models/message.dart';
import '../../services/snackbar_service.dart';

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


  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final ValueNotifier<bool> _hasText = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final chatData = Provider.of<ChatAppDataNotifier>(context);
    return Container(
      color: AppTheme.primaryBackground,
      child: Column(
        children: [
          _buildHeader(chatData),
          buildChatArea(chatData),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget buildChatArea(ChatAppDataNotifier chatData) {
    return ValueListenableBuilder(
      valueListenable: chatData.messageNotifier,
      builder: (context, messages, child) {
        _scrollToBottom();
        return Expanded(
          child: messages.isEmpty ? _buildEmptyState() : _buildMessagesListView(messages),
        );
      },
    );
  }


  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        '${StringConstants.noMessagesYet}\n${StringConstants.sayHi}',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildMessagesListView(List<Message> messages) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const NetworkImage(
            'https://i.pinimg.com/736x/d3/6b/cc/d36bcceceaa1d390489ec70d93154311.jpg',
          ),
          fit: BoxFit.cover,
          opacity: 0.05,
          onError: (_, __) {},
        ),
      ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
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
      color: AppTheme.secondaryBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      height: AppConstants.headerHeight,
      child: Row(
        children: [
          if (widget.onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back,),
              color: AppTheme.iconColor,
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
    return ValueListenableBuilder(
      valueListenable: chatData.roomsNotifier,
      builder: (__, room, _) {
          if (room == null) {
            return const SizedBox.shrink();
          }
          return CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.accentColor.withOpacity(0.3),
          child: room.type == 'GROUP'
              ? const Icon(Icons.group, color: AppTheme.accentColor)
              : Text(
                  room.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.accentColor,
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
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (room.type == 'GROUP')
              Text(
                '${room.participants.length} ${StringConstants.participants}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
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
          color: AppTheme.iconColor,
          onPressed: () {},
          tooltip: StringConstants.videoCall,
        ),
        IconButton(
          icon: const Icon(Icons.call_outlined),
          color: AppTheme.iconColor,
          onPressed: () {},
          tooltip: StringConstants.voiceCall,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          color: AppTheme.iconColor,
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.secondaryBackground.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
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
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final color = isMe
        ? AppTheme.outgoingMessageBubble
        : AppTheme.incomingMessageBubble;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width *
              AppConstants.maxMessageWidth,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(8),
            topRight: const Radius.circular(8),
            bottomLeft: Radius.circular(isMe ? 8 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 8),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatMessageTime(message.createdAt),
              style: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildInputArea() {
    return Container(
      color: AppTheme.secondaryBackground,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.emoji_emotions_outlined),
            color: AppTheme.iconColor,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.attach_file),
            color: AppTheme.iconColor,
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: StringConstants.typeMessage,
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.primaryBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _handleSendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.accentColor,
        shape: BoxShape.circle,
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: _hasText,
        builder: (context, hasText, child) {
          return IconButton(
            icon: Icon(hasText ? Icons.send : Icons.mic),
            color: Colors.white,
            onPressed: hasText
                ? _handleSendMessage
                : _showVoiceRecordingSnackbar,
          );
        },
      ),
    );
  }

  void _showVoiceRecordingSnackbar() {
    SnackbarService.showInfo(StringConstants.voiceRecordingComingSoon);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
