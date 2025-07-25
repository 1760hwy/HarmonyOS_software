// 定义传感器数据模型
export class SensorData {
  id?: number; // 数据库自增主键，可以为空
  temperature: number; // 温度
  humidity: number; // 湿度
  lightIntensity: number; // 光照度
  timestamp: number; // 记录时间戳（建议加上，用于排序或查询特定时间段的数据）

  constructor(temperature: number, humidity: number, lightIntensity: number) {
    this.temperature = temperature;//初始化温度属性
    this.humidity = humidity;//初始化湿度属性
    this.lightIntensity = lightIntensity;//初始化光照度属性
    this.timestamp = new Date().getTime(); // 记录当前时间（以毫秒为单位）
  }
}