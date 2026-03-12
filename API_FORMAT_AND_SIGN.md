# API 格式统一 + Sign / t 说明

**Version:** 1.0  
**Last Updated:** 2026-03-13

---

## 一、WebView 登录能拿到什么

### 1.1 当前实现

WebView 登录成功后，从 cookie 提取：

| Cookie 名 | 对应含义 | 存储 / 用途 |
|-----------|----------|-------------|
| `ngaPassportUid` | 用户 UID | `access_uid`，Keychain `nga_uid` |
| `ngaPassportCid` | 会话 token | `access_token`，Keychain `nga_auth_token` |

### 1.2 t 值

**t 为本地时间戳，每次发起请求时现场生成。**

- 每次调用需要 sign 的接口时，用 `Int(Date().timeIntervalSince1970)` 生成当前 Unix 时间戳作为 `t`
- 用该 `t` 计算 sign，并随请求一起发送
- 不从 API 响应取 `time`，不持久化 `t`

```swift
let t = Int(Date().timeIntervalSince1970)
let sign = md5("\(t)\(appSecret)\(access_token)\(access_uid)\(app_id)").lowercased()
```

---

## 二、Sign 计算方式

### 2.1 公式（wolfcon README）

拼接字符串：**时间戳 + AppSecret + email + encryptedPassword + app_id**，取 MD5（小写）。

```
sign = md5(t + AppSecret + email + encryptedPassword + app_id).lowercased()
```

### 2.2 适配 forum_favor2（WebView 登录后）

登录后接口无 email/password，用 `access_token`、`access_uid` 替代，公式为：

```
sign = md5(t + AppSecret + access_token + access_uid + app_id).lowercased()
```

| 参数 | 来源 |
|------|------|
| t | **本次请求时本地生成的 Unix 时间戳**（`Int(Date().timeIntervalSince1970)`） |
| AppSecret | 待确认：可能与 native 登录 AES key 同源（`41dcf30175a7a80b` 或完整 32 位） |
| access_token | ngaPassportCid（cid） |
| access_uid | ngaPassportUid（uid） |
| app_id | 1100（与 forum_favor2 设计一致） |

### 2.3 其他

- **wolfcon 13.2 客户端认证**（`__ngaClientChecksum`）：`md5(uid + 认证码 + 时间戳) + 时间戳`，用于发帖等，与 forum_favor2 sign 不同。

---

## 三、API 格式统一（设计文档要求）

### 3.1 通用规则

| 项 | 规格 |
|----|------|
| 方法 | **POST**（统一） |
| Content-Type | `application/x-www-form-urlencoded` |
| Host | `ngabbs.com` |

nuke.php 与 app_api.php 均使用 POST + form-urlencoded。

### 3.2 当前实现与待改点

| 接口 | 当前 | 设计文档要求 |
|------|------|--------------|
| thread.php | POST ✓ | 保持 POST |
| read.php | POST ✓ | 保持 POST |
| app_api.php | 需核对 | 全部 POST + form-urlencoded |
| nuke.php | 需核对 | 全部 POST + form-urlencoded |

### 3.3 需要 sign/t 的接口

- **forum_favor2**（nuke.php）：需要 `sign`、`t`，公式见 §2.2
- **favorforum/sync**（app_api.php）：可能沿用相同规则，待验证

---

## 四、总结

| 问题 | 结论 |
|------|------|
| t 从哪里来？ | **每次发起请求时本地生成**：`Int(Date().timeIntervalSince1970)` |
| WebView 登录能拿到什么？ | 只有 `uid` 和 `cid`，对应 `access_uid`、`access_token` |
| sign 如何计算？ | **`md5(t + AppSecret + access_token + access_uid + app_id).lowercased()`** |

---

## 五、参考

- [FAVOR_FORUM_AND_NATIVE_LOGIN_DESIGN.md](FAVOR_FORUM_AND_NATIVE_LOGIN_DESIGN.md)
- [WEBVIEW_LOGIN.md](WEBVIEW_LOGIN.md)
- [wolfcon 数据格式](https://github.com/wolfcon/NGA-API-Documents/wiki/数据格式) — 标准格式含 `"time": 当前时间`
- [wolfcon 客户端相关](https://github.com/wolfcon/NGA-API-Documents/wiki/客户端相关) — 13.2 客户端认证
- [wolfcon README](https://github.com/wolfcon/NGA-API-Documents) — app_api 接口列表、clientSign 示例
