export interface RandomData{
  temp:number;//温度
  hum:number;//湿度
  ill:number;//光照
}

/**
 * 生成 [min, max) 范围内的随机浮点数
 * @param min 最小值（含）
 * @param max 最大值（不含）
 */
function getRandomFloat(min:number,max:number):number{
  return Math.random()*(max-min)+min;
}

/**
 * 生成一组随机数据
 */
export function generateRandomData():RandomData{
  return{
    temp:parseFloat(getRandomFloat(32,38).toFixed(2)),
    hum:parseFloat(getRandomFloat(90,99).toFixed(2)),
    ill:parseFloat(getRandomFloat(14000,22000).toFixed(1)),
  };
}

