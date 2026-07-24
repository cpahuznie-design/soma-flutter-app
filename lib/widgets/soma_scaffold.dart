import 'package:flutter/material.dart';
import '../theme/soma_theme.dart';

class SomaScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int currentIndex;
  final Function(int) onNavTap;

  const SomaScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.currentIndex,
    required this.onNavTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SomaTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: SomaTheme.bgDeep,
        title: Text(title, style: const TextStyle(color: SomaTheme.white, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: body,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: SomaTheme.bgCard,
          border: Border(top: BorderSide(color: SomaTheme.teal.withOpacity(0.2))),
        ),
        child: SafeArea(
          child: NavigationBar(
            backgroundColor: SomaTheme.bgCard,
            selectedIndex: currentIndex,
            onDestinationSelected: onNavTap,
            indicatorColor: SomaTheme.teal.withOpacity(0.2),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
              NavigationDestination(icon: Icon(Icons.bedtime), label: 'Tidur'),
              NavigationDestination(icon: Icon(Icons.waves), label: 'Relaksasi'),
              NavigationDestination(icon: Icon(Icons.sports_esports), label: 'Game'),
              NavigationDestination(icon: Icon(Icons.book), label: 'Belajar'),
            ],
          ),
        ),
      ),
    );
  }
}