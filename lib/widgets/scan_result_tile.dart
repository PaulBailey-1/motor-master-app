import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:motor_master/utils/extra.dart';

class ScanResultTile extends StatefulWidget {
  ScanResultTile({Key? key, this.result, this.device, required this.onTap}) : super(key: key);

  BluetoothDevice? device;
  ScanResult? result;
  final Future<void> Function() onTap;

  @override
  State<ScanResultTile> createState() => _ScanResultTileState();
}

class _ScanResultTileState extends State<ScanResultTile> {
  BluetoothConnectionState _connectionState = BluetoothConnectionState.connected;
  bool _isConnecting = false;

  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;

  @override
  void initState() {
    super.initState();

    _connectionStateSubscription = (widget.device ?? widget.result!.device).connectionState.listen((state) {
      _connectionState = state;
      if (state == BluetoothConnectionState.disconnected) {
        _isConnecting = false;
      }
      if (mounted) {
        setState(() {});
      }
    });

  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    super.dispose();
  }

  bool get isConnected {
    return (widget.device ?? widget.result!.device).isConnected;
  }

   Widget _buildSpinner() {
    return const Padding(
      padding: EdgeInsets.all(10.0),
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildConnectButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.tertiary,
      ),
      onPressed: () async {
        if (widget.result == null || widget.result!.advertisementData.connectable) {
          setState(() { _isConnecting = true; });
          await widget.onTap();
          setState(() { _isConnecting = false; });
        }
      },
      child: _isConnecting ? _buildSpinner() : isConnected ? const Text('Open') : const Text('Connect'),
    );
  }

  @override
  Widget build(BuildContext context) {
    String name = '';
    if (widget.result != null) name = widget.result!.device.platformName;
    if (widget.device != null) name = widget.device!.platformName;
    return ListTile(
      title: Text(name),
      trailing: _buildConnectButton(context),
    );
  }
}
