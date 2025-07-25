import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { mapCommon } from '@kit.MapKit';

export class MapService {
  private mapOption: mapCommon.MapOptions;

  constructor() {
    // 初始化地图参数，设置中心点坐标和缩放级别
    this.mapOption = {
      position: {
        target: {
          latitude: 27.83, // 纬度
          longitude: 113.15,// 经度
        },
        zoom: 12 // 缩放级别
      }
    };
  }

  // 申请权限
  async applyPermission(context: Context, permissions: Array<Permissions>): Promise<boolean> {
    let atManager = abilityAccessCtrl.createAtManager();
    try {
      let data = await atManager.requestPermissionsFromUser(context, permissions);
      let grantStatus: Array<number> = data.authResults;
      return grantStatus.every(item => item === 0);
    } catch (err) {
      console.error('申请权限失败', err);
      return false;
    }
  }

  // 获取地图选项
  getMapOption(): mapCommon.MapOptions {
    return this.mapOption;
  }
}