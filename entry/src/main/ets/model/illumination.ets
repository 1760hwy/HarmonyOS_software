import http from '@ohos.net.http';

export  interface Guangzhao{
  deviceId:string;//设备id
  apiTag:string;//设备标识符
  accessToken:string;//云平台密钥
}

export interface Ill{
  illumination:number;//导出去的正式光照值
}

/**
 * 传感器详细信息接口
 * @property {string} Name - 传感器名称（如："光照传感器"）
 * @property {string} DataType - 数据类型（如："double"）
 * @property {string} Unit - 测量单位（如："lux"）
 * @property {number} Value - 传感器最新测量值
 * @property {string} UpdateTime - 数据最后更新时间（ISO格式）
 */

interface SensorInfo {
  Name: string;
  DataType: string;
  Unit: string;
  Value: number;
  UpdateTime: string;
}

/**
 * 云平台响应数据结构接口
 * @property {number} StatusCode - HTTP状态码（200表示成功）
 * @property {string} Msg - 接口返回的提示信息
 * @property {SensorInfo} [ResultObj] - 可选的传感器数据对象（成功时包含）
 */

interface ResponseData {
  StatusCode: number;
  Msg: string;
  ResultObj?: SensorInfo;
}

export class SensorService{
  private httpClient=http.createHttp();//创建http请求

  /**
   * 获取光照强度数据
   * @param {Guangzhao} config - 包含设备认证信息的配置对象
   * @returns {Promise<Ill>} 返回包含光照强度的Promise对象
   * @throws {Error} 当HTTP请求失败或数据解析错误时抛出异常
   */

  async fetchIllumination(config:Guangzhao):Promise<Ill>{
    try {
      const url=`http://api.nlecloud.com/devices/${config.deviceId}/Sensors/${config.apiTag}`;
      console.info(`请求URL:${url}`);

      //定义请求头
      const headers: Record<string,string>={
        'AccessToken':config.accessToken,
        'Content-Type':'application/json'
      };
      console.info('请求头',headers);

      //使用await等待请求完成
      const response=await this.httpClient.request(
        url,
        {
          method:http.RequestMethod.GET,//HTTP GET方法
          header:headers,
        });
      console.info(`HTTP状态码:${response.responseCode}`);

      //检查HTTP状态码是否为200
      if (response.responseCode==200 && typeof response.result === 'string') {
        const responseData: ResponseData = JSON.parse(response.result);
        console.info(`响应数据: ${JSON.stringify(responseData)}`);

        // 检查ResultObj是否存在
        if (responseData.ResultObj) {
          const sensorInfo = responseData.ResultObj;
          console.info(`传感器名称: ${sensorInfo.Name}`);
          console.info(`数据类型: ${sensorInfo.DataType}`);
          console.info(`单位: ${sensorInfo.Unit}`);
          console.info(`最新值: ${sensorInfo.Value}`);
          console.info(`更新时间: ${sensorInfo.UpdateTime}`);

          // 返回illumination值
          const result: Ill = { illumination: sensorInfo.Value };
          return result;
        } else {
          throw new Error('No ResultObj in response');
        }
      }else {
        throw new Error(`HTTP error: ${response.responseCode}`);
      }
    }catch (error) {
      console.error('获取光照数据失败:', error instanceof Error ? error.message : String(error));
      throw new Error(error instanceof Error ? error.message : String(error));
    }
  }
}

