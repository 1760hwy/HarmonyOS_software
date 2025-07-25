import { PromptAction, promptAction, router } from '@kit.ArkUI'
import { audio } from '@kit.AudioKit';
import { RdbHelper } from '../Data_Transmit/RdbHelper';
import { Weather, WeatherForecastData } from '../http/Weather_forecast';
import { SensorService, Guangzhao, Ill } from '../model/illumination'; // 导入 SensorService 和接口
import { generateRandomData, RandomData } from '../Test/Random_num';
import { SensorData } from '../Data_Transmit/SensorDataAbility';
import common from '@ohos.app.ability.common';
import { Speaker } from '../Test/Speaker';
import { emitter } from '@kit.BasicServicesKit';

// 创建特殊事件命名空间
const TEMP_EVENT = 'SENSOR/TEMPERATURE';
const HUM_EVENT = 'SENSOR/HUMIDITY';
const ILL_EVENT = 'SENSOR/ILLUMINATION';

@Entry
@Component
struct Manager {
  intervalId?: number;//声名为可选类型
  @State isVoiceOn:boolean=false
  //滑块百分比值
  @State volumeValue:number=50
  @State showLoading:boolean=true;//界面动画

  //随机值
  @State temp:number=26;
  @State hum:number=78;
  @State ill:number=11000;


  private rdbHelper: RdbHelper|null=null;//新增 RdbHelper 成员变量
  private context:common.UIAbilityContext | null=null;//传递给RdbHelper

  //AI朗读
  @State isClicked:boolean=false;
  speak:Speaker=new Speaker();//初始化Speaker

  //光照
  // @State illumination: number | null = null; // 存储光照值
  // private sensorService: SensorService = new SensorService(); // 创建 SensorService 实例

  // 配置参数
  // private config: Guangzhao = {
  //   deviceId: '1205414',
  //   apiTag: 'guangzhao',
  //   accessToken: '531B96E9FEDAE3751671B88B0B61FF90AB98B69EE515F2A0B941D4BA848A4A11B765E015DE99A31410E6058FC46666F907F367DB6D5103CA42CD5677616B64FF72A8C18988D316EE2592F1C917FD3502A090BA62BCE5B068793E5742F6DC75EC8CFD77483FCF87E57B05D3B983D3B71201940F3DA839222A0F57A8D9A6002FC3877024947E88AB3CC24295647DFB0B1660A1DBA43EB82552278F248AC1772A4DFDE6A68B8BBEE573E1480ACF338934744E3C19E347422D5F90AFC45B3B5737F0411F9E893F2FD0A396DA5D7F3287F834BC48B518BE1A736E6B0D2B65E33EBCCF'
  // };

  // 在组件构建时获取数据
  // async Ill() {
  //   try {
  //     const result: Ill = await this.sensorService.fetchIllumination(this.config);
  //     this.illumination = result.illumination; // 更新光照值
  //   } catch (error) {
  //     promptAction.showToast({
  //       message: `获取光照数据失败: ${error instanceof Error ? error.message : String(error)}`,
  //       duration: 3000,
  //       bottom:50
  //     });
  //   }
  // }

  //ai语音
  @State isDragging:boolean=false
  audioManager?:audio.AudioManager
  // 在Manager类中添加maxVolume私有变量
  private maxVolume: number = 0; // 存储设备的最大音量值

  //初始化音量管理器
  async aboutToAppear(){
    try {
      //获取音频管理器
      this.audioManager=await audio.getAudioManager()
      //获取最大音量
      this.maxVolume=await this.audioManager.getMaxVolume(audio.AudioVolumeType.MEDIA);
      //获取当前系统音量
      const currentVol=await this.audioManager.getVolume(audio.AudioVolumeType.MEDIA);
      //将系统音量值转换为百分比显示
      this.volumeValue=Math.round((currentVol/this.maxVolume)*100);
      this.context=getContext(this) as common.UIAbilityContext;
      if (this.context) {
        this.rdbHelper = new RdbHelper(this.context);
        console.info('Manager.ts', 'RdbHelper initialized.');
      } else {
        console.error('Manager.ts', 'Failed to get context for RdbHelper.');
      }

      //存储AppStorage的数据，用来显示界面动画
      this.showLoading=AppStorage.Get('hasLoadedManager')!==true;

      //获取天气数据
      this.weatherData=await Weather.fetchWeatherData();

      // 监听朗读完成事件
      emitter.on("ttsFinished", () => {
        this.isVoiceOn = false;
        this.isClicked = false;
        console.log("朗读完成");
      });

      // 监听朗读停止事件
      emitter.on("ttsStopped", () => {
        this.isClicked = false;
        console.log("朗读已停止");
      });

      //获取光照
      // await this.Ill();

      if (this.intervalId) {
        clearInterval(this.intervalId); // 先清除旧的定时器，避免重复创建
      }

      //初始化随机数生成
      this.intervalId = setInterval(() => {
        const rand: RandomData = generateRandomData();
        this.temp = rand.temp;
        this.hum = rand.hum;
        this.ill = rand.ill;

        this.saveSensorDataToDb();
      }, 3000);
    }catch (err){
      console.error(`初始化失败:${err}`)
    }
  }

  async saveSensorDataToDb() {
    if (!this.rdbHelper) {
      console.error('RDB', 'RdbHelper is not initialized. Cannot save data.');
      return;
    }

    // 创建 SensorData 对象
    const newData = new SensorData(this.temp, this.hum, this.ill);

    try {
      const rowId = await this.rdbHelper.insertData(newData);
      console.log(`Successfully saved data to RDB, rowId: ${rowId}`);
    } catch (e) {
      console.error('RDB', `Failed to save data: ${e.message}`);
    }
  }



  aboutToDisappear(){
    if (this.intervalId) {
      clearInterval(this.intervalId);
    }
    this.speak.stopSpeak();

    //移除事件监听
    emitter.off("ttsFinished");
    emitter.off("ttsStopped");
    emitter.off("ttsError");
  }

  private generateSpeechContent(): string {
    return `当前环境数据：温度${this.temp}摄氏度，湿度${this.hum}%，光照${this.ill}勒克斯`;
  }

  //添加终止方法
  private stopSpeech(){
    this.speak.stopSpeak();
    this.isVoiceOn=false;
  }

  //添加页面离开时的处理
  onPageHide(){
    // 页面隐藏时停止朗读
    this.speak?.stopSpeak();
    this.isVoiceOn=false;
  }


  @State selectedIndex:number=0//默认选中第一个(传感设备)
  @State selectedIndex1:number=0//下层导航栏默认选中管理平台

  @State weatherData: WeatherForecastData | null=null;//存储天气预报加载错误信息

  build() {
    Stack(){
    Column() {
      Text("当前位置:湖南省株洲市")
        .fontSize(20)
        .margin({ top:10, bottom:5,left:16})
        .width("100%")

      Row({ space: 20 }) {
        // 传感器设备
        Column() {
          Image($r("app.media.sensing"))
            .width(40)
            .height(40)
            .margin({ bottom: 8 })
            .fillColor(this.selectedIndex===0?"#66C241":"#000000")  // 直接设置颜色值
            .objectFit(ImageFit.Contain)
          Text("传感设备")
            .fontColor(this.selectedIndex===0?"#66C241":"#000000")
            .fontSize(16)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        // 控制设备
        Column() {
          Image($r("app.media.controlpage"))
            .width(40)
            .height(40)
            .foregroundColor(this.selectedIndex===1?"#66C241":"#000000")  // 直接设置颜色值
            .margin({ bottom: 8 })
            .objectFit(ImageFit.Contain)
          Text("控制设备")
            .fontSize(16)
            .fontColor(this.selectedIndex===1?"#66C241":"#000000")
        }
        .onClick(()=>{
          router.replaceUrl({
            url:"pages/Control"
          })
        })
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        // 视频设备
        Column() {
          Image($r("app.media.video"))
            .width(40)
            .height(40)
            .foregroundColor(this.selectedIndex===2?"#66C241":"#000000")  // 直接设置颜色值
            .margin({ bottom: 8 })
            .objectFit(ImageFit.Contain)
          Text("视频设备")
            .fontSize(16)
            .fontColor(this.selectedIndex===2?"#66C241":"#000000")
        }
        .onClick(()=>{
          router.replaceUrl({
            url:"pages/Video"
          })
        })
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        // 驾驶设备
        Column() {
          Image($r("app.media.driver"))
            .width(40)
            .height(40)
            .foregroundColor(this.selectedIndex===3?"#66C241":"#000000")  // 直接设置颜色值
            .margin({ bottom: 8 })
            .objectFit(ImageFit.Contain)
          Text("驾驶设备")
            .fontSize(16)
            .fontColor(this.selectedIndex===3?"#66C241":"#000000")

        }
        .onClick(()=>{
          router.replaceUrl({
            url:"Bluetooth/Interaction"
          })
        })
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .padding(16)
      .width("100%")
      Text("未来两天天气预报")
        .fontSize(20)
        .width("100%")
        .margin({left:16})//设置左边距强制左对齐

      Row(){
        Column(){
          Image($r("app.media.sum"))
            .width(30)
            .height(30)
            .margin({bottom:5})
            .objectFit(ImageFit.Contain)//保持图片比例
          Text(`最高温:${this.weatherData?.tomorrow.maxTemp}℃`)

          Text(`最低温:${this.weatherData?.tomorrow.minTemp}℃`)
        }
        .margin({top:5})
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column(){
          Image($r("app.media.cloud"))
            .width(30)
            .height(30)
            .margin({bottom:5})
            .objectFit(ImageFit.Contain)
          Text(`最高温:${this.weatherData?.dayAfterTomorrow.maxTemp}℃`)

          Text(`最低温:${this.weatherData?.dayAfterTomorrow.minTemp}℃`)
        }
        .margin({top:5})
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      Row() {
        Column({space:12}) {
          Row() {
            Image($r("app.media.wendu"))
              .width(30)
              .height(30)
              .margin({ right: 8 })
            Text(`温度:${this.temp}℃`)
              .fontSize(14)
          }
          .width(160)
          .height(60)
          .padding(8)
          .margin(4)
          .backgroundColor(Color.White)
          .border({radius:8})

          Row() {
            Image($r("app.media.guangzhao"))
              .width(30)
              .height(30)
              .margin({ right: 8 })
            //Text(this.illumination!==null ?`光照:${this.illumination}lux`:"光照:加载中...")
            Text(`光照：${this.ill}lux`)
              .fontSize(14)
          }
          .width(160)
          .height(60)
          .padding(8)
          .margin(8)
          .backgroundColor(Color.White)
          .border({radius:8})
        }
        .layoutWeight(1)
        .margin({right:10})

        Column({space:12}) {
          Row() {
            Image($r("app.media.shidu"))
              .width(30)
              .height(30)
              .margin({ right: 8 })
            Text(`湿度:${this.hum}%`)
              .fontSize(14)
          }
          .width(160)
          .height(60)
          .padding(8)
          .margin(4)
          .backgroundColor(Color.White)
          .border({radius:8})

          Row() {
            Image($r("app.media.turang"))
              .width(30)
              .height(30)
              .margin({ right: 8 })
            Text("土壤肥力:高")
              .fontSize(14)
          }
          .width(160)
          .height(60)
          .padding(8)
          .margin(8)
          .backgroundColor(Color.White)
          .border({radius:8})
        }
        .layoutWeight(1)
      }
      .padding(16)
      .width("100%")

      Column(){
        Column(){
          Text("AI语音播报设置")
            .fontSize(18)
            .fontColor(Color.Black)
            .margin({bottom:8})

          Row(){
            Text("AI开启语音播报")
              .fontSize(16)
              .layoutWeight(1)

            Toggle({type:ToggleType.Switch,isOn:this.isVoiceOn })
              .onChange((isOn:boolean)=>{
                this.isVoiceOn=isOn
              })
              .onClick(()=>{
                if (this.isVoiceOn) {
                  promptAction.showToast({
                    message:"已关闭AI语音播报",
                    duration:2000,
                    bottom:50
                  })
                  this.stopSpeech();
                }else {
                  promptAction.showToast({
                    message:"已开启AI语音播报",
                    duration:2000,
                    bottom:50
                  })
                  const content=this.generateSpeechContent();
                  this.speak.startSpeak(content);
                }
              })
          }
          .width("100%")
          .alignItems(VerticalAlign.Center)

          //音量控制行
          Row(){
            Text("音量")
              .fontSize(16)

            Slider({
              value:this.volumeValue,
              min:0,
              max:100,
              style:SliderStyle.OutSet
            })
              .layoutWeight(1)
              .margin({left:16})
              .onChange((value:number)=>{
                this.volumeValue=value
                if(this.audioManager){
                 try {
                   //将百分比转换为系统音量值
                   const systemVolume=Math.round((value/100)*this.maxVolume);

                   //设置系统媒体音量
                   this.audioManager.setVolume(audio.AudioVolumeType.MEDIA,systemVolume);
                 }catch (err) {
                   console.error(err)
                 }
                }
              })

            Text(`${this.volumeValue}%`)
              .fontSize(16)
              .margin({left:8})
          }
          .width("100%")
          .margin({top:12})
          .alignItems(VerticalAlign.Center)
        }
        .padding(12)
        .backgroundColor(Color.White)
        .margin(8)
        .width("100%")
      }
      .layoutWeight(1)
      .width("100%")


        Row(){
        Column(){
          Image($r("app.media.manage"))
            .objectFit(ImageFit.Contain)//图片适配(完全显示图片)
            .width(50)
            .foregroundColor(this.selectedIndex1===0?"#66C241":"#000000")  // 直接设置颜色值
            .height(35)
          Text("管理平台")
            .fontSize(18)
            .fontColor(this.selectedIndex1===0?"#66C241":"#000000")

        }

        .layoutWeight(1)
          .height(30)
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)

          Column(){
          Image($r("app.media.control"))
            .objectFit(ImageFit.Contain)
            .width(50)
            .foregroundColor(this.selectedIndex1===1?"#66C241":"#000000")  // 直接设置颜色值
            .height(35)
            Text("设备控制")
              .fontColor(this.selectedIndex1===1?"#66C241":"#000000")
              .fontSize(18)

          }
          .onClick(()=>{
            router.replaceUrl({
              url: "pages/Control"
            })
          })
          .layoutWeight(1)
          .height(30)
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)

          Column(){
          Image($r("app.media.analysis"))
            .objectFit(ImageFit.Contain)
            .width(50)
            .foregroundColor(this.selectedIndex1===2?"#66C241":"#000000")  // 直接设置颜色值
            .height(35)
            Text("数据分析")
              .fontSize(18)
              .fontColor(this.selectedIndex1===2?"#66C241":"#000000")

          }
          .onClick(()=>{
            router.replaceUrl({
              url:"pages/Analysis"
            });
          })
          .layoutWeight(1)
          .height(30)
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)

          Column(){
          Image($r("app.media.my"))
            .width(50)
            .height(35)
            .objectFit(ImageFit.Contain)
            .foregroundColor(this.selectedIndex1===3?"#66C241":"#000000")  // 直接设置颜色值
            Text("我的")
              .fontSize(18)
              .fontColor(this.selectedIndex1===3?"#66C241":"#000000")
          }
          .layoutWeight(1)
          .height(30)
          .onClick(()=>{
            router.replaceUrl({
              url:"pages/Myname"
            })
          })
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
        }
        .border({ width: { top: 1 }, color: '#e0e0e0' }) // 给导航栏顶部加个分割线
        .width("100%")
        .backgroundColor(Color.White)
        .margin({top:8})
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
      .backgroundColor("#E8E8E8")
      .width("100%")
      .height("100%")
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      if (this.showLoading){
        LoadingProgress()
          .width("100%")
          .height("100%")
          .color(Color.Blue)
      }
   }
    .onAppear(()=>{
      setTimeout(()=>{
        this.showLoading=false;
        AppStorage.setOrCreate("hasLoadedManager",true);
      },200);
    })
  }
}