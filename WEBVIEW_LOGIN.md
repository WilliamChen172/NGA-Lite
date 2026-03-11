# WebView 登录 — 需求与实现说明

**Version:** 1.0  
**Last Updated:** 2026-03-12  
**Status:** 已实现，待适配 NGA 改版与异常场景

---

## 1. 背景与动机

| 项目 | 说明 |
|------|------|
| **为何用 WebView** | NGA 网页登录支持图形验证码；客户端 `__act=login` 接口需图形验证码时无法直接调用，故使用 WebView 加载官方登录页。 |
| **参考实现** | MNGA 项目 `app/Shared/Views/LoginView.swift` |
| **入口** | ProfileView 未登录时「使用网页登录」按钮，打开 `WebViewLoginView` 的 sheet |

---

## 2. 流程概述

1. 加载 `nuke.php?__lib=login&__act=account&login`（NGA 登录入口）
2. 注入 JS：在 iframe `#iff` 内点击「密码登录」，隐藏二维码/第三方登录
3. 展示 WebView（点击完成后再显示，避免首页闪一下）
4. 用户输入账号密码、完成验证码，提交
5. 成功：NGA 弹出 alert，同时设置 cookie `ngaPassportUid`、`ngaPassportCid`
6. 检测到 cookie 后：`AuthService.completeLoginFromWebView`，关闭 sheet

---

## 3. 实现要点

### 3.1 使用 nonPersistent 存储

```swift
config.websiteDataStore = .nonPersistent()
```

- 每次打开 WebView 登录为**全新 cookie 环境**
- 不与 Safari / default store 共享，logout 后不会残留 cookie
- 关闭 sheet 后该存储被丢弃，下次打开必为空白

### 3.2 自动点击「密码登录」

- NGA 入口页有二维码、密码登录等选项
- 通过 XPath `//*[@id="main"]/div/div[3]/a[2]` 在 iframe 内模拟点击「密码登录」
- 隐藏元素：`//*[@id="main"]/div/a[2]`（二维码）、`//*[@id="main"]/div/div[last()]`（第三方登录）

### 3.3 登录成功检测

| 方式 | 触发时机 |
|------|----------|
| **JS alert 拦截** | 成功时 NGA 调用 `alert()`；在 `runJavaScriptAlertPanel` 中检查 cookie，若有 uid/cid 则完成登录并直接调用 `completionHandler`，不展示 alert |
| **Cookie 轮询** | 每 1 秒检查 cookie，最多 5 分钟，作为兜底 |

### 3.4 登出时清除 WebView 相关状态

- 使用 nonPersistent 后，WebView 本身不再共享 default store
- `AuthService` 中仍保留 `clearWebViewCookies()`，用于清除 default store 中的 `ngaPassportUid`、`ngaPassportCid`，防止其他路径遗留
- `logout()` 与 `clearSession()` 都会调用 `clearWebViewCookies()`

### 3.5 日志

- 使用 `Logger.for(.auth)`，前缀 `[webview]`
- 记录：导航开始/结束 URL、clickPasswordAndHide 重试、cookie 轮询、login success via alert/cookies

---

## 4. 未覆盖的 Edge Case

| 场景 | 当前行为 | 建议 |
|------|----------|------|
| **NGA 页面 DOM 改版** | XPath 失效，无法自动点击「密码登录」 | 每半年或发现异常时检查 NGA 页面，更新 XPath |
| **登录失败 alert** | 展示为 UIAlertController，用户手动关闭 | 可考虑识别常见错误文案，给予更友好提示 |
| **iframe 加载极慢** | 脚本最多重试 30 次（约 15 秒）后仍展示 | 可增加「重试加载」按钮 |
| **网络中断后重试** | 无专门重试 UI | 用户需手动关闭 sheet 再打开 |
| **多标签/多窗口** | 不考虑 | — |
| **登录成功但 iflogin 失败** | 已保存 uid/cid，但用户信息可能不完整 | 当前仍视为登录成功，可后续补拉信息 |

---

## 5. 后续适配与扩展

### 5.1 NGA 改版适配

- 若 XPath 失效，需重新抓取页面结构，更新 `clickPasswordAndHideScript` 中的 XPath
- 文件：`NGA/Views/Auth/WebViewLoginView.swift`，搜索 `byXpath`

### 5.2 可能增强

| 功能 | 说明 |
|------|------|
| 记住上次登录方式 | 若将来恢复 API 表单登录，可提供「网页登录 / API 登录」选项 |
| 登录页 URL 配置 | 若 NGA 更换域名或路径，可抽到配置 |
| 隐私模式 / 无痕 | 已通过 nonPersistent 实现每次新环境，无需额外逻辑 |

### 5.3 与 API 登录的关系

- **API 登录**：`AuthService.login(username:password:)`，直接调 `__act=login`，适用于无图形验证码场景
- **WebView 登录**：走 `completeLoginFromWebView(uid:cid:)`，cookie 检测 → Keychain + APIClient
- 两者都最终写入 Keychain 和 APIClient 的 token/uid，后续流程一致

---

## 6. 相关文件

| 文件 | 职责 |
|------|------|
| `NGA/Views/Auth/WebViewLoginView.swift` | WebView 登录 UI、JS 注入、cookie 检测、alert 拦截 |
| `NGA/Services/AuthService.swift` | `completeLoginFromWebView`、`clearWebViewCookies`、logout/clearSession |
| `NGA/Utils/Constants.swift` | `nukeURL`、`baseURL` |
| `NGA/Views/Profile/ProfileView.swift` | 登录入口 UI |

---

## 7. 参考

- [AUTH_AND_PROFILE_PLAN.md](AUTH_AND_PROFILE_PLAN.md) — 登录后 Profile、消息、pendingAction 等完整计划
- MNGA: `app/Shared/Views/LoginView.swift`, `app/Shared/Utilities/URLs.swift`
- NGA 登录页：`https://ngabbs.com/nuke.php?__lib=login&__act=account&login`（或 nga.178.com）
