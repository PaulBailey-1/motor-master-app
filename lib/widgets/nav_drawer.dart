import 'package:flutter/material.dart';

import '../screens/scan_screen.dart';
import '../screens/control_screen.dart';

class NavDrawer extends StatelessWidget {
  const NavDrawer({super.key});

  Widget _buildScreenLink(BuildContext context, String title, Icon icon, String route, Widget screen) {
    bool selected = ModalRoute.of(context)?.settings.name == route;
    return ListTile(
      selected: selected,
      leading: icon,
      title: Text(title),
      onTap: () {
        if (!selected) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => screen,
              settings: RouteSettings(name: route)));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 300,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const Padding(padding: EdgeInsets.only(top: 40)),
          _buildScreenLink(context, ScanScreen.name, const Icon(Icons.bluetooth_connected), "/ScanScreen", const ScanScreen()),
          _buildScreenLink(context, ControlScreen.name, const Icon(Icons.gamepad), "/ControlScreen", const ControlScreen()),
        ],
      ),
    );
  }
}
