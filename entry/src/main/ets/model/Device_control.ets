import http from '@ohos.net.http';

export interface DControl{
  device:string;//设备id
  apiTag:string;//设备标识码
  accessToken:string;//密钥
}

interface ResponseData{
  StatusCode:number;//HTTP状态码
  Msg:string;//接口返回消息
}

export class SensorService{
  private httpClient=http.createHttp();//创建http请求

  async control_device(config:DControl,cmdValue:number):Promise<boolean>{
    try {
      const url = `http://api.nlecloud.com/Cmds?deviceId=${config.device}&apiTag=${config.apiTag}`;
      console.info(`请求URL:${url}`);

      //定义请求头
      const headers:Record<string,string>={
        'AccessToken':config.accessToken,
        'Content-Type':'application/json'
      };
      console.info('请求头',headers);
      console.info('请求体',String(cmdValue));

      //使用await等待请求完成
      const response=await this.httpClient.request(
        url,
        {
          method:http.RequestMethod.POST,
          header:headers,
          extraData:String(cmdValue),//发送0和1作为请求体
          readTimeout:10000 //10秒超时
        });
      console.info(`HTTP状态码:${response.responseCode}`);
      console.info(`响应体:${response.result}`);

      //检查HTTP是否为200
      if (response.responseCode === 200 && typeof response.result === 'string') {
        try {
          const responseData: ResponseData = JSON.parse(response.result);
          console.info(`响应数据: ${JSON.stringify(responseData)}`);
          // 检查 API 状态码
          if (responseData.StatusCode === 0) {
            return true;
          } else {
            console.error(`API 操作失败: ${responseData.Msg}`);
            return false;
          }
        } catch (parseError) {
          console.error(`JSON 解析失败: ${parseError}`);
          return false;
        }
      } else {
        console.error(`HTTP 请求异常, 状态码: ${response.responseCode}`);
        return false;
      }
    }catch (error){
      console.error(`请求失败:${error}`)
      return false;
    }
  }
}
