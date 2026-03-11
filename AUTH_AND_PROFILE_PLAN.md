# 登录与个人中心 — 需求与实现计划

**Version:** 1.0  
**Last Updated:** 2026-03-12  
**Scope:** 登录流程、Profile、消息（Notifications）及登录后相关功能

---

## 1. 总览

| 模块 | 当前状态 | 说明 |
|------|----------|------|
| **登录入口** | ✅ 已实现 | 统一跳转「我的」tab，WebView 登录 |
| **登录流程** | ✅ 已实现 | 见 [WEBVIEW_LOGIN.md](WEBVIEW_LOGIN.md) |
| **登出** | ✅ 已实现 | 清 Keychain、清 WKWebView cookies、清 APIClient |
| **Just-in-time 登录** | ✅ 已实现 | requireAuthFor → requestLogin → postLoginIntent 回执 |
| **Profile（我的）** | ⚠️ 部分实现 | 头像/用户名展示、退出；我的帖子/收藏/历史为占位 |
| **消息（Notifications）** | ⚠️ 部分实现 | 未登录显示「登录后查看消息」+「去登录」按钮，点击切到「我的」；内容仍为 mock，无真实 API |
| **401 处理** | ✅ 已实现 | clearSession、needsReauthAlert 弹窗 |

---

## 2. 登录流程

### 2.1 登录入口与跳转

- 所有需要登录的操作统一通过 `AuthService.requestLogin(fromTab:)` 切到「我的」tab
- **登录入口仅在 Profile（我的）**：未登录时需登录的页面（如消息）会 `requestLogin` 切到「我的」tab，用户在 Profile 看到「使用网页登录」
- WebView 使用 `nonPersistent` 存储，每次打开为全新 cookie 环境

### 2.2 PendingAction 与 postLoginIntent

```swift
enum PendingAction: Equatable {
    case replyToThread(threadId: Int)
    case createThread(forumId: Int, subject: String)
    case votePost(postId: Int, tid: Int, pid: Int, upvote: Bool)
    case favorThread(tid: Int, folderId: String)
    case unfavorThread(tid: Int)
}
```

| 步骤 | 行为 |
|------|------|
| 1. 用户点「回复」未登录 | `requireAuthFor(.replyToThread(...))` 返回 false，保存 pendingAction，调用 `requestLogin` 切到「我的」 |
| 2. 用户完成 WebView 登录 | `completeLoginFromWebView` → `didCompleteLogin` → `postLoginIntent = flushPendingAction()`，切回 sourceTabForLogin |
| 3. ThreadDetailView 等 | `onChange(of: authService.postLoginIntent)` 匹配当前页面，执行回复/点赞，调用 `clearPostLoginIntent()` |

### 2.3 已接入 requireAuthFor 的入口

| 入口 | PendingAction | 所在 View |
|------|---------------|-----------|
| 回复 | replyToThread | ThreadDetailView |
| 点赞/踩 | votePost | ThreadDetailView |

### 2.4 离开「我的」且未登录时

- `MainTabView.onChange(selectedTab)`：若从「我的」切走且未登录，清空 `pendingAction`

---

## 3. Profile（我的）

### 3.1 已实现

| 功能 | 说明 |
|------|------|
| 未登录展示 | 登录提示 + 「使用网页登录」按钮 |
| 登录后展示 | currentUser 头像占位、displayName、username |
| 用户信息 | 来自 iflogin 或 Keychain 持久化的 User |
| 设置入口 | 跳转 SettingsView |
| 退出登录 | 调用 logout()，清 Keychain + WK cookies |

### 3.2 占位（待实现）

| 功能 | 当前状态 | 后续计划 |
|------|----------|----------|
| 我的帖子 | NavigationLink → 空页面 | 需 user posts API |
| 收藏 | NavigationLink → 空页面 | 需 favor/unfavor API |
| 历史记录 | NavigationLink → 空页面 | 需本地或服务端历史 |

### 3.3 头像

- 当前：占位圆形 + person.fill 图标
- 后续：`User.avatar` URL 使用 Kingfisher 等加载

---

## 4. 消息（Notifications）

### 4.1 已实现

| 功能 | 说明 |
|------|------|
| Auth 校验 | 未登录时显示「登录后查看消息」+「去登录」按钮，点击后 `requestLogin` 切到「我的」tab，登录入口仅在 Profile |

### 4.2 当前状态（登录后）

- 使用 mock 数据，无真实 API
- 三个 Tab：系统、回复、@我

### 4.3 待实现

| 项目 | 说明 |
|------|------|
| API 对接 | NGA 通知相关 endpoint（待查文档） |
| 未读数 | 与 tab bar 红点联动 |
| 已读/未读 | 点击后标记已读 |

---

## 5. Edge Cases 与异常处理

### 5.1 已处理

| 场景 | 处理方式 |
|------|----------|
| 401 未授权 | APIClient 发 `NotificationName.unauthorized` → AuthService.clearSession → needsReauthAlert 弹窗 |
| 登出后 WebView 残留 cookie | 使用 nonPersistent + clearWebViewCookies |
| 登录成功后 NGA alert | 检测 cookie 后直接 completionHandler，不展示 |

### 5.2 未覆盖或待加强

| 场景 | 当前行为 | 建议 |
|------|----------|------|
| 登录成功但 iflogin 失败 | 仍视为登录，用户信息可能不完整 | 可加重试或降级展示 |
| 切 tab 时登录 sheet 未关 | 可能残留 | 监听 tab 变化时 dismiss |
| 消息页未登录访问 | 已实现：显示提示 +「去登录」按钮 | — |
| createThread/favorThread 等 | PendingAction 已定义，UI 未接入 | 有对应 UI 时接入 requireAuthFor |

---

## 6. 后续功能计划

### 6.1 高优先级

| 功能 | 依赖 | 估计 |
|------|------|------|
| 消息页 API 对接 | NGA 通知 API | 中 |
| 我的帖子列表 | user posts / 个人主页 API | 中 |

### 6.2 中优先级

| 功能 | 说明 |
|------|------|
| 收藏列表 | favorForumSync / 收藏接口 |
| 历史记录 | 本地浏览历史或服务端 |
| 头像加载 | Kingfisher + User.avatar |
| createThread UI | 接入 requireAuthFor(.createThread) |

### 6.3 低优先级

| 功能 | 说明 |
|------|------|
| favorThread / unfavorThread | 帖子收藏，接入 requireAuthFor |
| 消息未读红点 | 需 API 支持 |
| 登出二次确认 | 避免误触 |

---

## 7. 相关文件

| 文件 | 职责 |
|------|------|
| `AuthService.swift` | 登录/登出、pendingAction、postLoginIntent、clearSession |
| `WebViewLoginView.swift` | WebView 登录 UI，见 WEBVIEW_LOGIN.md |
| `ProfileView.swift` | 我的 tab 入口、登录/登出入口 |
| `NotificationsView.swift` | 消息 tab；未登录显示登录提示 +「去登录」按钮，登录后 mock 列表 |
| `MainTabView.swift` | Tab 切换、pendingAction 清空、needsReauthAlert |
| `ThreadDetailView.swift` | 回复/点赞 requireAuth、postLoginIntent 消费 |
| `Endpoint.swift` | login、logout、iflogin |
| `Constants.swift` | TabIndex、Keychain keys |

---

## 8. 参考文档

- [WEBVIEW_LOGIN.md](WEBVIEW_LOGIN.md) — WebView 登录详细说明
- [DESIGN.md](DESIGN.md) §3 — Authentication Flow 总体设计
