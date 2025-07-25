import { router } from '@kit.ArkUI'

@Entry
@Component
struct LoginPage {

  build() {
    // 使用 NavDestination 作为全屏容器
    NavDestination() {
      Column() {
        // 上半部分图片区域
        Column() {
          Stack() {
            // 底层图片
            Image($r('app.media.dl3'))
              .objectFit(ImageFit.Cover)
              .width('100%')
              .height('100%')
              .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

            // 半透明覆盖层（对应原代码的 #10FFFFFF）
            Column()
              .width('100%')
              .height('100%')
              .backgroundColor('#10FFFFFF')
              .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])



            // 内容布局（可在此添加其他内容）
            Column() {
              // 这里添加你的其他内容
            }
            .width('100%')
            .height('100%')
          }
        }
        .layoutWeight(1)  // 占据上半部分

        // 下半部分登录表单
        Column() {
          Stack() {
            // 背景图片
            Image($r('app.media.dl4'))
              .objectFit(ImageFit.Cover)
              .width('100%')
              .height('100%')
              .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

            // 半透明遮罩层（对应原代码的 #80000000）
            Column()
              .width('100%')
              .height('100%')
              .backgroundColor('#80000000')
              .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

  
            // 表单内容
            Column() {
              Text('登录')
                .fontSize(30)
                .fontColor('#FFFFFF')
                .margin({ bottom: 20 })

              TextInput({ placeholder: '请输入用户名' })
                .id('et_user_name')
                .width('90%')
                .height(40)
                .margin({ left: 10, top: 10 })
                .backgroundColor('#FFFFFF')
                .borderRadius(20)
                .placeholderColor('#808080')
                .placeholderFont({ size: 14 })

              TextInput({ placeholder: '请输入密码' })
                .id('et_user_passwd')
                .width('90%')
                .height(40)
                .margin({ left: 10, top: 20 })
                .type(InputType.Password)
                .backgroundColor('#FFFFFF')
                .borderRadius(20)
                .placeholderColor('#808080')
                .placeholderFont({ size: 14 })

              Button('登录', { type: ButtonType.Normal })
                .id('denglv')
                .width('90%')
                .height(40)
                .margin({ top: 20 })
                .border({radius:10})
                .backgroundColor('#FFDE59')
                .fontColor('#000000')
                .fontSize(20)
                .onClick(() => {
                  // 添加路由跳转逻辑
                  router.replaceUrl({
                    url: 'pages/Manager' // 根据实际路径调整
                  });
                })
            }
            .width('100%')
            .height('100%')
            .padding(16)
            .justifyContent(FlexAlign.Center)
          }
        }
        .layoutWeight(1)  // 占据下半部分
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#000000')
    }
    // 使用 NavDestination 自带的 expandSafeArea 来扩充全屏安全区
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
