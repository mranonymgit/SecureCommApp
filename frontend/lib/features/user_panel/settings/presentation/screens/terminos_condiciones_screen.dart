import 'package:flutter/material.dart';
import 'package:frontend/features/user_panel/settings/presentation/widgets/terms_widgets.dart';

class TerminosCondicionesScreen extends StatelessWidget {
  const TerminosCondicionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Información y Legal'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: theme.colorScheme.surface,
              child: TabBar(
                indicatorColor: theme.colorScheme.primary,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 
                  0.7,
                ),
                tabs: const [
                  Tab(icon: Icon(Icons.info_outline), text: 'Acerca de SCA'),
                  Tab(
                    icon: Icon(Icons.description_outlined),
                    text: 'Términos y Datos',
                  ),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(children: [AcercaDeTab(), TerminosYDatosTab()]),
            ),
          ],
        ),
      ),
    );
  }
}
