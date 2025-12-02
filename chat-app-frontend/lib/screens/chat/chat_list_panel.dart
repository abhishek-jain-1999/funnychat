import 'package:chat_app_frontend/config/constants.dart';
import 'package:chat_app_frontend/notifiers/chat_app_data_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/string_constants.dart';
import '../../models/room.dart';
import '../../services/snackbar_service.dart';
import 'create_group_dialog.dart';

class ChatListPanel extends StatefulWidget {
  final VoidCallback onLogout;

  const ChatListPanel({
    super.key,
    required this.onLogout,
  });

  @override
  State<ChatListPanel> createState() => _ChatListPanelState();
}

class _ChatListPanelState extends State<ChatListPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      return StringConstants.yesterday;
    } else if (difference.inDays < 7) {
      return StringConstants.dayNames[time.weekday - 1];
    } else {
      final day = time.day.toString().padLeft(2, '0');
      final month = time.month.toString().padLeft(2, '0');
      final year = (time.year % 100).toString().padLeft(2, '0');
      return '$day/$month/$year';
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildChatListView();
  }

  Widget _buildChatListView() {
    var chatData = Provider.of<ChatAppDataNotifier>(context);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        border: Border(
          right: BorderSide(
            color: AppColors.backgroundBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(chatData),
          _buildSearchBar(),
          _buildChatList(chatData),
        ],
      ),
    );
  }

  Widget _buildHeader(ChatAppDataNotifier chatData) {
    return Container(
      color: AppColors.backgroundCard,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      height: AppConstants.headerHeight,
      child: Row(
        children: [
          _buildProfileAvatar(chatData),
          const Spacer(),
          _buildHeaderActions(),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(ChatAppDataNotifier chatData) {
    final currentUser = chatData.currentUser;
    if (currentUser == null) {
      return const SizedBox.shrink();
    }
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return GestureDetector(
      onTap: () => Provider.of<ChatAppDataNotifier>(context, listen: false).profileVisible.value = true,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.backgroundSubtle,
            backgroundImage: currentUser.avatarUrl != null ? NetworkImage(currentUser.avatarUrl!) : null,
            child: currentUser.avatarUrl == null
                ? Text(
                    currentUser.firstName[0].toUpperCase(),
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.neonGreen,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.backgroundCard, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.group_add_outlined,
          onPressed: _showNewGroupSnackbar,
          tooltip: StringConstants.newGroup,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundSubtle,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        color: AppColors.textSecondary,
        onPressed: onPressed,
        tooltip: tooltip,
        hoverColor: AppColors.textPrimary.withOpacity(0.1),
        splashRadius: 24,
      ),
    );
  }

  void _showNewGroupSnackbar() {
    showDialog(
      context: context,
      builder: (context) => CreateGroupDialog(
        onGroupCreated: (room) {
          // Room created and navigated by dialog
        },
      ),
    );
  }

  void _showNewChatSnackbar() {
    SnackbarService.showInfo(StringConstants.newChatComingSoon);
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.backgroundCard,
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
        decoration: InputDecoration(
          hintText: StringConstants.searchOrStartNewChat,
          hintStyle: const TextStyle(color: AppColors.textPlaceholder),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.backgroundSubtle,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        style: const TextStyle(color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildChatList(ChatAppDataNotifier chatData) {
    return ValueListenableBuilder(
        valueListenable: chatData.listRoomsNotifier,
        builder: (context, filteredRooms, child) {
          return Expanded(
            child: filteredRooms.isEmpty
                ? _buildEmptyState()
                : _buildListView(filteredRooms, chatData),
          );
        });
  }

  Widget _buildListView(List<Room> filteredRooms, ChatAppDataNotifier chatData) {
    return ValueListenableBuilder(
      valueListenable: chatData.roomsNotifier,
      builder: (context, value, child) {
        return ListView.builder(
          itemCount: filteredRooms.length,
          itemBuilder: (context, index) {
            final room = filteredRooms[index];
            final isSelected = value?.id == room.id;
            return _buildChatItem(room, isSelected);
          },
        );
      }
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        _searchQuery.isEmpty ? StringConstants.noChats : StringConstants.noChatsFound,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildChatItem(Room room, bool isSelected) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return InkWell(
      onTap: () => Provider.of<ChatAppDataNotifier>(context, listen: false).roomSelected(room),
      hoverColor: AppColors.backgroundSubtle,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.backgroundSubtle : Colors.transparent,
          border: isSelected 
              ? Border(left: BorderSide(color: primaryColor, width: 4))
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            _buildRoomAvatar(room),
            const SizedBox(width: 12),
            _buildRoomInfo(room),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomAvatar(Room room) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.backgroundSubtle,
      child: room.type == 'GROUP'
          ? Icon(Icons.group, color: primaryColor)
          : Text(
              room.name[0].toUpperCase(),
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
    );
  }

  Widget _buildRoomInfo(Room room) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  room.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTime(room.lastMessageTime),
                style: TextStyle(
                  color: room.unreadCount > 0 ? primaryColor : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: room.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  room.lastMessage ?? 'No messages yet',
                  style: TextStyle(
                    color: room.unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: room.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (room.unreadCount > 0) ...[_buildUnreadBadge(room, primaryColor)],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnreadBadge(Room room, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          room.unreadCount.toString(),
          style: const TextStyle(
            color: AppColors.textInverse,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
