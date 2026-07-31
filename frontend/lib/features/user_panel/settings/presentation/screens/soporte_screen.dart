import 'package:flutter/material.dart';
import 'package:frontend/features/user_panel/settings/presentation/screens/preguntas_frecuentes_screen.dart';
import 'package:frontend/features/user_panel/settings/presentation/screens/reglamento_screen.dart';
import 'package:frontend/features/user_panel/settings/presentation/widgets/support_cards.dart';

class SoporteScreen extends StatelessWidget {
  const SoporteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Soporte y Ayuda'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_SCA.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: const [
                                InteractiveHelpCard(
                                  title: 'Reglamento de Convivencia',
                                  subtitle:
                                      'Lee las normas aprobadas por el comité del vecindario.',
                                  icon: Icons.gavel,
                                  targetScreen: ReglamentoScreen(),
                                ),
                                SizedBox(height: 16),
                                InteractiveHelpCard(
                                  title: 'Preguntas Frecuentes',
                                  subtitle:
                                      'Resuelve dudas sobre el uso de la aplicación y reportes.',
                                  icon: Icons.help_outline,
                                  targetScreen: PreguntasFrecuentesScreen(),
                                ),
                                SizedBox(height: 16),
                                ContactInfoCard(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(child: ReportProblemCard()),
                        ],
                      )
                    : Column(
                        children: const [
                          InteractiveHelpCard(
                            title: 'Reglamento de Convivencia',
                            subtitle:
                                'Lee las normas aprobadas por el comité del vecindario.',
                            icon: Icons.gavel,
                            targetScreen: ReglamentoScreen(),
                          ),
                          SizedBox(height: 16),
                          InteractiveHelpCard(
                            title: 'Preguntas Frecuentes',
                            subtitle:
                                'Resuelve dudas sobre el uso de la aplicación y reportes.',
                            icon: Icons.help_outline,
                            targetScreen: PreguntasFrecuentesScreen(),
                          ),
                          SizedBox(height: 16),
                          ContactInfoCard(),
                          SizedBox(height: 16),
                          ReportProblemCard(),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
