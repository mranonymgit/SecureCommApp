import 'package:flutter/material.dart';
import 'package:frontend/core/network/api_session.dart';
import 'package:frontend/core/services/community_realtime_service.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro de que deseas salir del panel de administración?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await CommunityRealtimeService.instance.disconnect();
              if (!context.mounted) return;
              ApiSession.instance.clear();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E1E1E),
      child: SizedBox(
        width: 250,
        child: Column(
          children: [
            const SizedBox(height: 32.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/OIcon.png', height: 36),
                const SizedBox(width: 10),
                const Text(
                  'Admin SCA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32.0),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 16.0),
            _buildNavItem(
              0,
              Icons.dashboard_outlined,
              Icons.dashboard,
              'Dashboard',
            ),
            _buildNavItem(1, Icons.people_outline, Icons.people, 'Residentes'),
            _buildNavItem(
              2,
              Icons.door_sliding_outlined,
              Icons.door_sliding,
              'Accesos',
            ),
            _buildNavItem(3, Icons.campaign_outlined, Icons.campaign, 'Avisos'),
            _buildNavItem(
              4,
              Icons.report_problem_outlined,
              Icons.report_problem,
              'Reportes',
            ),
            _buildNavItem(
              5,
              Icons.account_circle_outlined,
              Icons.account_circle,
              'Mi perfil',
            ),
            _buildNavItem(
              6,
              Icons.lock_reset_outlined,
              Icons.lock_reset,
              'Contraseñas',
            ),
            _buildNavItem(7, Icons.gavel_outlined, Icons.gavel, 'Reglamento'),
            _buildNavItem(8, Icons.quiz_outlined, Icons.quiz, 'Preguntas FAQ'),
            _buildNavItem(
              9,
              Icons.notifications_none,
              Icons.notifications,
              'Notificaciones',
            ),
            const Spacer(),
            const Divider(color: Colors.white12, height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () => _handleLogout(context),
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected ? const Color(0xFF2A2A2A) : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? Colors.white : Colors.white54,
          ),
          title: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: () => onItemSelected(index),
        ),
      ),
    );
  }
}
