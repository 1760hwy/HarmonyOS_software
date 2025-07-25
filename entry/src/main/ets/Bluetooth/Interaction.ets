import { HashMap } from '@kit.ArkTS';
import { BlueToothMgr } from './BluetoothManager';
import { abilityAccessCtrl, common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { access } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { DeviceInfo } from './DeviceInfo';

@Entry
@Component
struct Interaction {
  private TAG: string = "BlueToothTest";
  private mNumInterval: number = -1;
  @State mCurrentDeviceName: string = "";
  @State @Watch('onChangeBlueTooth') isStartBlueTooth: boolean = false;
  @State @Watch('onChangeBlueTooth') isStartScan: boolean = false;
  @State userGrant: boolean = false;
  @State mMapDevice: HashMap<string, DeviceInfo> = new HashMap();
  @State mListDeviceInfo: Array<DeviceInfo> = new Array();
  @State sppConnected: boolean = false; // SPP连接状态
  @State sppMessage: string = ""; // SPP通信消息

  async aboutToAppear() {
    await this.requestBlueToothPermission();
    let state = access.getState();
    console.log(this.TAG, "getState state: " + state);
    this.isStartBlueTooth = state === 2;
  }

  private onChangeBlueTooth() {
    if (!this.isStartBlueTooth) {
      this.mMapDevice = new HashMap();
      return;
    }
    this.mCurrentDeviceName = BlueToothMgr.Ins().getCurrentDeviceName();
  }

  async reqPermissionsFromUser(): Promise<number[]> {
    let context = getContext() as common.UIAbilityContext;
    let atManager = abilityAccessCtrl.createAtManager();
    let grantStatus = await atManager.requestPermissionsFromUser(context, ['ohos.permission.ACCESS_BLUETOOTH']);
    return grantStatus.authResults;
  }

  async requestBlueToothPermission() {
    let grantStatus = await this.reqPermissionsFromUser();
    this.userGrant = grantStatus.every(status => status === 0);
    promptAction.showToast({ message: this.userGrant ? "蓝牙授权成功!" : "蓝牙授权失败!" });
  }

  setBlueToothScan = () => {
    if (!this.isStartScan) {
      promptAction.showToast({ message: "开启扫描" });
      BlueToothMgr.Ins().startScanDevice((data: Array<string>) => {
        let deviceId: string = data[0];
        if (!this.mMapDevice.hasKey(deviceId)) {
          let deviceInfo: DeviceInfo = new DeviceInfo();
          deviceInfo.deviceId = deviceId;
          deviceInfo.deviceName = BlueToothMgr.Ins().getDeviceName(deviceId);
          deviceInfo.deviceClass = BlueToothMgr.Ins().getDeviceClass(deviceId);
          this.mMapDevice.set(deviceId, deviceInfo);
          this.mListDeviceInfo = this.mListDeviceInfo.concat(deviceInfo);
        }
      });
      this.mMapDevice.clear();
      this.mListDeviceInfo = [];
      this.mNumInterval = setInterval(() => {
        if (!BlueToothMgr.Ins().isCurrentDiscovering()) {
          this.closeScanDevice();
        }
      }, 1000);
      this.isStartScan = true;
    } else {
      promptAction.showToast({ message: "关闭扫描!" });
      BlueToothMgr.Ins().stopScanDevice();
      this.closeScanDevice();
    }
  }

  private closeScanDevice() {
    clearInterval(this.mNumInterval);
    this.isStartScan = false;
  }

  setBlueToothState = () => {
    try {
      BlueToothMgr.Ins().setBlueToothAccess(!this.isStartBlueTooth, (state: access.BluetoothState) => {
        if (state === access.BluetoothState.STATE_ON) {
          this.isStartBlueTooth = true;
          promptAction.showToast({ message: "开启蓝牙!" });
        } else if (state === access.BluetoothState.STATE_OFF) {
          this.isStartBlueTooth = false;
          promptAction.showToast({ message: "关闭蓝牙" });
        }
      });
    } catch (err) {
      console.error(this.TAG, 'errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
    }
  }

  // SPP连接处理
  connectToSPP(deviceId: string) {
    BlueToothMgr.Ins().connectToSPPDevice(deviceId, (message: string) => {
      this.sppMessage = message;
      this.sppConnected = message === 'Connected to SPP device';
      promptAction.showToast({ message: this.sppConnected ? "SPP连接成功" : "SPP连接失败" });
      if (message="SPP连接成功") {
        this.getUIContext().getRouter().pushUrl({url:"pages/Driver"});
      }else {
        promptAction.showToast({message:"SPP连接失败无法跳转驾驶页面"});
      }
    });
  }

  // 发送测试数据
  sendTestData() {
    if (!this.sppConnected) {
      promptAction.showToast({ message: "请先连接SPP设备" });
      return;
    }
    const data = new Uint8Array([0x01, 0x02, 0x03]);
    BlueToothMgr.Ins().sendSPPData(data);
    promptAction.showToast({ message: "已发送测试数据" });
  }

  // 断开SPP连接
  disconnectSPP() {
    BlueToothMgr.Ins().disconnectSPP();
    this.sppConnected = false;
    this.sppMessage = "";
    promptAction.showToast({ message: "已断开SPP连接" });
  }

  private isLog() {
    console.log(this.TAG, "isLog isStartBlueTooth: " + this.isStartBlueTooth);
    return true;
  }

  build() {
    Column() {
      if (this.userGrant) {
        if (this.isLog()) {
          Text("当前蓝牙设备信息：\n" + this.mCurrentDeviceName)
            .fontSize(px2fp(80))
            .margin({ top: px2vp(100) })
            .fontWeight(FontWeight.Bold)

          Text(this.isStartBlueTooth ? "蓝牙状态:开启" : "蓝牙状态：关闭")
            .fontSize(px2fp(80))
            .margin({ top: px2vp(100) })
            .fontWeight(FontWeight.Bold)
            .onClick(this.setBlueToothState)

          Text(this.isStartScan ? "蓝牙扫描：开启ing" : "蓝牙扫描：关闭")
            .margin({ top: px2vp(100) })
            .fontSize(px2fp(80))
            .fontWeight(FontWeight.Bold)
            .onClick(this.setBlueToothScan)

          Text(this.sppConnected ? "SPP状态：已连接" : "SPP状态：未连接")
            .margin({ top: px2vp(100) })
            .fontSize(px2fp(80))
            .fontWeight(FontWeight.Bold)
            .onClick(() => this.sppConnected ? this.disconnectSPP() : null)

          Text("SPP消息：" + this.sppMessage)
            .margin({ top: px2vp(50) })
            .fontSize(px2fp(60))

          Button("发送测试数据")
            .margin({ top: px2vp(50) })
            .onClick(() => this.sendTestData())

          this.ListView()
        }
      }
    }
    .justifyContent(FlexAlign.Center)
    .height("100%")
    .width("100%")
  }

  @Builder ListView() {
    List() {
      ForEach(this.mListDeviceInfo, (item: DeviceInfo, index: number) => {
        ListItem() {
          Column() {
            Row() {
              Text("设备ID：" + item.deviceId).fontSize(px2fp(42)).fontColor(Color.Black)
              Blank()
              Text("设备名：" + item.deviceName).fontSize(px2fp(42)).fontColor(Color.Black)
            }
            .width("100%")
            .height(px2vp(200))
            .justifyContent(FlexAlign.Start)
            .onClick(() => {
              AlertDialog.show({
                title: "选择操作",
                message: "是否选择该设备进行SPP蓝牙连接或配对?",
                autoCancel: true,
                primaryButton: {
                  value: "SPP连接",
                  action: () => {
                    promptAction.showToast({ message: item.deviceName + " SPP连接中！" });
                    this.connectToSPP(item.deviceId);
                  }
                },
                secondaryButton: {
                  value: "配对",
                  action: () => {
                    promptAction.showToast({ message: item.deviceName + "配对中！" });
                    BlueToothMgr.Ins().pairDevice(item.deviceId);
                  }
                },
                cancel: () => {
                  promptAction.showToast({ message: "取消!" });
                }
              });
            })
          }
        }
      }, (item: string, index: number) => JSON.stringify(item) + index)
    }
    .width("100%")
  }
}