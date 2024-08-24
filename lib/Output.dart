
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract class Output {
  String name;
  String shortName;
  bool visible = true;

  BluetoothCharacteristic? _enabledCharacteristic;
  BluetoothCharacteristic? _cmdCharacteristic;

  bool _enabled = false;
  dynamic _cmd;

  int _lastUpdateTime = DateTime.now().millisecondsSinceEpoch;

  Output(this.name) : shortName = name.substring(name.lastIndexOf(": ") + 2);

  Future<void> readEnabled() async {
    _enabled = (await _enabledCharacteristic!.read())[0] > 0 ? true : false;
  }

  Future<void> readCmd();

  void setEnabledCharacteristic(BluetoothCharacteristic c) {
    _enabledCharacteristic = c;
    readEnabled();
  }

  void setCmdCharacteristic(BluetoothCharacteristic c) {
    _cmdCharacteristic = c;
    readCmd();
  }

  bool available() {return _enabledCharacteristic != null && _cmdCharacteristic != null;}

  bool get enabled  { return _enabled; }
  dynamic get cmd { return _cmd; }

  void setEnabled(bool enabled) {
    _enabled = enabled;
    _enabledCharacteristic!.write([_enabled ? 1 : 0]);
  }

  void setCmd(dynamic cmd);
}

class PwmOutput extends Output {

  PwmOutput(super.name);

  @override  
  Future<void> readCmd() async {
    List<int> bytes = await _cmdCharacteristic!.read();
    _cmd = bytes[0] / 100.0;
  }

  @override
  // cmd is -1.0 to 1.0
  void setCmd(dynamic cmd) {
    assert(cmd is double);
    _cmd = cmd;
    int time = DateTime.now().millisecondsSinceEpoch;
    if (time - _lastUpdateTime > 100) {
      _cmdCharacteristic!.write([(cmd).round(), 0, 0, 0]);
      _lastUpdateTime = time;
    }
  }
}

class CanOutput extends Output {

  BluetoothCharacteristic? _infoCharacteristic;

  Map<int, CanDevice> info = {};

  CanOutput(super.name) {
    _cmd = {};
  }

  void setInfoCharacteristic(BluetoothCharacteristic c) {
    _infoCharacteristic = c;
    readInfo();
  }

  Future<void> readInfo() async {
    List<int> bytes = await _infoCharacteristic!.read();
    String jsonInfo = String.fromCharCodes(bytes);
    jsonInfo = " [ { \"id\": 1, \"name\": \"drive_motor\" } ]";
    print("CAN info $jsonInfo");
    final devices = jsonDecode(jsonInfo) as List<dynamic>;

    info.clear();
    for (final device in devices) {
      info[device['id']] = CanDevice(device['name']);
    }
    readCmd();
  }

  @override  
  Future<void> readCmd() async {
    // List<int> bytes = await _cmdCharacteristic!.read();
    _cmd.clear();
    info.forEach((id, dev) {_cmd[id] = CanCommand(id, 0.0);});
  }

  @override 
  void setCmd(dynamic cmd) {
    assert(cmd is CanCommand);
    _cmd[cmd.id] = cmd;
    int time = DateTime.now().millisecondsSinceEpoch;
    if (time - _lastUpdateTime > 100) {
      _cmdCharacteristic!.write(cmd.toBytes());
      _lastUpdateTime = time;
    }
  }

  double getCmd(int id) {
    try {
      return cmd[id].val;
    } catch (e) {
      print("Failed to get CanControl cmd for id $id - ${e.toString()}");
    }
    return 0.0;
  }

  @override
  bool available() {return _enabledCharacteristic != null && _cmdCharacteristic != null && _infoCharacteristic != null;}

}

class CanDevice {

  String name;

  CanDevice(this.name);
}

class CanCommand {
  int id = -1;
  double val = 0.0;

  CanCommand(this.id, this.val);

  List<int> toBytes() {
    ByteData bytes = ByteData(4+4+8);
    bytes.setInt32(0, id, Endian.little);
    bytes.setFloat64(8, val, Endian.little);
    return bytes.buffer.asUint8List();
  }
}