import 'package:chat_app_frontend/notifiers/chat_app_data_notifier.dart';
import 'package:chat_app_frontend/notifiers/multi_value_listenable_builder.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../config/theme.dart';
import '../config/constants.dart';
import '../config/string_constants.dart';
import '../models/user.dart';
import '../models/room.dart';
import '../services/api_service.dart';
import '../services/response_handler.dart';
import 'profile_screen.dart';
import 'chat/chat_list_panel.dart';
import 'chat/chat_panel.dart';
import 'auth/login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ChatAppDataNotifier _dataNotifier = ChatAppDataNotifier();

  // StreamControllers for managing real-time updates

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _dataNotifier.dispose();
    super.dispose();
  }

  // ==================== Initialization ====================

  Future<void> _initialize() async {
    try {
      final results = await Future.wait([
        ApiService.getCurrentUser(),
        ApiService.getRooms(),
      ]);

      await _dataNotifier.start(results[0] as User, results[1] as List<Room>);
    } catch (e) {
      _handleInitializationError(e);
    }
  }

  void _handleInitializationError(Object error) {
    debugPrint('Initialization error: $error');
    if (mounted) {
      ResponseHandler.handleError(error, context);
    }
  }

  // ==================== Navigation ====================

  Future<void> _handleLogout() async {
    await ApiService.clearToken();
    if (mounted) {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // ==================== UI Builders ====================

  @override
  Widget build(BuildContext context) {
    return Provider<ChatAppDataNotifier>(
      create: (_) => _dataNotifier,
      child: ValueListenableBuilder(
        valueListenable: _dataNotifier.readyNotifier,
        builder: (context, ready, child) {
          return _buildContent(ready);
        }
      ),
    );
  }

  Widget _buildContent(bool ready) {
    if (!ready) {
      return _buildLoadingScreen();
    }

    if (_dataNotifier.currentUser == null) {
      return const LoginScreen();
    }

    return _buildMainContent();
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: AppTheme.accentColor,
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Scaffold(
      body: LayoutBuilder(builder: (context, constraints) {
        final isLargeScreen = _isLargeScreen(constraints);

        if (isLargeScreen) {
          return _buildLargeScreenLayout();
        } else {
          return _buildMainPanel(false);
        }
      }),
    );
  }

  Widget _buildLargeScreenLayout() {
    return Row(
      children: [
        _buildChatListPanel(true),
        Flexible(
          child: _buildMainPanel(true),
        )
      ],
    );
  }

  // Widget _buildSidePanel() {
  //   if (_dataNotifier.profileVisible.value) {
  //     return _buildProfilePanel();
  //   } else if (_dataNotifier.roomsNotifier.value != null) {
  //     return _buildChatPanel(true);
  //   } else {
  //     return _buildEmptyState();
  //   }
  // }

  Widget _buildMainPanel(bool isLargeScreen) {
    return CombinedNotifier(
      multipleListenable: [_dataNotifier.profileVisible, _dataNotifier.roomsNotifier],
      builder: (_, __, ___) {
        if (_dataNotifier.profileVisible.value) {
          return _buildProfilePanel();
        } else if (_dataNotifier.roomsNotifier.value != null) {
          return _buildChatPanel(isLargeScreen);
        } else if (isLargeScreen) {
          return _buildEmptyState();
        } else {
          return _buildChatListPanel(false);
        }
      },
    );
  }

  // Widget _buildSmallScreenLayout() {
  //   return _dataNotifier.profileVisible.value
  //       ? _buildProfilePanel()
  //       : _dataNotifier.roomsNotifier.value != null
  //           ? _buildChatPanelWithBackButton()
  //           : _buildChatListPanel(false);
  // }

  Future<bool> _handleBackPress() async {
    if (_dataNotifier.roomsNotifier.value != null) {
      _dataNotifier.roomsNotifier.value = null;
      return false;
    }
    if (_dataNotifier.profileVisible.value) {
      _dataNotifier.profileVisible.value = false;
      return false;
    }
    return true;
  }

  Widget _buildProfilePanel() {
    if (_dataNotifier.currentUser == null) {
      return const SizedBox.shrink();
    }
    return ProfileScreen(
      user: _dataNotifier.currentUser!,
    );
  }

  Widget _buildChatListPanel(bool isLargeScreen) {
    return SizedBox(
      width: isLargeScreen ? AppConstants.chatListWidth : double.infinity,
      child: ChatListPanel(
        onLogout: _handleLogout,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: AppTheme.primaryBackground,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 120,
              color: AppTheme.textSecondary.withValues(alpha: 255.0 * 0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              StringConstants.selectChatToStart,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatPanel(bool isLargeScreen) {
    final child = ChatPanel(
      onBack: isLargeScreen ? null : _handleBackPress,
    );
    return isLargeScreen
        ? child
        : WillPopScope(
            onWillPop: _handleBackPress,
            child: child,
          );
  }

  bool _isLargeScreen(BoxConstraints constraints) {
    return constraints.maxWidth > AppConstants.largeScreenWidth;
  }
}
