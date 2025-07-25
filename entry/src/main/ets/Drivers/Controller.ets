// Controller.ets
// 小车控制逻辑类
export class Controller {
  moveForward(): void {
    // 实际硬件控制代码
    console.log("向前移动");
  }

  moveBackward(): void {
    console.log("向后移动");
  }

  turnLeft(): void {
    console.log("向左转");
  }

  turnRight(): void {
    console.log("向右转");
  }

  stop(): void {
    console.log("停止");
  }

  setSpeed(speed: number): void {
    console.log(`设置速度: ${speed} km/h`);
  }
}