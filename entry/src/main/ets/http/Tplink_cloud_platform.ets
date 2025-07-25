import { CryptoJS } from '@ohos/crypto-js';
import http from '@ohos.net.http';

export interface tplink_yun {
  ak: string;
  sk: string;
  device_id: string;
  mac: string;
}

interface ApiResponse {
  error_code: number;
  msg?: string;
  result?: ApiResult;
}

interface ApiResult {
  url: string;
}

const API_HOST: string = "api-smbcloud.tp-link.com.cn";
const API_METHOD: string = "POST";
const API_PATH_STREAM: string = "/vms/open/httpFlvService/v1/getHttpFlvUrl";

// 生成 UUID
function generateUUID(): string {
  const chars = '0123456789abcdef';
  let uuid = '';
  for (let i = 0; i < 32; i++) {
    uuid += chars.charAt(Math.floor(Math.random() * 16));
    if (i === 7 || i === 11 || i === 15 || i === 19) {
      uuid += '-';
    }
  }
  return uuid;
}

// SHA-256 哈希函数
function hexDigestSha256(msg: string): string {
  return CryptoJS.SHA256(msg).toString();
}

// HMAC-SHA256 签名函数
function signHmacSha256(key: string, msg: string): string {
  return CryptoJS.HmacSHA256(msg, key).toString(CryptoJS.enc.Hex);
}

// 获取视频流 URL
interface GeneratedObjectLiteralInterface_1 {
  "X-Authorization": string;
  "Content-Type": string;
  "Host": string;
}

export async function getStreamUrl(config: tplink_yun): Promise<string | null> {
  const payload = JSON.stringify({
    qrCode: config.device_id,
    mac: config.mac,
    channelId: 1,
    type: "video",
    resolution: "HD",
    videoCode: "H264"
  });

  const algorithm = "HmacSHA256";
  const timestamp = Math.floor(Date.now() / 1000).toString();
  const nonce = generateUUID();
  const terminalId = generateUUID(); // 替换为全局 TERMINAL_ID 或每次生成

  const hashedPayload = hexDigestSha256(payload);
  const credentialScope = `${API_METHOD} ${API_PATH_STREAM} tp-link_request`;
  const stringToSign = `${algorithm}\n${timestamp}\n${credentialScope}\n${hashedPayload}`;

  const kSecret = config.sk;
  const kDate = signHmacSha256(kSecret, timestamp);
  const kService = signHmacSha256(kDate, API_PATH_STREAM);
  const kSigning = signHmacSha256(kService, "tp-link");
  const signature = signHmacSha256(kSigning, stringToSign);

  const authorizationHeaderValue = (
    `Timestamp=${timestamp},` +
      `Nonce=${nonce},` +
      `AccessKey=${config.ak},` +
      `Signature=${signature},` +
      `TerminalId=${terminalId}`
  );

  const headers: GeneratedObjectLiteralInterface_1 = {
    "X-Authorization": authorizationHeaderValue,
    "Content-Type": "application/json;charset=UTF-8",
    "Host": API_HOST
  };

  const fullUrl = `https://${API_HOST}${API_PATH_STREAM}`;
  console.info(`请求 URL: ${fullUrl}`);
  console.info(`请求 Headers: ${JSON.stringify(headers, null, 2)}`);
  console.info(`请求 Payload: ${payload}`);

  const httpRequest = http.createHttp();
  try {
    const response = await httpRequest.request(fullUrl, {
      method: http.RequestMethod.POST,
      header: headers,
      extraData: payload,
      connectTimeout: 10000,
      readTimeout: 10000
    });

    const result: ApiResponse = JSON.parse(response.result as string);
    console.info(`API 响应: ${JSON.stringify(result, null, 2)}`);
    if (result.error_code === 0 && result.result && result.result.url) {
      return result.result.url;
    } else {
      console.error(`API 错误: ${result.msg || '未知错误'}`);
      return null;
    }
  } catch (error) {
    console.error(`请求失败: ${error}`);
    return null;
  }
}