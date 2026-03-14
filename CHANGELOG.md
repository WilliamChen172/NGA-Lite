# Changelog

## 2026-03-14

### 帖子内容解析与展示

- **PostContentParser**：BBCode + HTML 解析器
  - 支持 [b]、[url]、[img]、[quote] 等 BBCode
  - 简单 HTML（`<b>`/`<i>`/`<u>`）转为 BBCode
  - 自闭合 NGA 表情 `[s:a2:xxx]` 替换为空
  - `extractImageUrls`：从 content 提取图片 URL
- **PostContentView**：富文本渲染组件，quote 引用块样式优化
- **Reply 框**：修复引用内容中 HTML 标签和表情未解析问题

### 主题列表与详情

- **ForumThread**：新增 `firstImageUrl`、`imageCount` 用于列表预览
- **ThreadRowView**：标题下方显示首图预览 + 多图角标
- **PostDetailView**：移除「关注」按钮

---

## 2026-03-13

### 首页推荐 / 热帖

- **app_inter/recmd_topic**：首页推荐改用 `nuke.php` 新接口，替代旧 `home/recmthreads`
- **HomeRecmTopic**：新增推荐帖子模型（tid, subject, thread_icon, forumName 等）
- **HomeRecmTopicCardView**：推荐卡片重设计
  - 图片在上、标题在下，独立白色背景
  - 图片 2:1 宽高比，fill 裁剪不拉伸
  - 标题区固定两行高度，不随内容变动
  - 版块标签左上角、评论数右下角
- **首页 Tab**：关注 | 推荐 | 热帖

### 论坛 / 收藏

- **forum_favor2**：我的收藏改用 `forum_favor2/get` 接口
- **ForumCard**：横向布局（图标左+名字右），2 列网格

### Native 登录

- **NativeLoginView**：客户端登录（账号+密码，AES 加密）
- **AuthService**：loginNative、iflogin JSON 响应

### 其他

- 移除 banner 轮播、recmthreads 回退
- 布局常量统一至 AppTheme
