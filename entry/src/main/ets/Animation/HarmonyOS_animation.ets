@Observed
export class HarmonyOS_animation{
  public animate1:boolean=false;//总开关
  public btn1Visible:boolean =false;
  public btn2Visible:boolean =false;
  public btn3Visible:boolean =false;

  //打开动画
  openButtons(){
    this.animate1=true;
    this.btn1Visible=true;
    setTimeout(()=>{this.btn2Visible=true},2);//第二个按钮延时200ms
    setTimeout(()=>{this.btn3Visible=true},4);//同理第三个
  }

  //关闭动画
  closeButtons(){
    this.btn3Visible=false;
    setTimeout(()=>{this.btn2Visible=false},2);
    setTimeout(()=>{this.btn1Visible=false},2);
    setTimeout(()=>{this.animate1=false},2);
  }
}