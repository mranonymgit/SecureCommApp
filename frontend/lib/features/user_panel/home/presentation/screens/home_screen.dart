import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../../data/repositories/home_repository_impl.dart';
import '../../domain/usecases/get_news_posts_usecase.dart';
import '../../domain/usecases/react_to_news_usecase.dart';
import '../controllers/home_controller.dart';
import '../widgets/noticia_card.dart';

import 'package:frontend/features/user_panel/reports/presentation/screens/create_report_screen.dart';
import 'package:frontend/features/user_panel/reports/data/repositories/reports_repository_impl.dart';
import 'package:frontend/features/user_panel/reports/domain/usecases/create_report_usecase.dart';
import 'package:frontend/features/user_panel/reports/presentation/controllers/create_report_controller.dart';
import 'package:frontend/features/user_panel/chat/presentation/screens/chat_screen.dart';
import 'package:frontend/features/user_panel/settings/presentation/screens/terminos_condiciones_screen.dart';
import 'package:frontend/features/user_panel/settings/presentation/screens/perfil_screen.dart';
import 'package:frontend/features/user_panel/settings/presentation/screens/settings_screen.dart';
import 'package:frontend/features/user_panel/maps/presentation/screens/map.dart';
import 'package:frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:frontend/core/network/api_session.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/user_panel/reports/presentation/screens/emergency_screen.dart';
import 'package:frontend/core/services/notification_realtime_service.dart';
import 'package:frontend/core/services/community_realtime_service.dart';
import 'package:frontend/core/presentation/app_toast.dart';

class HomeScreen extends StatefulWidget {
  final HomeController? controller;
  final int initialIndex;

  const HomeScreen({super.key, this.controller, this.initialIndex = 1});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _controller;
  late final CreateReportController _reportController;
  final NotificationRealtimeService _notificationRealtime =
      NotificationRealtimeService();
  bool _sosDialogVisible = false;

  @override
  void initState() {
    super.initState();
    final repository = HomeRepositoryImpl();
    _controller =
        widget.controller ??
        HomeController(
          getNewsPostsUseCase: GetNewsPostsUseCase(repository),
          reactToNewsUseCase: ReactToNewsUseCase(repository),
        );
    _reportController = CreateReportController(
      CreateReportUseCase(ReportsRepositoryImpl()),
    );

    _controller.currentIndex = widget.initialIndex;

    _controller.loadNews();
    _controller.connectRealtime();
    _notificationRealtime.subscribe(_checkSosProximity);
    _checkSosProximity();
  }

  @override
  void dispose() {
    _reportController.disposeControllers();
    _notificationRealtime.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  Future<void> _checkSosProximity() async {
    try {
      final state = await ApiClient().getJson('/api/me/sos/proximity');
      final active = state['active'] == true;
      final nearby = state['level'] == 'critical_nearby';
      if (!active) {
        _sosDialogVisible = false;
        return;
      }
      if (nearby && mounted && !_sosDialogVisible) {
        _sosDialogVisible = true;
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFFB71C1C),
            title: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'SOS cercano',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            content: Text(
              (state['message'] ??
                      'Un residente cercano necesita ayuda. Actúa con precaución y contacta a emergencias si es necesario.')
                  .toString(),
              style: const TextStyle(color: Colors.white, height: 1.4),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    } catch (_) {
      // The next database notification retries without interrupting the user.
    }
  }

  void cerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            title: Text(
              '¿Cerrar Sesión?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Tendrás que volver a introducir tu contraseña para acceder a la aplicación.',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 15.0,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 16.0,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await CommunityRealtimeService.instance.disconnect();
                  if (!context.mounted) return;
                  ApiSession.instance.clear();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                },
                child: Text(
                  'Salir',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewsFeed(BuildContext context) {
    if (_controller.isLoading && _controller.newsPosts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.errorMessage != null && _controller.newsPosts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _controller.loadNews,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 80),
            Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 12),
            Text(
              'No pudimos cargar los comunicados',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.errorMessage ?? 'Intenta actualizar la vista.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.65),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: FilledButton.icon(
                onPressed: _controller.loadNews,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ),
          ],
        ),
      );
    }

    if (_controller.newsPosts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _controller.loadNews,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 80),
            Icon(
              Icons.campaign_outlined,
              size: 56,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 12),
            Text(
              'Aún no hay comunicados publicados',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando la administración publique avisos oficiales, aparecerán aquí automáticamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.65),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _controller.loadNews,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount:
            _controller.newsPosts.length + (_controller.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _controller.newsPosts.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          }

          final noticia = _controller.newsPosts[index];
          return NoticiaCard(
            noticia: noticia,
            isReactionPending: _controller.isReactionPending(noticia.id),
            onLike: () async {
              final error = await _controller.toggleLike(noticia.id);
              if (error != null && context.mounted) {
                AppToast.show(context, error, type: AppToastType.error);
              }
            },
            onDislike: () async {
              final error = await _controller.toggleDislike(noticia.id);
              if (error != null && context.mounted) {
                AppToast.show(context, error, type: AppToastType.error);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildActiveTab(BuildContext context) {
    // Creating every tab eagerly starts two FlutterMap instances and several
    // controllers on web. Keep only the active module mounted.
    switch (_controller.currentIndex) {
      case 0:
        return CreateReportScreen(controller: _reportController);
      case 1:
        return _buildNewsFeed(context);
      case 2:
        return const EmergencyScreen();
      case 3:
        return const Chatscreen();
      case 4:
        return const MapaIncidenciasScreen();
      default:
        return _buildNewsFeed(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              'Mi Comunidad',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            elevation: 0,
            actions: [
              PopupMenuButton<String>(
                tooltip: 'Opciones',
                offset: const Offset(0, 40),
                color: Theme.of(context).cardColor,
                elevation: 4,
                icon: Icon(
                  Icons.menu,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 32,
                ),
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      value: 'perfil',
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Mi Perfil',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      value: 'configuracion',
                      child: Row(
                        children: [
                          Icon(
                            Icons.settings,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Configuración',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      value: 'privacidad',
                      child: Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Información',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(
                            Icons.exit_to_app,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Cerrar Sesión',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
                onSelected: (String valorSeleccionado) {
                  if (valorSeleccionado == 'perfil') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PerfilScreen(),
                      ),
                    );
                  } else if (valorSeleccionado == 'configuracion') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  } else if (valorSeleccionado == 'privacidad') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TerminosCondicionesScreen(),
                      ),
                    );
                  } else {
                    cerrarSesion(context);
                  }
                },
              ),
            ],
          ),
          body: _buildActiveTab(context),
          bottomNavigationBar: SafeArea(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24.0),
                topRight: Radius.circular(24.0),
              ),
              child: Container(
                color: Theme.of(context).cardColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 6.0,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: screenWidth - 12),
                    child: GNav(
                      backgroundColor: Colors.transparent,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                      activeColor: Theme.of(context).colorScheme.secondary,
                      tabBackgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.15),
                      gap: isSmallScreen ? 4 : 6,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 12,
                        vertical: 10,
                      ),
                      selectedIndex: _controller.currentIndex,
                      onTabChange: _controller.changeTab,
                      tabs: [
                        const GButton(
                          icon: Icons.assignment_outlined,
                          text: 'Reportar',
                        ),
                        const GButton(
                          icon: Icons.home_outlined,
                          text: 'Inicio',
                        ),
                        GButton(
                          icon: Icons.campaign_sharp,
                          text: 'SOS',
                          iconColor: const Color.fromARGB(255, 236, 62, 62),
                          iconActiveColor: const Color.fromARGB(
                            255,
                            255,
                            255,
                            255,
                          ),
                          textColor: const Color.fromARGB(255, 255, 255, 255),
                          backgroundColor: const Color(0xFFFF0000),
                          backgroundGradient: const LinearGradient(
                            colors: [Color(0xFFFF0000), Color(0xFFB71C1C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          iconSize: 30.0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        const GButton(
                          icon: Icons.chat_bubble_outline,
                          text: 'Chat',
                        ),
                        const GButton(icon: Icons.map_outlined, text: 'Mapa'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
