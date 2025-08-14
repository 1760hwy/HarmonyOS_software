import { CryptoJS } from '@ohos/crypto-js';
import http from '@ohos.net.http';
import media from '@ohos.multimedia.media';

// 定义 API 响应类型
interface GeneratedTypeLiteralInterface_1 {
  url: string;
}

interface TPLinkApiResponse {
  error_code: number;
  result: GeneratedTypeLiteralInterface_1;
  msg?: string;
}

/**
 * TP-LINK 摄像头视频流获取和播放类
 */
export class TPLinkCamera {
  // 配置参数
  private readonly AK: string = "34b45db265eb4ecba44cda4497369"; // 替换为你的 Access Key
  private readonly SK: string = "47646a74e43b4f3eb492bbdd47e1e"; // 替换为你的 Secret Key
  private readonly TERMINAL_ID: string;
  private readonly API_HOST: string = "api-smbcloud.tp-link.com.cn";
  private readonly API_METHOD: string = "POST";
  private readonly API_PATH_STREAM: string = "/vms/open/httpFlvService/v1/getHttpFlvUrl";
  private readonly DEVICE_QRCODE: string = "8de52ca36338a3"; // 你的设备 QRCode
  private readonly DEVICE_MAC: string = "F4-84-8D-25-7C"; // 替换为你的设备 MAC 地址

  constructor() {
    // 生成唯一的终端ID（建议确认是否需要固定值）
    this.TERMINAL_ID = this.generateUUID();
  }

  /**
   * 生成 UUID
   */
  private generateUUID(): string {
    const randomBytes = new Uint8Array(16);
    for (let i = 0; i < 16; i++) {
      randomBytes[i] = Math.floor(Math.random() * 256);
    }
    return Array.from(randomBytes, (byte: number): string => byte.toString(16).padStart(2, '0')).join('');
  }

  /**
   * HMAC-SHA256 签名
   */
  // private signHmacSha256(keyBytes: string, msgStr: string): string {
  //   return CryptoJS.HmacSHA256(msgStr, keyBytes).toString(CryptoJS.enc.Hex);
  // }

  /**
   * SHA256 哈希
   */
  private hexDigestSha256(msgStr: string): string {
    return CryptoJS.SHA256(msgStr).toString(CryptoJS.enc.Hex);
  }

  /**
   * 获取视频流 URL
   */
  async getStreamUrl(qrCode?: string, mac?: string): Promise<string | null> {
    const deviceQrCode: string = qrCode || this.DEVICE_QRCODE;
    const deviceMac: string = mac || this.DEVICE_MAC;

    // 构造请求负载
    const payload: string = JSON.stringify({
      qrCode: deviceQrCode,
      mac: deviceMac,
      channelId: 1,
      type: "video",
      resolution: "HD",
      videoCode: "H264"
    });

    // 生成时间戳和随机数
    const timestamp: string = Math.floor(Date.now() / 1000).toString();
    const nonce: string = this.generateUUID();

    // 计算 payload 的 SHA256 哈希
    const hashedPayload: string = this.hexDigestSha256(payload);

    // 设置凭证范围
    const credentialScope = `${this.API_METHOD} ${this.API_PATH_STREAM} tp-link_request`;

    // 构造待签名字符串
    const stringToSign = `HmacSHA256\n${timestamp}\n${credentialScope}\n${hashedPayload}`;

    // 签名密钥派生
    const kDate = CryptoJS.HmacSHA256(timestamp, this.SK);
    const kService = CryptoJS.HmacSHA256(this.API_PATH_STREAM, kDate);
    const kSigning = CryptoJS.HmacSHA256("tp-link", kService);
    const signature = CryptoJS.HmacSHA256(stringToSign, kSigning).toString(CryptoJS.enc.Hex);

    // 构造授权头
    const authorizationHeaderValue = `Timestamp=${timestamp},Nonce=${nonce},AccessKey=${this.AK},Signature=${signature},TerminalId=${this.TERMINAL_ID}`;

    // 设置请求头
    const headers: Record<string, string> = {
      "X-Authorization": authorizationHeaderValue,
      "Content-Type": "application/json;charset=UTF-8",
      "Host": this.API_HOST
    };

    // 构造请求 URL
    const fullUrl: string = `https://${this.API_HOST}${this.API_PATH_STREAM}`;
    console.log(`请求 URL: ${fullUrl}`);
    console.log(`请求 Headers: ${JSON.stringify(headers, null, 2)}`);
    console.log(`请求 Payload: ${payload}`);
    console.log(`待签名字符串: ${stringToSign}`);
    console.log(`签名: ${signature}`);

    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(fullUrl, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: payload,
        expectDataType: http.HttpDataType.STRING,
        usingCache: false,
        priority: 1,
        connectTimeout: 10000,
        readTimeout: 10000
      });

      httpRequest.destroy();

      if (response.responseCode === 200) {
        const resultText = response.result as string;
        const result: TPLinkApiResponse = JSON.parse(resultText);
        console.log(`API 响应: ${JSON.stringify(result, null, 2)}`);

        if (result.error_code === 0) {
          return result.result.url;
        } else {
          console.error(`API 错误: ${result.msg || '未知错误'}`);
          return null;
        }
      } else {
        console.error(`HTTP 错误: ${response.responseCode}`);
        return null;
      }
    } catch (error) {
      console.error(`请求失败: ${JSON.stringify(error)}`);
      return null;
    }
  }

  /**
   * 创建媒体播放器
   */
  async createVideoPlayer(): Promise<media.AVPlayer | null> {
    try {
      const avPlayer: media.AVPlayer = await media.createAVPlayer();

      // 设置状态监听
      avPlayer.on('stateChange', async (state: string): Promise<void> => {
        console.log(`播放器状态变化: ${state}`);
        switch (state) {
          case 'idle':
            console.log('播放器处于空闲状态');
            break;
          case 'initialized':
            console.log('播放器初始化完成');
            break;
          case 'prepared':
            console.log('播放器准备完成，可以开始播放');
            await avPlayer.play();
            break;
          case 'playing':
            console.log('正在播放');
            break;
          case 'paused':
            console.log('播放暂停');
            break;
          case 'completed':
            console.log('播放完成');
            break;
          case 'stopped':
            console.log('播放停止');
            break;
          case 'error':
            console.error('播放器出现错误');
            break;
          default:
            console.log(`未知状态: ${state}`);
            break;
        }
      });

      // 设置错误监听
      avPlayer.on('error', (error: Error): void => {
        console.error(`播放器错误: ${JSON.stringify(error)}`);
      });

      return avPlayer;
    } catch (error) {
      console.error(`创建播放器失败: ${JSON.stringify(error)}`);
      return null;
    }
  }

  /**
   * 播放视频流
   */
  async playStream(url?: string, surfaceId?: string): Promise<boolean> {
    try {
      let streamUrl: string | null = url || null;
      if (!streamUrl) {
        streamUrl = await this.getStreamUrl();
      }

      if (!streamUrl) {
        console.error("无法获取有效的视频流 URL");
        return false;
      }

      console.log(`正在播放视频流: ${streamUrl}`);

      const avPlayer: media.AVPlayer | null = await this.createVideoPlayer();
      if (!avPlayer) {
        console.error("无法创建媒体播放器");
        return false;
      }

      if (surfaceId) {
        avPlayer.surfaceId = surfaceId;
      }

      avPlayer.url = streamUrl;
      await avPlayer.prepare();
      return true;
    } catch (error) {
      console.error(`播放视频流失败: ${JSON.stringify(error)}`);
      return false;
    }
  }

  /**
   * 停止播放
   */
  async stopPlay(avPlayer: media.AVPlayer): Promise<void> {
    try {
      await avPlayer.stop();
      await avPlayer.release();
      console.log("视频播放已停止");
    } catch (error) {
      console.error(`停止播放失败: ${JSON.stringify(error)}`);
    }
  }
}