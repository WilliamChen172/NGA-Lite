# 回复解析与 UI 实施计划

基于 `REPLY_UI_AND_PARSING_DESIGN.md` 整理的可执行步骤。

---

## Phase 1：解析统一

| # | 步骤 | 文件 | 说明 |
|---|------|------|------|
| 1.1 | 实现 `extractAndReplaceReplyHeaders` | `PostContentParser.swift` | 识别 B1/B2 两种引用头，提取 pid/uid/author/date，替换为占位或结构化输出 |
| 1.2 | 扩展 `PostContentSegment` 或引入 `ReplyHeader` | `PostContentParser.swift` | 新增 `.quote(ReplyHeader?, body)` 或等价结构，ReplyHeader 含 pid, uid, author, date |
| 1.3 | 确保 `[pid]`、`[uid]` 不裸显 | `PostContentParser.swift` | parseTag 中 pid/uid 转为可读文本或可点击 link，不输出原始标签 |
| 1.4 | B1 引用补全：当前页查找 | `PostContentView` 或解析层 | 解析时若为 B1，从传入的 posts 字典按 pid 查找 content，补全被引用内容 |
| 1.5 | B1 引用补全：按 pid 请求 | `APIClient.swift` | 新增 `fetchPostByPid(pid:)`，调用 read.php，Body 传 `pid`、`__inchst`、`lite`、`v2` |
| 1.6 | 接入 B1 补全逻辑 | ViewModel / PostContentView | 当 B1 且当前页无 pid 时，调用 fetchPostByPid，解析 content 作为引用体 |

---

## Phase 2：UI 增强

| # | 步骤 | 文件 | 说明 |
|---|------|------|------|
| 2.1 | Post 模型增加 `fromClient` | `Post.swift` | 新增 `fromClient: String?`，CodingKeys 加 `from_client` |
| 2.2 | postFromDict 解析 from_client | `APIClient.swift` | 在 `postFromDict` 中从 dict 取 `from_client` 传入 Post |
| 2.3 | 设备图标显示 | `PostDetailView.swift` | 时间旁根据 `fromClient` 显示：`apple.logo`（含 iOS）、`square.grid.2x2`（含 Android）、默认 `iphone` |
| 2.4 | 引用头独立一行、可点击 | `PostContentView.swift` | quote 块内引用头单独渲染，tap 时回调或滚动到对应楼层（需 tid + pid） |
| 2.5 | 引用块样式 | `PostContentView.swift` | 按 5.4：浅灰背景、左边框、smallBody、secondary 色 |
| 2.6 | 楼层号、时间元数据强化 | `PostDetailView.swift` | 视需要调整字号、间距、层级 |

---

## Phase 3：扩展（可选）

| # | 步骤 | 文件 | 说明 |
|---|------|------|------|
| 3.1 | 楼中楼 UI | 新增 / 调整 | 若有 comment 数据，设计缩进、折叠等 |
| 3.2 | NGA 表情渲染 | `PostContentParser` | `[s:xx:yy]` 转为图片（需 CDN 规则） |
| 3.3 | 长引用折叠 | `PostContentView` | 引用内容过长时折叠/展开 |

---

## 依赖关系

```
1.1 ─┬─► 1.2 ─► 1.3 ─► 1.4 ─┬─► 1.5 ─► 1.6
     │                        │
     └── 2.1 ◄── 2.2 ─► 2.3 ─┴─► 2.4 ─► 2.5 ─► 2.6
```

- 1.4 需要 View 层能拿到 posts（用于按 pid 查找）
- 1.5、1.6 可并行于 1.4，但 1.6 依赖 1.5
- 2.1、2.2、2.3 可独立于 Phase 1 先做（设备图标）

---

## 建议执行顺序

**快速见效**（先跑通基本显示）：
1. 2.1 → 2.2 → 2.3（设备图标）
2. 1.1 → 1.2 → 1.3（引用头解析与 pid/uid 不裸显）

**完整 B1 补全**：
3. 1.5（fetchPostByPid）
4. 1.4、1.6（补全逻辑接入）

**引用块体验**：
5. 2.4 → 2.5 → 2.6
