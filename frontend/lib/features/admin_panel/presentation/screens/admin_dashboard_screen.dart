import 'package:flutter/material.dart';
import '../../data/repositories/admin_overview_repository_impl.dart';
import '../../domain/usecases/get_admin_dashboard_stats_usecase.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../widgets/admin_sidebar.dart';
import 'views/access_logs_view.dart';
import 'views/admin_management_views.dart';
import 'views/admin_overview_view.dart';
import 'views/announcements_view.dart';
import 'views/full_chat_screen.dart';
import 'views/reports_view.dart';
import 'views/residents_view.dart';

class AdminDashboardScreen extends StatefulWidget {
  final AdminDashboardController? controller;

  const AdminDashboardScreen({super.key, this.controller});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final AdminDashboardController _controller;
  bool _isShowingFullChat = false;

  @override
  void initState() {
    super.initState();
    final repo = AdminOverviewRepositoryImpl();
    _controller =
        widget.controller ??
        AdminDashboardController(
          getDashboardStatsUseCase: GetAdminDashboardStatsUseCase(repo),
        );

    _controller.loadStats();
    if (widget.controller == null) _controller.startRealtimeRefresh();
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  Widget _getSelectedView(int index, bool isDesktop) {
    switch (index) {
      case 0:
        return AdminOverviewView(
          controller: _controller,
          isDesktop: isDesktop,
          onOpenChat: () => setState(() => _isShowingFullChat = true),
        );
      case 1:
        return const ResidentsView();
      case 2:
        return const AccessLogsView();
      case 3:
        return const AnnouncementsView();
      case 4:
        return const ReportsView();
      case 5:
        return const AdminProfileView();
      case 6:
        return const PasswordRequestsView();
      case 7:
        return const RulesManagementView();
      case 8:
        return const FaqManagementView();
      default:
        return AdminOverviewView(
          controller: _controller,
          isDesktop: isDesktop,
          onOpenChat: () => setState(() => _isShowingFullChat = true),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isShowingFullChat) {
      return FullChatScreen(
        onBack: () => setState(() => _isShowingFullChat = false),
      );
    }

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final isDesktop = MediaQuery.of(context).size.width >= 900;

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: isDesktop
              ? null
              : AppBar(
                  title: const Text('Panel de Administración'),
                  backgroundColor: const Color(0xFF1E1E1E),
                  foregroundColor: Colors.white,
                ),
          drawer: isDesktop
              ? null
              : Drawer(
                  child: AdminSidebar(
                    selectedIndex: _controller.selectedIndex,
                    onItemSelected: (index) {
                      _controller.setSelectedIndex(index);
                      Navigator.pop(context);
                    },
                  ),
                ),
          body: Row(
            children: [
              if (isDesktop)
                AdminSidebar(
                  selectedIndex: _controller.selectedIndex,
                  onItemSelected: (index) =>
                      _controller.setSelectedIndex(index),
                ),
              Expanded(
                child: SafeArea(
                  child: _getSelectedView(_controller.selectedIndex, isDesktop),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
