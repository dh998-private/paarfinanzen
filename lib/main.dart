import 'package:flutter/material.dart';

import 'finance_store.dart';
import 'ui/app_theme.dart';
import 'ui/categories_page.dart';
import 'ui/dashboard_page.dart';
import 'ui/settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = FinanceStore();
  await store.init();
  runApp(PaarFinanzenApp(store: store));
}

class PaarFinanzenApp extends StatelessWidget {
  const PaarFinanzenApp({super.key, required this.store});

  final FinanceStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PaarFinanzen',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: AppShell(store: store),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store});

  final FinanceStore store;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardPage(store: widget.store),
      CategoriesPage(store: widget.store),
      SettingsPage(store: widget.store),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        if (desktop) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  extended: constraints.maxWidth >= 1180,
                  selectedIndex: index,
                  onDestinationSelected: (value) => setState(() => index = value),
                  leading: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 18, 12, 28),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
                        ),
                        if (constraints.maxWidth >= 1180) ...[
                          const SizedBox(width: 12),
                          const Text(
                            'PaarFinanzen',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded),
                      label: Text('Übersicht'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.folder_outlined),
                      selectedIcon: Icon(Icons.folder_rounded),
                      label: Text('Gruppen'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings_rounded),
                      label: Text('Daten & Einstellungen'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: pages[index]),
              ],
            ),
          );
        }

        return Scaffold(
          body: pages[index],
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (value) => setState(() => index = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Übersicht',
              ),
              NavigationDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder_rounded),
                label: 'Gruppen',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'Daten',
              ),
            ],
          ),
        );
      },
    );
  }
}
