import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:motor_master/DevicesModel.dart';
import 'package:provider/provider.dart';

import '../widgets/nav_drawer.dart';
import 'device_screen.dart';
import '../utils/snackbar.dart';
import '../widgets/scan_result_tile.dart';
import '../utils/extra.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  static const String name = "Connected Devices";

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<ScanResult> _scanResults = [];
  List<BluetoothDevice> _systemDevices = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  @override
  void initState() {
    super.initState();

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      if (mounted) {
        setState(() {});
      }
    }, onError: (e) {
      Snackbar.show(ABC.b, prettyException("Scan Error:", e), success: false);
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
      if (mounted) {
        setState(() {});
      }
    });

    onScanPressed();
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  Future onScanPressed() async {
    try {
      _systemDevices = await FlutterBluePlus.systemDevices;
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("System Devices Error:", e), success: false);
    }
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Start Scan Error:", e), success: false);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future onStopPressed() async {
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Stop Scan Error:", e), success: false);
    }
  }

  Future<void> onConnectPressed(BluetoothDevice btDevice) async {
    if (!btDevice.isConnected) {
      await btDevice.connectAndUpdateStream().catchError((e) {
        Snackbar.show(ABC.c, prettyException("Connect Error:", e), success: false);
      });
    }
    if (btDevice.isConnected) {
      Device device = await Provider.of<DevicesModel>(context, listen: false).addDevice(btDevice);

      MaterialPageRoute route = MaterialPageRoute(
          builder: (context) => DeviceScreen(device: device), settings: const RouteSettings(name: '/DeviceScreen'));
      Navigator.of(context).push(route);
    }
  }

  Future onRefresh() {
    if (_isScanning == false) {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    }
    if (mounted) {
      setState(() {});
    }
    return Future.delayed(const Duration(milliseconds: 500));
  }

  Widget buildScanButton(BuildContext context) {
    if (FlutterBluePlus.isScanningNow) {
      return FloatingActionButton(
        onPressed: onStopPressed,
        child: const Icon(Icons.stop),
      );
    } else {
      return FloatingActionButton(onPressed: onScanPressed, child: const Icon(Icons.refresh));
    }
  }

  List<ScanResult> _filterScan() {
    return _scanResults.where((r) => r.device.platformName.contains('MotorMaster')).toList();
  }

    List<Widget> _buildSystemDeviceTiles(BuildContext context) {
    return _systemDevices
        .map(
          (r) => ScanResultTile(
            device: r,
            onTap: () => onConnectPressed(r),
          ),
        )
        .toList();
  }

  List<Widget> _buildScanResultTiles(BuildContext context) {
    return _filterScan()
        .map(
          (r) => ScanResultTile(
            result: r,
            onTap: () => onConnectPressed(r.device),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyB,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(ScanScreen.name),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.tertiary,
        ),
        drawer: const NavDrawer(),
        body: RefreshIndicator(
          onRefresh: onRefresh,
          child: Builder(
            builder: (context) {
              if (_filterScan().isEmpty && _systemDevices.isEmpty) {
                return const Center(
                  child: Text('No MotorMaster Devices Found'),
                );
              }
              return ListView(
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 15.0),
                  ),
                  ..._buildSystemDeviceTiles(context),
                  ..._buildScanResultTiles(context),
                ],
              );
            }
          ),
        ),
        floatingActionButton: buildScanButton(context),
      ),
    );
  }
}
