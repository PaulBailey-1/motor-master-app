
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

  String info = "";

  CanOutput(super.name);

  void setInfoCharacteristic(BluetoothCharacteristic c) {
    _infoCharacteristic = c;
    readInfo();
  }

  Future<void> readInfo() async {
    List<int> bytes = await _infoCharacteristic!.read();
    info = String.fromCharCodes(bytes);
    print("Can info $info");
  }

  @override  
  Future<void> readCmd() async {
    List<int> bytes = await _cmdCharacteristic!.read();
    _cmd = String.fromCharCodes(bytes);
  }

  @override 
  void setCmd(dynamic cmd) {
    assert(cmd is String);
    _cmd = cmd;
    int time = DateTime.now().millisecondsSinceEpoch;
    if (time - _lastUpdateTime > 100) {
      _cmdCharacteristic!.write(_cmd.codeUnits);
      _lastUpdateTime = time;
    }
  }

  @override
  bool available() {return _enabledCharacteristic != null && _cmdCharacteristic != null && _infoCharacteristic != null;}

}
