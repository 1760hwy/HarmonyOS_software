// DeviceInfo.ts
export class DeviceInfo {
  /** 蓝牙设备唯一 ID */
  deviceId: string = '';
  /** 蓝牙设备名称 */
  deviceName: string = '';
  /** 蓝牙设备类型或类别码 */
  deviceClass: string = '';

  constructor(init?: Partial<DeviceInfo>) {
    if (init) {
      this.deviceId = init.deviceId ?? this.deviceId;
      this.deviceName = init.deviceName ?? this.deviceName;
      this.deviceClass = init.deviceClass ?? this.deviceClass;
    }
  }
}
