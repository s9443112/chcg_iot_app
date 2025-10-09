import 'package:flutter/material.dart';

import 'package:chcg_iot_app/pages/home_tabs/disease_ai/disease_ai.dart';
import 'package:chcg_iot_app/pages/home_tabs/disease_ai/disease_ai_now.dart';
import 'package:chcg_iot_app/pages/home_tabs/disease_ai/disease_ai_mine_history.dart';

class DiseaseAIMainPage extends StatefulWidget {
  const DiseaseAIMainPage({super.key});

  @override
  State<DiseaseAIMainPage> createState() => _DiseaseAIMainPageState();
}

class _DiseaseAIMainPageState extends State<DiseaseAIMainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DiseaseAIPage(),
    DiseaseAINowPage(),
    DiseaseAIMinePage(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.history),
      label: '歷史紀錄',
    ),
    NavigationDestination(
      icon: Icon(Icons.camera_alt),
      label: '即時辨識',
    ),
    NavigationDestination(
      icon: Icon(Icons.folder_special),
      label: '即時辨識紀錄',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        destinations: _destinations,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}
