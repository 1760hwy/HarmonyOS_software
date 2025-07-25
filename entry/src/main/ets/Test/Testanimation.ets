// CircleMenu.ets

// @Entry 装饰器表明这是应用的入口UIAbility的主组件
// @Component 装饰器表明这是一个自定义组件
@Entry
@Component
struct CircleMenu {
  // @State 装饰器用于标记状态变量，当isExpanded的值改变时，UI会自动刷新
  @State isExpanded: boolean = false // 控制菜单是否展开的状态，默认为false（折叠）

  //私有属性，存储子按钮的数据 - 保持为4个按钮
  private subButtons: ButtonItem[] = [
    { name: '功能A', color: '#FF6B6B' },
    { name: '功能B', color: '#4ECDC4' },
    { name: '功能C', color: '#45B7D1' },
    { name: '功能D', color: '#96CEB4' }
  ]

  // 私有方法：计算每个子按钮在圆形布局中的位置
  // index: 当前按钮的索引
  // total: 子按钮的总数
  // 返回值: CustomPosition 类型，包含 x 和 y 坐标
  private calculatePosition(index: number, total: number): CustomPosition {
    // --- 修改这里的 radius 值 ---
    const radius: number = 55;  // 将布局半径改小，使子按钮更靠近主按钮
    // 原来是 100，主按钮半径30，子按钮半径20
    // 30 + 20 = 50 (紧贴)
    // 55 会留出约 5vp 的间隙
    let angle: number;

    if (total <= 0) { // 防止除以0或负数的情况
      return { x: 0, y: 0 };
    }
    if (total === 1) {
      // 如果只有一个按钮，则将其放在正左方 (180度)
      angle = 180;
    } else {
      // 我们希望按钮分布在主按钮左侧的180度弧线上
      // 角度从 90度 (正上方) 到 270度 (正下方)
      const arcSpanDegrees: number = 180; // 弧的总度数
      const startAngleDegrees: number = 90; // 起始角度 (正上方)

      // 计算每个按钮之间的角度增量
      // total - 1 因为有 total 个点，它们之间有 total - 1 个间隔
      const angleIncrement: number = arcSpanDegrees / (total - 1);
      angle = startAngleDegrees + (index * angleIncrement);
    }

    return {
      // 使用三角函数计算 x 坐标 (cos)
      x: Math.cos(angle * Math.PI / 180) * radius,
      // 使用三角函数计算 y 坐标 (sin)
      y: Math.sin(angle * Math.PI / 180) * radius
    };
  }

  // build 方法是组件UI的声明式描述
  build() {
    Stack({ alignContent: Alignment.Center }) {
      Button('+')
        .width(60)
        .height(60)
        .borderRadius(30)
        .fontSize(24)
        .backgroundColor('#646464')
        .zIndex(this.subButtons.length + 1) //确保主按钮在最上层
        .onClick(() => {
          animateTo({
            duration: 300,
            curve: Curve.EaseInOut
          }, () => {
            this.isExpanded = !this.isExpanded
          })
        })

      ForEach(this.subButtons, (item: ButtonItem, index: number) => {
        Column() {
          Text(item.name)
            .fontSize(12)
            .fontColor('#FFFFFF')
            .margin({ bottom: 4 })
          Circle()
            .width(40)
            .height(40)
            .fill(item.color)
        }
        .position({
          x: this.calculatePosition(index, this.subButtons.length).x,
          y: this.calculatePosition(index, this.subButtons.length).y
        })
        .opacity(this.isExpanded ? 1 : 0)
        .scale({
          x: this.isExpanded ? 1 : 0,
          y: this.isExpanded ? 1 : 0
        })
        .animation({
          duration: 300,
          curve: Curve.EaseInOut,
          delay: index * 50
        })
        .zIndex(index + 1)
        .onClick(() => {
          console.info(`点击了${item.name}`)
        })
      }, (item: ButtonItem) => item.name)
    }
    .width('100%')
    .height('100%')
  }
}

// 类型定义区域
interface ButtonItem {
  name: string
  color: string
}

interface CustomPosition {
  x: number
  y: number
}