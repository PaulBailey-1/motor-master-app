
import 'package:flutter/material.dart';
import 'package:motor_master/DevicesModel.dart';
import 'package:motor_master/Output.dart';
import 'package:motor_master/widgets/control_tile.dart';
import 'package:motor_master/widgets/nav_drawer.dart';
import 'package:provider/provider.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({Key? key}) : super(key: key);

  static const String name = "Control Motors";

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {

  List<Widget> _getControlTiles(DevicesModel devices) {
    List<Output> outputs = devices.getOutputs().where((output) => output.visible).toList();
    List<Widget> res = [];
    for (int i = 0; i < outputs.length; i++) {
      res.add(ControlTile(outputs[i], end: i == outputs.length - 1));
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(ControlScreen.name),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.tertiary,
      ),
      drawer: const NavDrawer(),
      body: Consumer<DevicesModel>(
        builder: (context,  devices, child) {
          if (devices.getOutputs().isEmpty) {
            return const Center(
              child: Text('Add devices and enable outputs'),
            );
          }
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: _getControlTiles(devices),
          );
        }
      ),
    );
  }
}
