// 1. 导入模块
import bundleManager from '@ohos.bundle.bundleManager';

// 2. 获取签名信息标志位
let flag = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_SIGNATURE_INFO;

// 3. 获取当前应用的Bundle信息（同步方法）
let bundleInfo = bundleManager.getBundleInfoForSelfSync(flag);

// 4. 提取AppID
let appId = bundleInfo.signatureInfo?.appId; // 注意空值检查

