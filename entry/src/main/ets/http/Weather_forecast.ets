// src/main/ets/Weather_forecast.ts

import http from '@ohos.net.http';//Http网络请求模块

// 日志标签 (用于 console 或 hilog)
// import hilog from '@ohos.hilog';
// const HI_LOG_DOMAIN = 0x0001; // 如果使用 hilog，可定义日志域
const TAG = 'WeatherForecast';//定义日志标签

// 彩云天气 API 配置
const API_KEY = "kEW0dciQ5rc99ASB";//开发者密钥
const LOCATION = "113.131695,27.827433";//固定经纬度
const BASE_URL = `https://api.caiyunapp.com/v2.5/${API_KEY}/${LOCATION}/weather.json?lang=zh_CN&unit=metric`;
//HTTP协议请求头URL构建

// --- API 响应类型定义 ---

interface ApiTemperatureItem {
  max: number;//当日最高温
  min: number;//当然最低温
}

interface ApiSkyconItem {
  value: string;//天气现象
  date: string;//对应日期
}

interface ApiDailyData {
  temperature: ApiTemperatureItem[];//未来多日温度预报数组
  skycon: ApiSkyconItem[];//未来多日天气现象数组
}

interface ApiResult {
  daily: ApiDailyData;//包含每日预报数据
}

interface ApiResponse {
  status: string;//请求状态
  api_version: string;//API版本
  api_status: string;//API服务状态
  lang: string;//语言
  unit: string;//单位制
  tz: string;//时区
  timestamp: number;//数据时间戳
  result: ApiResult;//核心数据内容
}

// --- 内部使用的简化类型 ---
/* 单日天气预报 */
export  interface ForecastItem {
  maxTemp: number;//最高温
  minTemp: number;//最低温
  skycon: string;//天气现象
}

export  interface WeatherForecastData {
  tomorrow: ForecastItem;//明日预报
  dayAfterTomorrow: ForecastItem;//后天预报
}

/**
 * Weather_forecast
 * 使用 @ohos.net.http 模块，在 HarmonyOS 5.0.4 / API16 环境下
 * 异步获取并解析彩云天气 “明天” 和 “后天” 的预报数据。
 */
 export class Weather_forecast {
  /**
   * 获取天气数据（核心方法）
   * 流程说明：
   * 1. 创建HTTP请求实例
   * 2. 发起GET请求获取原始数据
   * 3. 校验响应状态码
   * 4. 解析JSON数据
   * 5. 进行数据结构校验
   * 6. 提取目标数据并构建返回对象
   * @returns {Promise<WeatherForecastData|null>} 标准化天气预报数据（失败时返回null）
   */
  async fetchWeatherData(): Promise<WeatherForecastData | null> {
    let request: http.HttpRequest | null = null;
    try {
      console.info(TAG, `请求 URL: ${BASE_URL}`);
      // 创建 HttpRequest 实例
      request = http.createHttp();//创建HTTP请求实例

      // 发起 GET 请求，并 await 返回值
      const response = await request.request(BASE_URL, {
        method: http.RequestMethod.GET,
        connectTimeout: 10000,//连接超时时间
        readTimeout: 10000,//读取超时时间
      });

      //检查HTTP状态码
      console.info(TAG, `HTTP 响应状态码: ${response.responseCode}`);
      if (response.responseCode !== 200) {
        console.error(TAG, `HTTP 错误: ${response.responseCode}`);
        return null;
      }

      // 解析响应体类型
      const bodyText = response.result;
      if (typeof bodyText !== 'string') {
        console.error(TAG, '响应体不是字符串，无法解析');
        return null;
      }

      //解析JSON数据
      let json: ApiResponse;
      try {
        json = JSON.parse(bodyText);
        console.info(TAG, 'JSON 解析成功');
      } catch (parseErr) {
        console.error(TAG, `JSON 解析失败: ${(parseErr as Error).message}`);
        return null;
      }

      // 数据结构完整性校验
      const daily = json.result.daily;
      if (!daily
        || !Array.isArray(daily.temperature)
        || !Array.isArray(daily.skycon)
        || daily.temperature.length < 3
        || daily.skycon.length < 3
      ) {
        console.error(TAG, '返回数据格式或长度不符合预期');
        return null;
      }

      //提取目标数据索引(1.明天,2.后天)
      const tmr = daily.temperature[1];
      const sgt = daily.skycon[1];
      const dayAfter = daily.temperature[2];
      const sgAfter = daily.skycon[2];

      // 再次类型检查(二次数据类型校验)
      if (
        typeof tmr.max !== 'number' || typeof tmr.min !== 'number' ||
          typeof sgt.value !== 'string' ||
          typeof dayAfter.max !== 'number' || typeof dayAfter.min !== 'number' ||
          typeof sgAfter.value !== 'string'
      ) {
        console.error(TAG, '天气数据项类型不符合预期');
        return null;
      }

      // 构造返回对象,构建标准化数据(温度取整)
      const result: WeatherForecastData = {
        tomorrow: {
          maxTemp: Math.round(tmr.max),
          minTemp: Math.round(tmr.min),
          skycon: sgt.value,
        },
        dayAfterTomorrow: {
          maxTemp: Math.round(dayAfter.max),
          minTemp: Math.round(dayAfter.min),
          skycon: sgAfter.value,
        },
      };

      console.info(TAG, '天气预报解析完成');
      return result;
    } catch (e) {
      // 捕获并打印任何错误,统一错误处理
      if (e instanceof Error) {
        console.error(TAG, `请求异常: ${e.message}`);
      } else {
        console.error(TAG, `未知异常: ${e}`);
      }
      return null;
    } finally {
      // 一定要销毁 HttpRequest 实例，释放资源,释放网络资源
      if (request) {
        request.destroy();
        console.info(TAG, '请求实例已销毁');
      }
    }
  }

  /**
   * 将 skycon 值映射为逻辑图标名，供 UI 层使用
   */
  /**
   * 天气现象代码转图标逻辑名
   * @param {string|null} skycon - 原始天气现象代码
   * @returns {string} 对应的图标逻辑名称（与UI资源匹配）
   */
  getWeatherIconLogicalName(skycon?: string | null): string {
    if (!skycon) {
      console.warn(TAG, 'skycon 为空或未定义');
      return 'unknown';
    }
    switch (skycon.toUpperCase()) {
      case 'CLEAR_DAY':
      case 'CLEAR_NIGHT':    return 'sun';
      case 'PARTLY_CLOUDY_DAY':
      case 'PARTLY_CLOUDY_NIGHT': return 'cloudy_partial';
      case 'CLOUDY':         return 'cloudy';
      case 'WIND':           return 'wind';
      case 'HAZE':
      case 'DUST':           return 'haze';
      case 'FOG':            return 'fog';
      case 'LIGHT_RAIN':
      case 'MODERATE_RAIN':
      case 'HEAVY_RAIN':
      case 'STORM_RAIN':     return 'rain';
      case 'THUNDER_SHOWER': return 'thunder_shower';
      case 'LIGHT_SNOW':
      case 'MODERATE_SNOW':
      case 'HEAVY_SNOW':
      case 'STORM_SNOW':     return 'snow';
      case 'ICE_PELT':
      case 'FREEZING_RAIN':  return 'ice';
      case 'SLEET':          return 'sleet';
      default:
        console.warn(TAG, `未知 skycon: ${skycon}`);
        return 'cloudy_partial';
    }
  }
}

// 导出单例，页面中直接调用 Weather.fetchWeatherData()
export const Weather: Weather_forecast = new Weather_forecast();

