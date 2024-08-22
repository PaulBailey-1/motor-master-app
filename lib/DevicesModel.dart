
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:motor_master/Output.dart';

class Device {
  BluetoothDevice btDevice;
  late StreamSubscription<BluetoothConnectionState> connectionStateSub;
  List<Output> outputs = [];

  Device(BluetoothDevice dev) : btDevice = dev;
}

class DevicesModel extends ChangeNotifier {

  final Map _devices = {};

  Future<Device> addDevice(BluetoothDevice btDev) async {

    if (_devices.containsKey(btDev.remoteId.str)) {
      return _devices[btDev.remoteId.str];
    }

    Device dev = Device(btDev);

    if (!dev.btDevice.isConnected) {
      throw "Device is not connected";
    }

    List<BluetoothService> services = await dev.btDevice.discoverServices();
    if (services.isEmpty) {
      throw "Error - no device services";
    }
    BluetoothService? service;
    for (BluetoothService s in services) {
      if (s.uuid.str == "4f79cca2-cef2-4137-b4f1-c9cc7fda9ec7") {
        service = s;
        break;
      }
    }
    if (service == null) {
      throw "Error - device service not found";
    }

    PwmOutput pwm1 = PwmOutput("${btDev.platformName}: PWM1");
    PwmOutput pwm2 = PwmOutput("${btDev.platformName}: PWM2");
    CanOutput can = CanOutput("${btDev.platformName}: CAN");
    for (BluetoothCharacteristic c in service.characteristics) {
      if (c.characteristicUuid.str == "a506df5a-48b5-4f57-933c-214612bd77ef") {
        pwm1.setEnabledCharacteristic(c);
      } else if (c.characteristicUuid.str == "ead5e8a1-e5ea-4223-86e5-7ff501a37929") {
        pwm1.setCmdCharacteristic(c);
      } else if (c.characteristicUuid.str == "1c9eb4ba-a11f-444b-aeca-0765f9387506") {
        pwm2.setEnabledCharacteristic(c);
      } else if (c.characteristicUuid.str == "c8bd31cf-6364-4aab-8949-d55cca13618f") {
        pwm2.setCmdCharacteristic(c);
      } else if (c.characteristicUuid.str == "73bb062a-be94-4a95-8fd0-8460d7a8af88") {
        can.setEnabledCharacteristic(c);
      } else if (c.characteristicUuid.str == "28332f90-0151-479a-8bab-f627c195533c") {
        can.setCmdCharacteristic(c);
      } else if (c.characteristicUuid.str == "77723d0f-9668-466e-a3f2-56bc80a0eb9d") {
        can.setInfoCharacteristic(c);
      }
    }
    if (pwm1.available()) {
      dev.outputs.add(pwm1);
      print("Added pwm1");
    }
    if (pwm2.available()) {
      dev.outputs.add(pwm2);
      print("Added pwm2");
    }
    if (can.available()) {
      dev.outputs.add(can);
      print("Added can");
    }

    dev.connectionStateSub = dev.btDevice.connectionState.listen((state) async {
      if (state == BluetoothConnectionState.disconnected) {
        print("Device ${dev.btDevice.remoteId.str} disconnected");
        _devices.remove(dev.btDevice.remoteId.str);
        notifyListeners();
      }
    });
    _devices[btDev.remoteId.str] = dev;

    notifyListeners();
    print("Added device");
    return _devices[btDev.remoteId.str];
  }

  List<Output> getOutputs() {
    List<Output> outputs = [];
    _devices.forEach((key, value) => outputs.addAll(value.outputs));
    return outputs;
  }

}