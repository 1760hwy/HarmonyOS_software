import { bundleManager, Permissions } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
// 导入 MapKit 相关模块
import { map, mapCommon, MapComponent } from '@kit.MapKit';
import { Weather, WeatherForecastData } from '../http/Weather_forecast';
import { DControl, SensorService } from '../model/Device_control';
import { MapService } from '../model/HarmonyOS_map';
import { AsyncCallback } from '@kit.BasicServicesKit';




@Entry
@Component
struct Manager {

  @State isVoiceOn0: boolean = false
  @State isVoiceOn1: boolean = false


  @State selectedIndex:number=1//默认选中第一个(传感设备) - 注意，根据UI似乎应该是第二个“控制设备”高亮？
  @State selectedIndex1:number=1//下层导航栏默认选中管理平台 - 根据你的代码，你把它初始化为1了，但管理平台是第0个，这里改为0
  @State weatherData: WeatherForecastData | null =null;//存储天气数据
  @State isMapReady: boolean = false;


  //控制灯的开关
  private sensorService:SensorService=new SensorService();
  private deviceConfig:DControl={
    device:"1205412",
    apiTag:"baojingden",
    accessToken:"531B96E9FEDAE3751671B88B0BFF90AB98B69EE515F2A0B941D4BA848A4A11B765E015DE99A31410E6058FC46666F907F367DB6D5103CA42CD5677616B64FF72A8C18988D316EE2592F1C917FD3502A090BA62BCE5B068793E5742F6DC75EC8CFD77483FCF87E57B05D3B983D3B71201940F3DA839222A0F57A8D9A6002FC3877024947E88AB3CC24295647DFB0B1660A1DBA43EB82552278F248AC1772A4DFDE6A68B8BBEE573E1480ACF338934744E3C19E347422D5F90AFC45B3B5737F0411F9E893F2FD0A396DA5D7F3287F834BC48B518BE1A736E6B0D2B65E33EBCCF"
  };

  //地图
  private mapService: MapService=new MapService();
  private mapOption?: mapCommon.MapOptions;
  private mapCallback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;

  async aboutToAppear(){
    this.weatherData=await Weather.fetchWeatherData();
    // 实例化后端服务
    this.mapService = new MapService();
    // 申请权限并初始化地图
    let permissions: Array<Permissions> = ['ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION'];
    this.mapService.applyPermission(getContext(this), permissions).then((granted) => {
        this.initMap();
    });
  }

  private initMap(): void {
    // 获取地图选项
    this.mapOption = this.mapService.getMapOption();

    // 定义地图初始化回调
    this.mapCallback = (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        // 启用我的位置图层和按钮
        this.mapController.setMyLocationEnabled(true);
        this.mapController.setMyLocationControlsEnabled(true);
      }
    };
    this.isMapReady=true;
  }

  build() {
    // 用 Stack 将主要内容和底部导航栏叠加
    Stack() {
      // 主内容部分（底层）
      Column() {
        Text("当前位置:湖南省株洲市") // 建议这里可以动态获取或显示更精确的位置
          .fontSize(20)
          .margin({ top: 10, bottom: 5, left: 16 })
          .width("100%")
          .textAlign(TextAlign.Start) // 确保文本左对齐

        // --- 设备分类 ---
        Row({ space: 20 }) {
          // 传感设备
          Column() {
            Image($r("app.media.sensing"))
              .width(40)
              .height(40)
              .foregroundColor(this.selectedIndex === 0 ? "#66C241" : "#000000") // 根据selectedIndex高亮
              .margin({ bottom: 8 })
              .objectFit(ImageFit.Contain)
            Text("传感设备")
              .fontSize(16)
              .fontColor(this.selectedIndex === 0 ? "#66C241" : "#000000")
          }
          .onClick(() => {
            // 点击传感设备时更新selectedIndex
            this.selectedIndex = 0;
            // 这里可以根据需要决定是否跳转，如果只是切换上方分类显示，可能不需要跳转
            router.replaceUrl({ url:"pages/Manager" }) // 跳转回自己可能不是期望行为，除非是刷新？
            console.info("传感设备 clicked");
          })
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          // 控制设备
          Column() {
            Image($r("app.media.controlpage"))
              .width(40)
              .height(40)
              .margin({ bottom: 8 })
              .foregroundColor(this.selectedIndex === 1 ? "#66C241" : "#000000")
              .objectFit(ImageFit.Contain)
            Text("控制设备")
              .fontSize(16)
              .fontColor(this.selectedIndex === 1 ? "#66C241" : "#000000")
          }
          .onClick(() => {
            this.selectedIndex = 1; // 更新状态
            console.info("控制设备 clicked");
          })
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          // 视频设备
          Column() {
            Image($r("app.media.video"))
              .width(40)
              .foregroundColor(this.selectedIndex === 2 ? "#66C241" : "#000000")
              .height(40)
              .margin({ bottom: 8 })
              .objectFit(ImageFit.Contain)
            Text("视频设备")
              .fontColor(this.selectedIndex === 2 ? "#66C241" : "#000000")
              .fontSize(16)
          }
          .onClick(() => {
            this.selectedIndex = 2; // 更新状态
            router.replaceUrl({url:"pages/Video"})
            console.info("视频设备 clicked");
          })
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          // 驾驶设备
          Column() {
            Image($r("app.media.driver"))
              .width(40)
              .foregroundColor(this.selectedIndex === 3 ? "#66C241" : "#000000")
              .height(40)
              .margin({ bottom: 8 })
              .objectFit(ImageFit.Contain)
            Text("驾驶设备")
              .fontSize(16)
              .fontColor(this.selectedIndex === 3 ? "#66C241" : "#000000")
          }
          .onClick(() => {
            this.selectedIndex = 3; // 更新状态
            console.info("驾驶设备 clicked");
          })
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }
        .padding(16)
        .width("100%")

        // --- 天气预报 ---
        Text("未来两天天气预报") // 建议这部分数据动态获取
          .fontSize(20)
          .width("100%")
          .margin({ left: 16, top: 10, bottom: 5 })
          .textAlign(TextAlign.Start) // 确保文本左对齐

        Row() {
          Column() {
            Image($r("app.media.sum")) // 假设是晴天图标
              .width(30)
              .height(30)
              .margin({ bottom: 5 })
              .objectFit(ImageFit.Contain)
            Text(`最高温: ${this.weatherData?.tomorrow.maxTemp}℃`) // 数据应该是动态的
            Text(`最低温: ${this.weatherData?.tomorrow.minTemp}℃`) // 数据应该是动态的
          }
          .margin({ top: 5 })
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          Column() {
            Image($r("app.media.cloud")) // 假设是多云图标
              .width(30)
              .height(30)
              .margin({ bottom: 5 })
              .objectFit(ImageFit.Contain)
            Text(`最高温: ${this.weatherData?.dayAfterTomorrow.maxTemp}℃`) // 数据应该是动态的
            Text(`最低温: ${this.weatherData?.dayAfterTomorrow.minTemp}℃`) // 数据应该是动态的
          }
          .margin({ top: 5 })
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }
        .width("100%")
        .padding({ left: 16, right: 16, bottom: 10 })

        // --- 控制开关 ---
        Row({ space: 10 }) { // 增加一点列间距
          Column({ space: 12 }) {
            Row() {
              Image($r("app.media.putter"))
                .width(40)
                .height(40)
                .margin({ right: 8 })
              Text("推杆")
                .fontSize(16)
                .layoutWeight(1) // 让文本占据剩余空间，将开关推到右边
              Toggle({ type: ToggleType.Switch, isOn: this.isVoiceOn0 })
                .onChange((isOn: boolean) => {
                  this.isVoiceOn0 = isOn;
                  console.log(`推杆状态: ${isOn}`);
                  // 在这里添加控制推杆的逻辑
                })
            }
            .width("100%")
            .padding(8)
            // .margin(4) // Row 设置了 space，这里 margin 可能不需要或调整
            .backgroundColor(Color.White)
            .borderRadius(8) // 使用 borderRadius 替代 border({ radius: 8 })
            .alignItems(VerticalAlign.Center) // 垂直居中对齐 Row 内容
          }
          .layoutWeight(1) // 让两个控制列均分布局
          // .margin({ right: 10 }) // Row 设置了 space，这里 margin 可能不需要

          Column({ space: 12 }) {
            Row() {
              Image($r("app.media.lamp"))
                .width(40)
                .height(40)
                .margin({ right: 8 })
              Text("灯泡")
                .fontSize(16)
                .layoutWeight(1) // 让文本占据剩余空间，将开关推到右边
              Toggle({ type: ToggleType.Switch, isOn: this.isVoiceOn1 })
                .onChange(async (isOn: boolean) => {
                  this.isVoiceOn1 = isOn;
                  console.log(`灯泡状态: ${isOn}`);
                  const cmdValue=isOn?1:0;
                  const success=await this.sensorService.control_device(this.deviceConfig,cmdValue);
                  if (success) {
                    console.info("控制灯泡成功")
                  }else {
                    console.error("控制灯泡失败")
                  }
                  // 在这里添加控制灯泡的逻辑
                })
              // .margin({left:10}) // 因为用了 layoutWeight，这个 margin 可能不再需要
            }
            .width("100%")
            .padding(8)
            // .margin(4) // Row 设置了 space，这里 margin 可能不需要
            .backgroundColor(Color.White)
            .borderRadius(8) // 使用 borderRadius
            .alignItems(VerticalAlign.Center) // 垂直居中对齐 Row 内容
          }
          .layoutWeight(1) // 让两个控制列均分布局
        }
        .padding(16)
        .width("100%")

        // --- 地图容器 ---
        // 这里是我们放置地图组件的地方
        Column() {
          if (this.isMapReady){
            MapComponent({
              mapOptions:this.mapOption,
              mapCallback:this.mapCallback
            })
              .width("100%")
              .height("100%")
          }else {
            Text("地图加载中...")
              .fontSize(18)
              .fontColor(Color.Gray)
          }
        }
        .layoutWeight(1) // 让地图容器占据剩余的垂直空间
        .width("100%")
        .margin({ top: 10 }) // 给地图上方加点边距
        // --- 地图容器结束 ---

      }
      .width("100%")
      //.height("100%") // 让主内容 Column 填满 Stack (除开底部导航栏高度) - 这可能需要调整，取决于Stack如何处理子元素高度
      .padding({bottom:60})

      // --- 底部导航栏部分 ---
      Row() {
        // 管理平台
        Column() {
          Image($r("app.media.manage"))
            .objectFit(ImageFit.Contain)
            .width(50) // 稍微调小图标和文字以适应导航栏高度
            .height(35)
            .foregroundColor(this.selectedIndex1 === 0 ? "#66C241" : "#000000")
          Text("管理平台")
            .fontSize(18) // 调小字体
            .fontColor(this.selectedIndex1 === 0 ? "#66C241" : "#000000")
        }
        .onClick(() => {
          if (this.selectedIndex1 !== 0) { // 仅在未选中时才导航
            this.selectedIndex1 = 0; // 更新选中状态
            console.info("Navigating to Manager page");
            router.replaceUrl({ url: "pages/Manager" }); // 假设 Manager 就是当前页面/管理平台页
          }
        })
        .layoutWeight(1)
        .height(30)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)

        // 设备控制
        Column() {
          Image($r("app.media.control"))
            .objectFit(ImageFit.Contain)
            .width(50)
            .height(35)
            .foregroundColor(this.selectedIndex1 === 1 ? "#66C241" : "#000000")
          Text("设备控制")
            .fontSize(18)
            .fontColor(this.selectedIndex1 === 1 ? "#66C241" : "#000000")
        }
        .onClick(() => {
          if (this.selectedIndex1 !== 1) {
            this.selectedIndex1 = 1;
            console.info("Navigating to Device Control page (Not implemented)");
            // 这里应该导航到设备控制页面
            // router.replaceUrl({ url: "pages/DeviceControl" }); // 示例
          }
        })
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .height(30)

        // 数据分析
        Column() {
          Image($r("app.media.analysis"))
            .objectFit(ImageFit.Contain)
            .width(50)
            .height(35)
            .foregroundColor(this.selectedIndex1 === 2 ? "#66C241" : "#000000")
          Text("数据分析")
            .fontSize(18)
            .fontColor(this.selectedIndex1 === 2 ? "#66C241" : "#000000")
        }
        .onClick(() => {
          if (this.selectedIndex1 !== 2) {
            this.selectedIndex1 = 2;
            console.info("Navigating to Analysis page");
            router.replaceUrl({ url: "pages/Analysis" });
          }
        })
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .height(30)

        // 我的
        Column() {
          Image($r("app.media.my"))
            .width(50)
            .height(35)
            .foregroundColor(this.selectedIndex1 === 3 ? "#66C241" : "#000000")
            .objectFit(ImageFit.Contain)
          Text("我的")
            .fontSize(18)
            .fontColor(this.selectedIndex1 === 3 ? "#66C241" : "#000000")
        }
        .onClick(() => {
          if (this.selectedIndex1 !== 3) {
            this.selectedIndex1 = 3;
            console.info("Navigating to My/Profile page (Not implemented)");
            // 这里应该导航到“我的”页面
             router.replaceUrl({ url: "pages/Myname" }); // 示例
          }
        })
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .height(30)
      }
      .width("100%")
      .backgroundColor(Color.White)
      .border({ width: { top: 1 }, color: '#e0e0e0' }) // 给导航栏顶部加个分割线
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]) // 使用 SafeArea
      .height(30)
      .position({ left: 0, right: 0, bottom: 0 })
    }
    .backgroundColor("#F5F5F5") // 稍微调整背景色
    .width("100%")
    .height("100%")
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]) // 使用 SafeArea
  }
}