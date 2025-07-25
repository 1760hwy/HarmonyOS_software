import { access, ble, connection, socket } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 定义一个通用的回调类型，方便使用
type Callback<T> = (data: T) => void;

export class BlueToothMgr {
  private TAG: string = "BlueToothTest";
  private static mBlueToothMgr: BlueToothMgr | undefined = undefined;
  // private advHandle: number = 0xFF; // 暂时未使用，可以先注释掉
  // private mDeviceDiscoverArr: Array<string> = new Array<string>(); // 完全未使用，已删除
  private sppSocketId: number | undefined = undefined; // 用于存储SPP连接的socket ID

  public static Ins() {
    if (!BlueToothMgr.mBlueToothMgr) {
      BlueToothMgr.mBlueToothMgr = new BlueToothMgr();
      BlueToothMgr.init();
    }
    return BlueToothMgr.mBlueToothMgr;
  }

  private static init() {
    try {
      connection.on('pinRequired', (data: connection.PinRequiredParam) => {
        console.info("BlueToothTest", 'pinRequired pin required = ' + JSON.stringify(data));
      });
    } catch (err) {
      console.error("BlueToothTest", 'pinRequired errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  public getCurrentDeviceName() {
    let localName: string = "";
    try {
      localName = connection.getLocalName();
      console.info(this.TAG, 'getCurrentDeviceName localName: ' + localName);
    } catch (err) {
      console.error(this.TAG, 'getCurrentDeviceName errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
    return localName;
  }

  public isCurrentDiscovering() {
    let res: boolean = false;
    try {
      res = connection.isBluetoothDiscovering();
      console.info(this.TAG, 'isCurrentDiscovering isBluetoothDiscovering: ' + res);
    } catch (err) {
      console.error(this.TAG, 'isCurrentDiscovering errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
    return res;
  }

  public getBlueToothState(): access.BluetoothState {
    let state = access.getState();
    return state;
  }

  setBlueToothAccess(isAccess: boolean, callbackBluetoothState: Callback<access.BluetoothState>) {
    try {
      if (isAccess) {
        console.info(this.TAG, 'bluetooth enableBluetooth 1');
        access.enableBluetooth();
        console.info(this.TAG, 'bluetooth enableBluetooth 2');
        access.on('stateChange', (data: access.BluetoothState) => {
          let btStateMessage = this.switchState(data);
          if (btStateMessage == 'STATE_ON') {
            access.off('stateChange');
          }
          console.info(this.TAG, 'bluetooth statues: ' + btStateMessage);
          callbackBluetoothState(data);
        });
      } else {
        console.info(this.TAG, 'bluetooth disableBluetooth 1');
        access.disableBluetooth();
        console.info(this.TAG, 'bluetooth disableBluetooth 2');
        access.on('stateChange', (data: access.BluetoothState) => {
          let btStateMessage = this.switchState(data);
          if (btStateMessage == 'STATE_OFF') {
            access.off('stateChange');
          }
          console.info(this.TAG, "bluetooth statues: " + btStateMessage);
          callbackBluetoothState(data);
        });
      }
    } catch (err) {
      console.error(this.TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  private switchState(data: access.BluetoothState) {
    let btStateMessage = '';
    switch (data) {
      case 0: btStateMessage += 'STATE_OFF'; break;
      case 1: btStateMessage += 'STATE_TURNING_ON'; break;
      case 2: btStateMessage += 'STATE_ON'; break;
      case 3: btStateMessage += 'STATE_TURNING_OFF'; break;
      case 4: btStateMessage += 'STATE_BLE_TURNING_ON'; break;
      case 5: btStateMessage += 'STATE_BLE_ON'; break;
      case 6: btStateMessage += 'STATE_BLE_TURNING_OFF'; break;
      default: btStateMessage += 'unknown status'; break;
    }
    return btStateMessage;
  }

  public registerBroadcast() {
    try {
      ble.on('advertisingStateChange', (data: ble.AdvertisingStateChangeInfo) => {
        console.info(this.TAG, 'bluetooth advertising state = ' + JSON.stringify(data));
        // AppStorage is not defined here, if it's a global dependency, make sure it's correctly imported/set.
        // AppStorage.setOrCreate('advertiserState', data.state);
      });
    } catch (err) {
      console.error(this.TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  public async startBroadcast(valueBuffer: Uint8Array) {
    let setting: ble.AdvertiseSetting = {
      interval: 160,
      txPower: 0,
      connectable: true
    };
    let manufactureDataUnit: ble.ManufactureData = {
      manufactureId: 4567,
      manufactureValue: valueBuffer.buffer
    };
    let serviceValueBuffer = new Uint8Array(4);
    serviceValueBuffer[0] = 5;
    serviceValueBuffer[1] = 6;
    serviceValueBuffer[2] = 7;
    serviceValueBuffer[3] = 8;
    let serviceDataUnit: ble.ServiceData = {
      serviceUuid: "00001888-0000-1000-8000-00805f9b34fb",
      serviceValue: serviceValueBuffer.buffer
    };
    let advData: ble.AdvertiseData = {
      serviceUuids: ["00001888-0000-1000-8000-00805f9b34fb"],
      manufactureData: [manufactureDataUnit],
      serviceData: [serviceDataUnit],
      includeDeviceName: false
    };
    let advResponse: ble.AdvertiseData = {
      serviceUuids: ["00001888-0000-1000-8000-00805f9b34fb"],
      manufactureData: [manufactureDataUnit],
      serviceData: [serviceDataUnit]
    };
    let advertisingParams: ble.AdvertisingParams = {
      advertisingSettings: setting,
      advertisingData: advData,
      advertisingResponse: advResponse,
      duration: 0
    };
    try {
      this.registerBroadcast();
      // 'advHandle' is not used, so we don't need to assign the result.
      await ble.startAdvertising(advertisingParams);
    } catch (err) {
      console.error(this.TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  public startScanDevice(callback: Callback<Array<string>>) {
    try {
      connection.on('bluetoothDeviceFind', (data: Array<string>) => {
        console.info(this.TAG, 'bluetooth device bluetoothDeviceFind = ' + JSON.stringify(data));
        callback(data);
      });
      connection.startBluetoothDiscovery();
    } catch (err) {
      console.error(this.TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  public stopScanDevice() {
    try {
      connection.off('bluetoothDeviceFind');
      connection.stopBluetoothDiscovery();
    } catch (err) {
      console.error(this.TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  public getDeviceName(deviceID: string) {
    let remoteDeviceName: string = "";
    try {
      remoteDeviceName = connection.getRemoteDeviceName(deviceID);
      console.info(this.TAG, 'getDeviceName device = ' + JSON.stringify(remoteDeviceName));
    } catch (err)
    {
      console.error(this.TAG, 'getDeviceName errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
    return remoteDeviceName;
  }

  public getDeviceClass(deviceID: string) {
    let remoteDeviceClass: string = "";
    try {
      let classObj = connection.getRemoteDeviceClass(deviceID);
      remoteDeviceClass = JSON.stringify(classObj);
    } catch (err) {
      console.error(this.TAG, 'getDeviceName errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
    return remoteDeviceClass;
  }

  // **FIXED**: Renamed from 'pairDeviceifdef' and removed the empty one at the top.
  public pairDevice(deviceID: string) {
    try {
      connection.on('bondStateChange', (data: connection.BondStateParam) => {
        console.info(this.TAG, 'pairDevice pair state = ' + JSON.stringify(data));
      });
      connection.pairDevice(deviceID, (err: BusinessError) => {
        if (err) {
          console.error(this.TAG, 'pairDevice callback error: ' + JSON.stringify(err));
        } else {
          console.info(this.TAG, 'pairDevice successful for device: ' + deviceID);
        }
      });
    } catch (err) {
      console.error(this.TAG, 'pairDevice errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  // **FIXED**: Changed to use a callback instead of async/await.
  public connectToSPPDevice(deviceId: string, callback: Callback<string>) {
    const sppOptions: socket.SppOptions = {
      uuid: '00001101-0000-1000-8000-00805f9b34fb', // SPP UUID
      secure: true,
      type: 0 // Should be socket.SppType.SPP_RFCOMM
    };

    try {
      socket.sppConnect(deviceId, sppOptions, (err: BusinessError, socketId: number) => {
        if (err) {
          console.error(this.TAG, 'SPP connect callback errCode: ' + err.code + ', errMessage: ' + err.message);
          callback('SPP connection failed');
          return;
        }

        this.sppSocketId = socketId;
        console.info(this.TAG, 'Connected to SPP device, socketId: ' + this.sppSocketId);
        callback('Connected to SPP device');

        // 监听数据接收
        socket.on('sppRead', this.sppSocketId, (dataBuffer: ArrayBuffer) => {
          const receivedData = new Uint8Array(dataBuffer);
          console.info(this.TAG, 'Received SPP data: ' + receivedData);
          callback('Received: ' + receivedData.toString());
        });
      });
    } catch (err) {
      console.error(this.TAG, 'SPP connect invocation errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
      callback('SPP connection failed');
    }
  }

  // 发送SPP数据
  // **FIXED**: Removed 'async' and 'await'
  public sendSPPData(data: Uint8Array) {
    if (!this.sppSocketId) {
      console.error(this.TAG, 'No SPP connection established');
      return;
    }
    try {
      socket.sppWrite(this.sppSocketId, data.buffer);
      console.info(this.TAG, 'SPP data sent: ' + data);
    } catch (err) {
      console.error(this.TAG, 'SPP write errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  // 断开SPP连接
  public disconnectSPP() {
    if (this.sppSocketId) {
      socket.off('sppRead', this.sppSocketId);
      // It's also a good practice to explicitly close the socket if an API is available
      // e.g. socket.sppClose(this.sppSocketId);
      this.sppSocketId = undefined;
      console.info(this.TAG, 'SPP connection disconnected');
    }
  }
}