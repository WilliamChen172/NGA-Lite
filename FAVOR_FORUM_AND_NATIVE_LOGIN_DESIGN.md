# 收藏版块 + Native 登录 设计文档

## 背景

基于官方 App 抓包（proxy 拦截）得到的真实接口规格。

---

## 〇、通用规则（所有 nuke / app_api 接口）

| 项 | 规格 |
|----|------|
| 方法 | **POST**（统一改为 POST） |
| Content-Type | `application/x-www-form-urlencoded` |
| Host | `ngabbs.com`（统一） |

即：nuke.php 和 app_api.php 全部走 POST + form-urlencoded，baseURL 统一为 `https://ngabbs.com`。

---

## 一、forum_favor2 收藏版块接口

### 1.1 规格

- **URL**：`https://ngabbs.com/nuke.php?__lib=forum_favor2&__act=get`
- **方法**：POST
- **Content-Type**：`application/x-www-form-urlencoded`
- **Body 参数**：`__output`, `access_token`, `access_uid`, `app_id`, `sign`, `t`
  - `t`：当前 UNIX 时间戳（timeIntervalSince1970）
  - `sign`：计算方式待补充

### 1.2 改动点

| 位置 | 改动 |
|------|------|
| `Endpoint.swift` | 新增 forumFavorGet：`__lib=forum_favor2`, `__act=get` |
| `APIClient` | 统一 POST、Content-Type、baseURL |
| `ForumService` | 调用 forum_favor2，失败则回退 favorforum/sync |

---

## 二、Native 登录（nuke.php）

### 2.1 规格（官方 App 抓包）

- **URL**：`https://ngabbs.com/nuke.php`
- **方法**：POST
- **Content-Type**：`application/x-www-form-urlencoded`
- **Body 参数**（trackid 不传，__ngaClientChecksum 先不传）：

| 参数 | 值 | 说明 |
|------|-----|------|
| `__lib` | login | |
| `__act` | login | |
| `__output` | **14** | JSON 格式 |
| `app_id` | 1100 | |
| `device` | iOS:5a8d121f3176bb01f62ad0ca8388e8f7a414547a7cc406d4ff1a8a202d76b671 | 64 位 hex，设备唯一 hash，持久化存储 |
| `name` | 40448473 | 登录名（uid/邮箱/手机） |
| `type` | id | 登录名类型：id / mail / phone |
| `password` | UrxkAq9WHNVvHlvUHekk...（Base64） | 明文 → **AES-128 加密** → **Base64 编码** 传输 |
| `__inchst` | UTF-8 | |

- **password**：明文 → AES-128-ECB 加密 → Base64 编码。Key = wolfcon AppSecret 后 16 位 = `41dcf30175a7a80b`
- **trackid**：不传（投放广告用）
- **__ngaClientChecksum**：先不传

### 2.2 依赖

- **AES-128-ECB**：CryptoSwift 或 CommonCrypto，Key = `41dcf30175a7a80b`（32 位 hex = 16 字节）
- **device**：格式 `iOS:{64位hex}`，可用 identifierForVendor 或 UUID 做 seed，SHA256 得 64 位 hex，存 Keychain

### 2.3 改动点

| 位置 | 改动 |
|------|------|
| `Constants` | nativeLoginAppId=1100，nativeLoginAESKeyHex=41dcf30175a7a80b |
| `AESHelper` | AES-128-ECB 加密，返回 Base64 |
| `DeviceIdHelper` | 生成并持久化 `iOS:{64位hex}` |
| `KeychainService` | saveDeviceId / getDeviceId |
| `APIClient` | requestNativeLogin(name:type:password:) |
| `AuthService` | loginNative(name:password:) |
| `NativeLoginView` | 新建：输入 name、password，推断 type，调用 loginNative |
| `ProfileView` | 增加「客户端登录」入口 |

---

## 三、实现顺序建议

1. **Phase 1：Native 登录**（优先）
   - AESHelper、DeviceIdHelper、KeychainService
   - APIClient.requestNativeLogin
   - AuthService.loginNative
   - NativeLoginView、ProfileView

2. **Phase 2：通用规则**
   - 所有 nuke/app_api 接口改为 POST + form-urlencoded
   - Host 统一为 ngabbs.com

3. **Phase 3：forum_favor2**
   - 确认 sign/t 计算方式后补齐

---

## 四、待确认

1. **forum_favor2**：`sign` 的计算方式。
2. **__ngaClientChecksum**：后续如需传入，计算公式待定。

---

## 五、参考

- 官方 App 抓包（proxy 拦截）
- [wolfcon/NGA-API-Documents](https://github.com/wolfcon/NGA-API-Documents)
