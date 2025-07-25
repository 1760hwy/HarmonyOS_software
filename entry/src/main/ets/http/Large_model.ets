// src/main/ets/utils/ChatBotAPI.ts

import hilog from '@ohos.hilog'; // 导入日志模块
import http from '@ohos.net.http'; // 导入 HTTP 网络请求模块

// 日志标签
const HI_LOG_DOMAIN = 0x0001; // 自定义日志域 (可以根据实际模块规划)
const HI_LOG_TAG = 'ChatBotAPI'; // 日志标签

// *** 关键修复：使用日志级别的数值常量，避免直接访问hilog.Level或hilog属性 ***
const LOG_LEVEL_INFO = 3;
const LOG_LEVEL_DEBUG = 2; // 通常 Debug 比 Info 低
const LOG_LEVEL_ERROR = 5;
// 可以根据需要添加其他级别: const LOG_LEVEL_WARN = 4; etc.


// Moonshot AI API 配置
// !!! 警告: 生产环境中应安全存储 API 密钥，切勿硬编码 !!!
const API_KEY = "sk-L2omJCkUz1zaJ0O7gXZoP5ZXq2c45FpNJj56DHnqpyR364UJ"; // AI开发者密钥
const API_URL = "https://api.moonshot.cn/v1/chat/completions";       // API请求URL
const MODEL_NAME = "moonshot-v1-128k";                             // 使用的AI模型名称

// --- API 请求体 (RequestBody) 结构定义 ---
// 这是根据 Moonshot API 文档为 POST 请求体定义的数据结构
interface ChatMessage {
  role: "user" | "system" | "assistant"; // 消息角色
  content: string;                       // 消息内容
}

interface ChatRequestPayload {
  model: string;            // 使用的模型名称
  messages: ChatMessage[];  // 聊天消息历史数组 (这里通常只包含用户当前消息)
  // 根据需要还可以添加其他可选参数，比如 temperature, stream 等
  // temperature?: number;
  // stream?: boolean; // 如果你想实现流式传输
}


// --- API 响应体 (ResponseBody) 结构定义 (根据实际返回调整，简化以匹配提取逻辑) ---
// 用于接收 API 的响应
interface Choice {
  message: ChatMessage; // 回答的消息
  index: number;
  logprobs: null; // 或者定义具体类型
  finish_reason: string;
}

interface Usage {
  prompt_tokens: number;
  completion_tokens: number;
  total_tokens: number;
}

interface ApiChatResponse {
  id: string;
  object: string;
  created: number;
  model: string;
  choices: Choice[]; // 回答选项数组
  usage: Usage;
  system_fingerprint: string | null; // 或者定义具体类型
}


/**
 * ChatBotAPI
 * 封装调用 AI（如 Moonshot）API 的功能。
 * 使用 @ohos.net.http 模块和 async/await 异步获取回答。
 * 返回 Promise，解析成功时包含回答字符串，失败时为 null。
 */
export class ChatBotAPI {

  /**
   * 异步调用 AI API 获取文本回答。
   * 使用 async/await 返回 Promise，模拟 Weather_forecast 的风格。
   *
   * @param question 用户的提问字符串。
   * @returns {Promise<string | null>} 一个 Promise，
   * 如果成功则解析为 AI 的回答字符串，如果发生错误则解析为 null。
   */
  async queryAPI(question: string): Promise<string | null> {
    let httpRequest: http.HttpRequest | null = null; // 声明 HttpRequest 实例，用于 finally 释放
    try {
      // 使用 hilog 进行日志输出 (仅在支持 hilog 的设备上打印，或者根据 isLoggable 判断)
      // 修复：isLoggable 使用数值常量
      hilog.isLoggable(HI_LOG_DOMAIN, HI_LOG_TAG, LOG_LEVEL_INFO)
        && hilog.info(HI_LOG_DOMAIN, HI_LOG_TAG, `开始请求 AI，问题: %{public}s`, question);
      // 作为备用，也可以使用 console
      // console.info(HI_LOG_TAG, `开始请求 AI，问题: ${question}`);


      // 创建 HttpRequest 实例
      httpRequest = http.createHttp(); // 创建 HTTP 请求实例

      // 请求体结构，匹配 AI API 要求，并声明明确类型
      const requestBody: ChatRequestPayload = {
        model: MODEL_NAME, // 使用指定的模型
        messages: [ // 聊天消息历史数组
          { role: "user", content: question } // 当前的用户提问，遵循 ChatMessage 接口
        ]
        // 如果有其他参数，可以在这里添加
      };

      // 记录请求体日志 (注意安全，不要在生产环境详细记录敏感信息)
      // 修复：isLoggable 使用数值常量
      hilog.isLoggable(HI_LOG_DOMAIN, HI_LOG_TAG, LOG_LEVEL_DEBUG) // 使用 Debug 级别记录详细请求体
        && hilog.debug(HI_LOG_DOMAIN, HI_LOG_TAG, `构建请求体: %{public}s`, JSON.stringify(requestBody));


      // 发起 POST 请求，并使用 await 等待响应
      // 注意：省略了 callback 参数，httpRequest.request 在这种情况下返回 Promise
      const response = await httpRequest.request(API_URL, {
        method: http.RequestMethod.POST, // 请求方法为 POST
        // extraData 对象的键值对会自动序列化为 JSON 字符串，因为 Content-Type 是 application/json
        extraData: requestBody, // 传递带有明确类型的 requestBody
        header: {
          'Content-Type': 'application/json', // 设置内容类型，告诉服务器请求体是 JSON
          'Authorization': `Bearer ${API_KEY}` // 设置授权头部，包含 API 密钥
        },
        connectTimeout: 60000, // 连接超时时间（毫秒）
        readTimeout: 60000     // 读取超时时间（毫秒）
      });

      // 检查 HTTP 响应状态码
      // 修复：isLoggable 使用数值常量
      hilog.isLoggable(HI_LOG_DOMAIN, HI_LOG_TAG, LOG_LEVEL_INFO)
        && hilog.info(HI_LOG_DOMAIN, HI_LOG_TAG, `HTTP 响应状态码: %{public}d`, response.responseCode);

      if (response.responseCode !== 200) {
        const errorMsg = `HTTP 错误码: ${response.responseCode}`;
        // 修复：isLoggable 使用数值常量
        hilog.isLoggable(HI_LOG_DOMAIN, HI_LOG_TAG, LOG_LEVEL_ERROR)
          && hilog.error(HI_LOG_DOMAIN, HI_LOG_TAG, errorMsg + ` 响应体: %{public}s`, response.result);
        // 如果响应体包含错误信息，可以尝试解析并返回更详细的错误
        return null; // 请求失败，返回 null
      }

      // 获取并校验响应体类型
      const bodyText = response.result;
      if (typeof bodyText !== 'string') {
        // 修复：isLoggable 使用数值常量
        hilog.isLoggable(HI_LOG_DOMAIN, HI_LOG_TAG, LOG_LEVEL_ERROR)
          && hilog.error(HI_LOG_DOMAIN, HI_LOG_TAG, `响应体不是字符串类型`);
        return null; // 响应体格式错误
      }

      // 解析 JSON 数据
      let jsonResponse: ApiChatResponse; // 使用响应接口类型
      try {
        jsonResponse = JSON.parse(bodyText); // 解析 JSON 字符串到对象
        // 修复：isLoggable 使用数值常量
        hilog.isLoggable(HI_LOG_DOMAIN, HI_LOG_TAG, LOG_LEVEL_INFO)
          && hilog.info(HI_LOG_DOMAIN, HI_LOG_TAG, `JSON 解析成功`);
      } catch (parseErr) {
        const errorMsg = `JSON 解析失败: ${(parseErr as Error).message}`;
        // 修复：isLoggable 使用数值常量
        hilog.isLoggable(HI_LOG_DOMAIN, HI_LOG_TAG, LOG_LEVEL_ERROR)
          && hilog.error(HI_LOG_DOMAIN, HI_LOG_TAG, errorMsg);
        return null; // JSON 解析失败，返回 null
      }

      // 检查并安全提取回答内容
      // 使用可选链 ?. 确保不会因为某个属性缺失而抛出错误
      const answer = jsonResponse?.choices?.[0]?.message?.content;

      // 校验提取到的回答是否为字符串
      if (typeof answer === 'string') {
        // 修复：isLoggable 使用数值常量
        hilog.isLoggable(HI_LOG_DOMAIN, HI_LOG_TAG, LOG_LEVEL_INFO)
          && hilog.info(HI_LOG_DOMAIN, HI_LOG_TAG, `AI 回答提取成功`);
        return answer; // 成功获取到回答，返回字符串
      } else {
        // 数据结构不符合预期或回答内容不是字符串
        const errorMsg = 'AI 响应格式不符合预期或内容不是字符串';
        // 修复：isLoggable 使用数值常量
        hilog.isLoggable(HI_LOG_DOMAIN, HI_LOG_TAG, LOG_LEVEL_ERROR)
          && hilog.error(HI_LOG_DOMAIN, HI_LOG_TAG, errorMsg + `: %{public}s`, JSON.stringify(jsonResponse));
        return null; // 数据结构错误，返回 null
      }

    } catch (e) {
      // 捕获在 try 块中可能发生的任何其他异常（如网络连接问题、await 中的错误等）
      if (e instanceof Error) {
        // 修复：isLoggable 使用数值常量
        hilog.isLoggable(HI_LOG_DOMAIN, HI_LOG_TAG, LOG_LEVEL_ERROR)
          && hilog.error(HI_LOG_DOMAIN, HI_LOG_TAG, `请求 AI 异常: %{public}s`, e.message);
      } else {
        // 修复：isLoggable 使用数值常量
        hilog.isLoggable(HI_LOG_DOMAIN, HI_LOG_TAG, LOG_LEVEL_ERROR)
          && hilog.error(HI_LOG_DOMAIN, HI_LOG_TAG, `未知异常: %{public}s`, String(e));
      }
      return null; // 发生异常，返回 null
    } finally {
      // 在 finally 块中确保销毁 HttpRequest 实例，释放资源
      if (httpRequest) {
        httpRequest.destroy(); // 销毁请求实例
        // 修复：isLoggable 使用数值常量
        hilog.isLoggable(HI_LOG_DOMAIN, HI_LOG_TAG, LOG_LEVEL_INFO)
          && hilog.info(HI_LOG_DOMAIN, HI_LOG_TAG, `HttpRequest 实例已销毁`);
      }
    }
  }

  // 如果你觉得总是写 new ChatBotAPI().queryAPI(...) 麻烦，
  // 并且queryAPI本来就是无状态的（不依赖实例成员），
  // 你也可以考虑将queryAPI方法设为static并在类的外部导出一个便捷调用：
  /*
  static async queryAPI(question: string): Promise<string | null> {
   // ... implementation remains the same ...
  }
  // 然后在使用的地方直接 import { ChatBotAPI } from './ChatBotAPI'; 并调用 ChatBotAPI.queryAPI(...)
  */
}

// 导出单例或类本身供外部引用
// 模仿 Weather 的导出风格，导出一个类的实例
export const AIChatBot: ChatBotAPI = new ChatBotAPI();