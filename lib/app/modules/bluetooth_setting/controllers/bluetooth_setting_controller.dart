import 'dart:async';
import 'package:basmalla/app/modules/home/controllers/bluetooth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';
import 'BluetoothDeviceListEntry.dart';

enum _DeviceAvailability {
  // no,
  maybe,
  yes,
}

class _DeviceWithAvailability {
  BluetoothDevice device;
  _DeviceAvailability availability;
  int? rssi;

  _DeviceWithAvailability(this.device, this.availability, [this.rssi]);
}

class BluetoothSettingController extends GetxController {
  BluetoothController get bt_controller =>
      GetInstance().find<BluetoothController>();
  final checkAvailability = false.obs;
  final devices = List<_DeviceWithAvailability>.empty(growable: true).obs;

  @override
  void onInit() {
    super.onInit();
    Timer.periodic(Duration(seconds: 1), (timer) {
      reload();
    });
    Future.delayed(Duration(milliseconds: 200), reload);
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    this.dispose();
  }

  void reload() async {
    final bondedDevices =
        await FlutterBluetoothSerial.instance.getBondedDevices();
    devices.value = bondedDevices
        .map(
          (device) => _DeviceWithAvailability(
            device,
            checkAvailability.value
                ? _DeviceAvailability.maybe
                : _DeviceAvailability.yes,
          ),
        )
        .toList();
    // print('reload');
  }

  List<BluetoothDeviceListEntry> getList() {
    return devices
        .map((_device) => BluetoothDeviceListEntry(
              device: _device.device,
              rssi: _device.rssi,
              enabled: true, // _device.availability == _DeviceAvailability.yes,
              onTap: () async {
                Get.defaultDialog(
                  title: 'Loading',
                  titleStyle: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold,
                  ),
                  middleTextStyle: TextStyle(color: Colors.black),
                  radius: 3,
                  contentPadding: EdgeInsets.all(15),
                  content: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.amber,
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      Text('Menyambungkan Perangkat...'),
                    ],
                  ),
                  barrierDismissible: false,
                );
                if (_device.device.isConnected) {
                  await this.startDisConnect(_device.device.address);
                }

                String msg = await bt_controller.connectTo(_device.device);
                Future.delayed(const Duration(milliseconds: 500), () {
                  Get.snackbar("Bluetooth", msg,
                      snackPosition: SnackPosition.BOTTOM);
                });
                Get.back(result: true, closeOverlays: true);
              },
            ))
        .toList();
  }

  Future openBluetoothSetting() async {
    await FlutterBluetoothSerial.instance.openSettings();
    reload();
  }

  Future startDisConnect(String address) async {
    try {
      BluetoothConnection connection =
          await BluetoothConnection.toAddress(address);
      // print('Connected to the device');
      connection.dispose();
    } catch (exception) {
      // print('Cannot connect, exception occured');
      this.reload();
    }
  }

  // Future<bool> findConnection() async {
  //   bool result = false;

  //   List<BluetoothDevice> _conn =
  //       await FlutterBluetoothSerial.instance.getBondedDevices();
  //   _conn.forEach((element) {
  //     print('element = ${element.name} = ${element.isConnected} ');
  //     if (element.isConnected == true) {
  //       result = true;
  //       BluetoothConnection.toAddress(element.address).
  //     }
  //   });
  //   return result;
  // }

  // void disConnect() async {
  //   List<BluetoothDevice> _conn =
  //       await FlutterBluetoothSerial.instance.getBondedDevices();
  //   _conn.forEach((element) {
  //     if (element.isConnected == true) {
  //       startDisConnect(element.address);
  //     }
  //   });
  // }
}
