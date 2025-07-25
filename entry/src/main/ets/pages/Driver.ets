// MainPage.ets
import { Controller } from '../Drivers/Controller';

@Entry
@Component
struct Driver {
  @State speed: number = 0;
  @State directions: string = "停止";
  private controller: Controller = new Controller();

  build() {
    Column() {
      // 状态显示区域
      this.StatusDisplay()

      // 方向控制区域
      this.DirectionPad()

      // 速度控制区域
      this.SpeedControl()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#222222')
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
  }

  // 状态显示组件
  @Builder StatusDisplay() {
    Column() {
      Text(this.directions)
        .fontSize(24)
        .fontColor('#FFFFFF')

      Text(`${this.speed} km/h`)
        .fontSize(36)
        .fontColor('#4CAF50')
        .margin({ top: 10 })
    }
    .width('100%')
    .padding(20)
  }

  // 方向控制面板
  @Builder DirectionPad() {
    Column() {
      // 前进按钮
      Button() {
        Text("↑")
          .fontSize(36)
      }
      .onClick(() => {
        this.controller.moveForward();
        this.directions = "前进";
      })
      .width(80)
      .height(80)
      .backgroundColor('#333333')
      .margin(5)

      // 左右按钮行
      Row() {
        // 左转按钮
        Button() {
          Text("←")
            .fontSize(36)
        }
        .onClick(() => {
          this.controller.turnLeft();
          this.directions = "左转";
        })
        .width(80)
        .height(80)
        .backgroundColor('#333333')
        .margin(5)

        // 停止按钮
        Button() {
          Text("●")
            .fontSize(36)
            .fontColor('#FF5252')
        }
        .onClick(() => {
          this.controller.stop();
          this.directions = "停止";
          this.speed = 0;
        })
        .width(80)
        .height(80)
        .backgroundColor('#444444')
        .margin(5)

        // 右转按钮
        Button() {
          Text("→")
            .fontSize(36)
        }
        .onClick(() => {
          this.controller.turnRight();
          this.directions = "右转";
        })
        .width(80)
        .height(80)
        .backgroundColor('#333333')
        .margin(5)
      }

      // 后退按钮
      Button() {
        Text("↓")
          .fontSize(36)
      }
      .onClick(() => {
        this.controller.moveBackward();
        this.directions = "后退";
      })
      .width(80)
      .height(80)
      .backgroundColor('#333333')
      .margin(5)
    }
    .margin({ top: 30 })
  }

  // 速度控制组件
  @Builder SpeedControl() {
    Column() {
      Slider({
        value: this.speed,
        min: 0,
        max: 100,
        step: 5,
        style: SliderStyle.OutSet
      })
        .blockColor('#4CAF50')
        .trackThickness(10)
        .onChange((value: number) => {
          this.speed = value;
          this.controller.setSpeed(value);
        })
        .width('80%')

      Row() {
        Button('低速')
          .onClick(() => {
            this.speed = 20;
            this.controller.setSpeed(20);
          })
          .backgroundColor(this.speed === 20 ? '#4CAF50' : '#333333')

        Button('中速')
          .onClick(() => {
            this.speed = 50;
            this.controller.setSpeed(50);
          })
          .backgroundColor(this.speed === 50 ? '#4CAF50' : '#333333')
          .margin({ left: 15, right: 15 })

        Button('高速')
          .onClick(() => {
            this.speed = 80;
            this.controller.setSpeed(80);
          })
          .backgroundColor(this.speed === 80 ? '#4CAF50' : '#333333')
      }
      .margin({ top: 20 })
    }
    .width('100%')
    .padding(20)
    .margin({ top: 30 })
  }
}