// MyPage_corrected_curve.arkts (Frontend - View)
import router from "@ohos.router";
import { Animator, ButtonModifier, curves, UIContext } from "@kit.ArkUI";
import { FaultLogger } from "@kit.PerformanceAnalysisKit";
import { HarmonyOS_animation } from "../Animation/HarmonyOS_animation";
import { url } from "@kit.ArkTS";
import { Swiper_image } from "../http/Swiper_image";


// 确保ViewModel的路径正确
@Entry
@Component
struct MyPage {

  private swiperInstance:Swiper_image=new Swiper_image();//初始化

  @State animate:boolean=false;//监测动画
  @State rotateValue:number=0;//组件一旋转角度


  build() {
    Stack(){
    Column() {
      // --- 其他UI元素 ---
      Column() {
        Row() {
          Image($r("app.media.my"))
            .width(60)
            .height(60)
            .objectFit(ImageFit.Cover)
            .borderRadius(30)
          Column() {
            Text("用户名")
              .fontSize(18)
              .fontColor(0x000000)
              .fontWeight(FontWeight.Bold)
            Text("ID: 123456")
              .fontSize(14)
              .fontColor(0x666666)
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 16 })
        }
        .width("100%")
        .padding(20)
        .margin({ top: 20 })
        .backgroundColor(0xFFFFFF)
        .alignItems(VerticalAlign.Center)

        Column() {
          Row() {
            Image($r("app.media.manage")).width(24).height(24)
            Text("管理平台")
              .fontSize(16)
              .fontColor(0x000000)
              .margin({ left: 16 })
          }
          .width("100%")
          .padding(16)
          .margin({ top: 30 })
          .backgroundColor(0xFFFFFF)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            console.info("管理平台 Clicked");
            router.replaceUrl({ url: "pages/Manager" });
          })
          Row() {
            Image($r("app.media.concerning"))
              .width(24)
              .height(24)
            Text("关于平台")
              .fontSize(16)
              .fontColor(0x000000)
              .margin({ left: 16 })
          }
          .width("100%")
          .padding(16)
          .margin({ top: 30 })
          .backgroundColor(0xFFFFFF)
          .alignItems(VerticalAlign.Center)
          .onClick(() => { console.info("关于平台 Clicked"); })
          Row() {
            Image($r("app.media.setting"))
              .width(24)
              .height(24)
            Text("设置")
              .fontSize(16)
              .fontColor(0x000000)
              .margin({ left: 16 })
          }
          .width("100%")
          .padding(16)
          .margin({ top: 30 })
          .backgroundColor(0xFFFFFF)
          .alignItems(VerticalAlign.Center)
          .onClick(() => { console.info("设置 Clicked"); })
        }
        .width("100%").margin({ top: 8 })
        // --- 其他UI元素结束 ---

        RelativeContainer() {
          Swiper(){
            ForEach(this.swiperInstance.swiperList,(item:string)=>{
              Image(item)
                .width("100%")
                .height(200)
                .border({radius:10})
                .margin({top:20})
                .objectFit(ImageFit.Contain)
            })
          }
          .autoPlay(true)

          Button("切换")
            .fontSize(14)
            .borderRadius(5)
            .width(60)
            .height(60)
            .margin({top:260,left:300})
            .rotate({angle:this.rotateValue})
            .onClick(() => {
              this.getUIContext()?.animateTo({curve:curves.springMotion()},()=>{
                this.animate=!this.animate;
                this.rotateValue=this.animate?-45:0;
              });
            })
            .align(Alignment.Center)
          if (this.animate){
            Button({type:ButtonType.Circle,stateEffect:true}){
              Image($r('app.media.manage'))
                .width(26)
                .height(26)
                .objectFit(ImageFit.Contain)
            }
            .onClick(()=>{
              this.getUIContext().getRouter().pushUrl({url:"pages/Manager"})
            })
            .fontSize(12)
            .width(40)
            .height(40)
            .align(Alignment.Center)
            .margin({top:200,left:300})
            .backgroundColor(0xF55A42)


            Button({type:ButtonType.Circle,stateEffect:true}){
              Image($r("app.media.control"))
                .width(26)
                .height(26)
                .objectFit(ImageFit.Contain)
            }
            .onClick(()=>{
              this.getUIContext().getRouter().pushUrl({url:"pages/Control"})
            })
            .fontSize(12)
            .width(40)
            .height(40)
            .align(Alignment.Center)
            .margin({top:240,left:250})
            .backgroundColor(0xF55A42)

            Button({type:ButtonType.Circle,stateEffect:true}){
              Image($r("app.media.analysis"))
                .width(26)
                .height(26)
                .objectFit(ImageFit.Contain)
            }
            .onClick(()=>{
              this.getUIContext().getRouter().pushUrl({url:"pages/Analysis"})
            })
            .fontSize(12)
            .width(40)
            .height(40)
            .align(Alignment.Center)
            .margin({top:300,left:260})
            .backgroundColor(0xF55A42)
          }

        }
        .width("100%")
        .height("100%")
        .backgroundColor(0xFFF0F0F0)
      }
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .layoutWeight(1)
      .width("100%")
      .backgroundColor(0xF5F5F5)
    }
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .width("100%")
      .height("100%")
      .backgroundColor(0xE8E8E8)
    }
  }
}

