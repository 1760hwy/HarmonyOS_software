import { media } from '@kit.MediaKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { prompt, router } from '@kit.ArkUI';
import { NodePlayer, NodePlayerController } from '@nodemedia/nodemediaclient';
import { TPLinkCamera } from '../http/TpCloud';
import { TPLinkCameraService } from '../http/TPLinkCameraService';

const PAGE_TAG = 'VideoPage';

@Entry
@Component
struct VideoPage {

  private cameraService:TPLinkCameraService=new TPLinkCameraService();
  @State videoUrl: string = ''; // 用于绑定到 Video 组件的 src
  @State isPlaying: boolean = false; // 跟踪播放状态，用于控制按钮显示
  @State isLoading: boolean = false; // 用于显示加载状态
  @State errorMessage: string | null = null; // 用于显示错误消息

  async aboutToAppear(){
    console.log(PAGE_TAG, 'aboutToAppear: Initializing player...');
    await this.initPlayer();
  }

  async initPlayer() {
    this.isLoading = true; // 开始加载
    this.errorMessage = null; // 清除旧的错误信息
    this.videoUrl = ''; // 清空旧的 URL
    this.isPlaying = false;

    console.log(PAGE_TAG, 'initPlayer: Attempting to get stream URL...');
    try {
      // 调用您的服务获取视频流 URL
      const url = await this.cameraService.getStreamUrl();
      if (url && typeof url === 'string' && url.length > 0) {
        console.log(PAGE_TAG, `initPlayer: Obtained stream URL: ${url}`);
        // 将获取到的 URL 设置到 @State videoUrl 变量中
        // 这种方式会让 <Video src={this.videoUrl} ... /> 组件自动更新并尝试播放
        this.videoUrl = url;
        this.isPlaying = true; // 设置播放状态
        this.isLoading = false; // 加载完成
        console.log(PAGE_TAG, 'initPlayer: Video URL set, waiting for autoplay or UI render.');
      } else {
        const msg = 'Failed to get a valid stream URL from the service.';
        console.error(PAGE_TAG, `initPlayer: ${msg}`);
        this.errorMessage = msg;
        this.isLoading = false; // 加载失败
        this.isPlaying = false;
      }
    } catch (error) {
      let errorMsg = 'An unexpected error occurred while getting the stream URL.';
      if (typeof error === 'object' && error !== null && 'message' && error) {
        errorMsg = `Error fetching stream URL: ${error.message}`;
      } else if (typeof error === 'string') {
        errorMsg = `Error fetching stream URL: ${error}`;
      }
      console.error(PAGE_TAG, `initPlayer: ${errorMsg}`);
      this.errorMessage = errorMsg;
      this.isLoading = false; // 加载失败
      this.isPlaying = false;
    }
  }

  // onPageHide 在页面从屏幕移除时调用
  onPageHide() {
    console.log(PAGE_TAG, 'onPageHide: Stopping camera stream and releasing resources.');
    // 调用您的服务停止摄像头流（如果您的服务有此功能）
    // 如果 TPLinkCameraService.stopCameraStream() 用于释放其内部持有的资源
    // 是需要调用的
    this.cameraService.stopCameraStream(); // 确保您的服务中有这个方法

    // *** 重要说明 ***
    // 如果您是通过 <Video> 组件来播放，您不需要手动管理 media.AVPlayer 实例，
    // 也无需在此调用 stop() 或 release()。
    // `<Video>` 组件会自动处理其生命周期和资源的释放。
    // 如果您真的在 initPlayer() 里手动创建了 avPlayer 并且用了一个 SurfaceID (后面没有的代码显示了)，
    // 那才需要在 onPageHide 里手动释放。但既然您用了 <Video src={this.videoUrl}>，就意味着依赖其封装的播放器。
    // 因此，我注释掉手动释放 AVPlayer 的代码。
    // if (this.avPlayer) {
    //   try {
    //     this.avPlayer.stop();
    //     this.avPlayer.release();
    //     this.avPlayer = null;
    //     console.log(PAGE_TAG, 'Manual AVPlayer resources released.');
    //   } catch (err) {
    //     console.error(PAGE_TAG, `Failed to release AVPlayer: ${JSON.stringify(err)}`);
    //   }
    // }

    // 清空 URL 可以确保在返回时停止播放，尽管 onPageHide 本身可能就能让组件不活跃。
    this.videoUrl = '';
    this.isPlaying = false;
    this.isLoading = false;
  }

  // 添加一个辅助方法来显示状态文本
  private getCurrentStatus(): string {
    if (this.isLoading) {
      return '加载中...';
    } else if (this.errorMessage) {
      return `错误: ${this.errorMessage}`;
    } else if (this.isPlaying) {
      return '正在播放';
    } else {
      return '已停止/未开始';
    }
  }


  build() {
    Column() {
      // 输入区域
      Row() {
        TextInput({ placeholder: '输入 AppKey (AK)' })
          .id('et_ak')
          .width('100%')
          .margin({ top: 8 })
          .layoutWeight(1)

        TextInput({ placeholder: '输入 AppSecret (SK)' })
          .id('et_sk')
          .width('100%')
          .margin({ top: 8 })
          .layoutWeight(1)

        TextInput({ placeholder: '输入摄像头 QRCode/ID' })
          .id('et_qrcode')
          .width('100%')
          .margin({ top: 8 })
          .layoutWeight(1)

        TextInput({ placeholder: '输入摄像头 MAC (XX-XX-XX..)' })
          .id('et_mac')
          .width('100%')
          .margin({ top: 8 })
          .layoutWeight(1)

        Button('返回')
          .id('btn_back')
          .margin({ top: 8 })
          .layoutWeight(1)
          .onClick(()=>{
            router.replaceUrl({
              url:"pages/Manager"
            })
          })
      }
      .margin({bottom:130})

      // 视频预览容器
      Column() {
        // 视频预览区域
        Video({
          src:this.videoUrl
        })
          .controls(false)//隐藏控制条
          .autoPlay(true)//自动播放
          .onPrepared(()=>console.log("视频准备就绪"))
          .onError(()=>console.error("适配播放出错"))
          .width("100%")
          .height(250)
          .backgroundColor("#000")
          .onPrepared(() => {
            console.log(PAGE_TAG, 'Video prepared. isPlaying should now be true.');
            // 当 Video 组件准备好时，可以认为视频流有效，标记为正在播放。
            // 即使是视频区域未准备好（黑屏）但流被获取，这里的事件也不一定会触发。
            // 如果 initPlayer 成功获取了 URL 并且 videoUrl 非空， autoplay 应该会在后台尝试播放。
            // 确认 videoUrl 是否已经有值是很重要的一步
            this.isPlaying = !!this.videoUrl; // 如果 videoUrl 非空，则设为 true
            this.errorMessage = null; // 准备好后清空错误信息
          })
      }
      .id('preview_container')
      .width('100%')
      .margin({ top: 10 });

      // 云台控制区域
      Column() {
        Button('↑')
          .id('btn_ptz_up')
          .margin({ bottom: 16 })

        Row() {
          Button('←')
            .id('btn_ptz_left')
            .margin({ right: 32 })

          Button('→')
            .id('btn_ptz_right')
        }
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 16 })

        Button('↓')
          .id('btn_ptz_down')
      }
      .id('ptz_container')
      .width('100%')
      .margin({ bottom: 16 ,top:50})

      // 状态显示
      Text(`状态: ${this.getCurrentStatus()}`)
        .id('tv_status')
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 30 })
    }
    .width('100%')
    .height('100%')
    .padding(16)
  }
}
