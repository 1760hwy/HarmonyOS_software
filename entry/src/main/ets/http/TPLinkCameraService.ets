import { TPLinkCamera } from "../http/TpCloud";
import media from '@ohos.multimedia.media';

/**
 * TP-LINK 摄像头服务类
 */
export class TPLinkCameraService {
  private camera: TPLinkCamera;
  private currentPlayer: media.AVPlayer | null = null;

  constructor() {
    this.camera = new TPLinkCamera();
  }

  /**
   * 启动摄像头流播放
   */
  async startCameraStream(surfaceId: string): Promise<boolean> {
    try {
      const success = await this.camera.playStream(undefined, surfaceId);
      if (success) {
        this.currentPlayer = await this.camera.createVideoPlayer(); // 跟踪 AVPlayer 实例
        console.log("AVPlayer 已创建并绑定到 surfaceId:", surfaceId);
      }
      return success;
    } catch (error) {
      console.error(`启动摄像头流失败: ${JSON.stringify(error)}`);
      return false;
    }
  }

  /**
   * 停止摄像头流播放
   */
  async stopCameraStream(): Promise<void> {
    if (this.currentPlayer) {
      try {
        await this.camera.stopPlay(this.currentPlayer);
        this.currentPlayer = null;
        console.log("摄像头流已停止");
      } catch (error) {
        console.error(`停止摄像头流失败: ${JSON.stringify(error)}`);
      }
    } else {
      console.warn("未找到有效的 AVPlayer 实例");
    }
  }

  /**
   * 获取流 URL（仅获取，不播放）
   */
  async getStreamUrl(): Promise<string | null> {
    try {
      const url = await this.camera.getStreamUrl();
      console.log("获取流 URL:", url);
      return url;
    } catch (error) {
      console.error(`获取流 URL 失败: ${JSON.stringify(error)}`);
      return null;
    }
  }
}

/**
 * 导出默认实例，方便直接使用
 */
export default new TPLinkCameraService();