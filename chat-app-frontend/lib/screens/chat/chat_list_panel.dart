import 'package:chat_app_frontend/config/constants.dart';
import 'package:chat_app_frontend/notifiers/chat_app_data_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
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

  // List<Room> get _filteredRooms {
  //   // if (_searchQuery.isEmpty) return _displayRooms;
  //   // return _displayRooms
  //   //     .where((room) =>
  //   //         room.name.toLowerCase().contains(_searchQuery.toLowerCase()))
  //   //     .toList();
  // }

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
      color: AppTheme.primaryBackground,
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
      color: AppTheme.secondaryBackground,
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
    return GestureDetector(
      onTap: () => Provider.of<ChatAppDataNotifier>(context, listen: false).profileVisible.value = true,
      child: CircleAvatar(
        radius: 20,
        backgroundColor: AppTheme.accentColor,
        backgroundImage: currentUser.avatarUrl != null ? NetworkImage(currentUser.avatarUrl!) : null,
        child: currentUser.avatarUrl == null
            ? Text(
                currentUser.firstName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.group_add_outlined),
          color: AppTheme.iconColor,
          onPressed: _showNewGroupSnackbar,
          tooltip: StringConstants.newGroup,
        ),
        IconButton(
          icon: const Icon(Icons.chat_outlined),
          color: AppTheme.iconColor,
          onPressed: _showNewChatSnackbar,
          tooltip: StringConstants.newChat,
        ),
        _buildMoreMenu(),
      ],
    );
  }

  Widget _buildMoreMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppTheme.iconColor),
      color: AppTheme.secondaryBackground,
      onSelected: _handleMenuSelection,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'logout',
          child: Text(
            StringConstants.logout,
            style: TextStyle(color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }

  void _handleMenuSelection(String value) {
    if (value == 'logout') {
      widget.onLogout();
    }
  }

  void _showNewGroupSnackbar() {
    showDialog(
      context: context,
      builder: (context) => CreateGroupDialog(
        onGroupCreated: (room) {
          // Room created and navigated by dialog
          // widget.onRoomSelected(room);
        },
      ),
    );
  }

  void _showNewChatSnackbar() {
    SnackbarService.showInfo(StringConstants.newChatComingSoon);
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppTheme.primaryBackground,
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
        decoration: InputDecoration(
          hintText: StringConstants.searchOrStartNewChat,
          hintStyle: const TextStyle(color: AppTheme.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppTheme.iconColor),
          filled: true,
          fillColor: AppTheme.secondaryBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        style: const TextStyle(color: AppTheme.textPrimary),
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
          color: AppTheme.textSecondary,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildChatItem(Room room, bool isSelected) {
    return InkWell(
      onTap: () => Provider.of<ChatAppDataNotifier>(context, listen: false).roomSelected(room),
      child: Container(
        decoration: BoxDecoration(color: isSelected ? AppTheme.secondaryBackground : Colors.transparent, borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    return CircleAvatar(
      radius: 26,
      backgroundColor: AppTheme.accentColor.withOpacity(0.3),
      child: room.type == 'GROUP'
          ? const Icon(Icons.group, color: AppTheme.accentColor)
          : Text(
              room.name[0].toUpperCase(),
              style: const TextStyle(
                color: AppTheme.accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
    );
  }

  Widget _buildRoomInfo(Room room) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRoomHeader(room),
          const SizedBox(height: 4),
          _buildRoomPreview(room),
        ],
      ),
    );
  }

  Widget _buildRoomHeader(Room room) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            room.name,
            style: const TextStyle(
              color: AppTheme.textPrimary,
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
            color: room.unreadCount > 0 ? AppTheme.accentColor : AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomPreview(Room room) {
    return Row(
      children: [
        Expanded(
          child: Text(
            room.lastMessage ?? 'No messages yet',
            style: TextStyle(
              color: room.unreadCount > 0 ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        if (room.unreadCount > 0) ...[_buildUnreadBadge(room)],
      ],
    );
  }

  Widget _buildUnreadBadge(Room room) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.accentColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          room.unreadCount.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
