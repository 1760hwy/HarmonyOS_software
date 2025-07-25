import { textToSpeech } from "@kit.CoreSpeechKit";
import { BusinessError, emitter } from "@kit.BasicServicesKit";

export class Speaker{
  //添加状态标记
  private isSpeaking:boolean=false;
  private engineInitializad:boolean=false;

  //封装语音朗读模块
  ttsEngine?:textToSpeech.TextToSpeechEngine;

  //创建一个TextToSpeechEngine实例,并初始化引擎
  initParamsInfo:textToSpeech.CreateEngineParams= {
    language: "zh-CN",//设置语音为在我
    person: 0,//默认发英人，跟小艺一样
    online: 1,//1（语音在线服务）表示网络，这样效果更好的，表示使用在线服务（效果更好但需要网络），0 表示使用本地服务（离线可用，但音质或功能可能受限）
    extraParams:{"style":'interaction-broadcast',"locate":'CN',"name":'EngineName'}
  };

  //定义一个可选的语音播报监听器（SpeakListener）变量
  speakListener?:textToSpeech.SpeakListener;

  initListener(){
    this.speakListener={
      /**
       * onStart：当 TTS 开始播报时触发
       * @param requestId - 请求 ID，用于标识当前请求
       * @param response - 响应对象，包含启动相关信息
       */
      onStart(requestId:string,response:textToSpeech.StartResponse){},
      /**
       * onComplete：当 TTS 合成完成并播报完毕时触发
       * @param requestId - 请求 ID
       * @param response - 包含完成信息的对象
       */
      onComplete(requestId:string,response:textToSpeech.CompleteResponse){
        // 如果 type === 1，表示成功完成合成和播报
        if (response.type===1) {
          this.isSpeaking=false;
          // 使用事件总线 emitter 发送一个事件 "eventId"，通知其他模块进行下一步操作
          emitter.emit("ttsFinished");
        }
      },
      /**
       * onStop：当 TTS 被主动停止时触发
       * @param requestId - 请求 ID
       * @param response - 停止响应对象
       */
      onStop(requestId:string,reponse:textToSpeech.StopResponse){
        if (reponse.type===1) {
          this.isSpeaking=false;
          // 触发事件，通知其他组件
          emitter.emit("ttsStopped");
        }
      },
      /**
       * onData：音频数据返回回调，用于获取合成后的音频流
       * @param requestId - 请求 ID
       * @param audio - 音频数据（ArrayBuffer）
       * @param response - 响应对象
       */
      onData(requestId:string,audio:ArrayBuffer,response:textToSpeech.SynthesisResponse){},  // 在这里可以处理音频流，比如保存到本地或播放
      /**
       * onError：发生错误时的回调
       * @param requestId - 请求 ID
       * @param errorCode - 错误码
       * @param errorMessage - 错误信息
       */
      onError(requestId:string,errorCode:number,errorMessage:string){
        this.isSpeaking=false;
      } // 可以在这里处理错误信息，比如提示用户或记录日志

    };
  }
  //编写初始化引擎的函数，在函数中调用textToSpeech的createEngine函数，并在createEngine函数的第一个位置传入刚刚定义的引擎创建参数，该函数支持回调形式与Promise形式的调用方式，此处采用回调的形式，在回调函数中可以拿到创建的引擎实例，并赋值给Speaker类的ttsEngine变量，并使用引擎的setListener方法绑定回调配置。
  creatEngine(){
    if (this.engineInitializad && this.ttsEngine) return;
    try {
      textToSpeech.createEngine(
        this.initParamsInfo,
        (err: BusinessError,textToSpeechEngine:textToSpeech.TextToSpeechEngine)=>{
          if (!err) {
            this.ttsEngine=textToSpeechEngine;
            this.ttsEngine.setListener(this.speakListener);
            this.engineInitializad=true;//标记已经初始化
          }else {
            this.engineInitializad=false;
          }
        });
    }catch (error) {
      this.engineInitializad=false;
      let message=(error as BusinessError).message;
      let code=(error as BusinessError).code;
    }
  }
  //构造函数中进行监听器和引擎的初始化。
  constructor() {
    this.initListener()
    this.creatEngine()
  }

  /**
   * peed为合成音频播报时的语速，支持范围[0.5-2]，不传参时默认为1。
   volume为合成音频播报时的音量，支持范围[0-2]，不传参时默认为1。
   pitch为合成音频播报时的音调，支持范围[0.5-2]，不传参时默认为1。
   playType为合成类型，不传参时默认为1。当该参数为0时表示仅合成不播报，返回音频流，为1时表示合成与播报不返回音频流。
   soundChannel为通道，参数范围0-16，整数类型，可参考音频流使用类型介绍来选择适合自己的音频场景。不传参时默认为3，语音助手通道。
   queueMode为播报模式，不传参时默认为0。0为排队模式播报，1为抢占模式播报。
   */
  extraParam:Record<string,Object>={
    "queueMode": 0,
    "speed": 1,
    "volume": 2,
    "pitch": 1,
    "languageContext": 'zh-CN',
    "audioType": "pcm",
    "soundChannel": 3,
    "playType": 1
  }

  speakParams:textToSpeech.SpeakParams={
    requestId:Date.now().toString(),
    extraParams:this.extraParam
  };


  //朗读函数
  startSpeak(content:string){
    if (!this.engineInitializad) {
      this.creatEngine();
      setTimeout((): void => this.startSpeak(content),100);
      return;
    }

    if (this.isSpeaking) {
      this.stopSpeak();//如果正在播报先停止
    }
    this.speakParams.requestId=Date.now().toString();//更新requestId
    this.isSpeaking=true;
    this.ttsEngine?.speak(content,this.speakParams);
  }

  stopSpeak(){
    if (this.ttsEngine && this.isSpeaking) {
      this.ttsEngine?.stop();
      this.isSpeaking=false;
    }

  }

  shutdownEngine(){
    this.stopSpeak();//只停止不销毁
    //保持可用状态
  }
}
