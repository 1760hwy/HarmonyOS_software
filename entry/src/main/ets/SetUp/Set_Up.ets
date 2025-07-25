import { faceDetector } from '@kit.CoreVisionKit'

@Entry
@Component
struct Set{

  @State isVoiceOn:boolean=false;

  build() {
    Stack(){
      Column(){
        Column(){
          Row(){
            Text("主题切换")
            Blank()//填中间的空位
            Toggle({type:ToggleType.Switch,isOn:this.isVoiceOn})
              .onChange((isOn:boolean)=>{
                this.isVoiceOn=isOn;
              })
          }
          .width("100%")
          .padding(20)
          .margin({top:20})
          .backgroundColor(0xFFFFFF)
          .alignItems(VerticalAlign.Center)
        }
        Column(){}
        Column(){}
        Column(){}
        Column(){}
      }
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
      .layoutWeight(1)
      .width("100%")
      .height("100%")
      .backgroundColor(0xE8E8E8)
    }
  }
}