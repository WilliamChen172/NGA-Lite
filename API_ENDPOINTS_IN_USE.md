# 当前使用的 API 接口清单

---

## 一、baseURL 配置

| 变量 | 当前值 |
|------|--------|
| `Constants.API.baseURL` | `https://ngabbs.com` |
| `Constants.API.appAPIURL` | `{baseURL}/app_api.php` |
| `Constants.API.nukeURL` | `{baseURL}/nuke.php` |

---

## 二、app_api.php 接口

### 2.1 主题列表（双路径）

**已登录**：`app_api subject/list`

| 项 | 值 |
|----|-----|
| **URL** | app_api.php?__lib=subject&__act=list&__output=14 |
| **方法** | POST |
| **Body** | fid, page, order_by, app_id=1100（认证通过 Cookie） |

**未登录**：`thread.php`（MNGA 风格，lite=js 返回 JSON）

| 项 | 值 |
|----|-----|
| **URL** | {baseURL}/thread.php |
| **方法** | POST |
| **Body** | fid, page, __inchst=UTF8, lite=js, order_by, recommend |

### 2.2 帖子详情（双路径）

**已登录**：`app_api post/list`

| 项 | 值 |
|----|-----|
| **URL** | app_api.php?__lib=post&__act=list&__output=14 |
| **方法** | POST |
| **Body** | tid, page, app_id=1100（认证通过 Cookie） |

**未登录**：`read.php`（MNGA 风格，lite=js 返回 JSON）

| 项 | 值 |
|----|-----|
| **URL** | {baseURL}/read.php |
| **方法** | POST |
| **Body** | tid, page, __inchst=UTF8, lite=js, v2=1 |

### 2.3 home/category — 论坛分类（共用，登录/未登录均可）

| 项 | 值 |
|----|-----|
| **URL** | app_api.php?__lib=home&__act=category&_v=2&__output=14 |
| **方法** | GET |
| **调用处** | ForumService.getForums, getForumCategories |

### 2.4 subject/hot — 首页热帖

| 项 | 值 |
|----|-----|
| **URL** | app_api.php?__lib=subject&__act=hot&__output=14 |
| **方法** | GET |
| **调用处** | APIClient.fetchHotThreads |

### 2.5 post/new — 发主题

| 项 | 值 |
|----|-----|
| **URL** | app_api.php?__lib=post&__act=new&__output=14 |
| **方法** | POST |
| **Body** | fid, subject, content |
| **调用处** | ForumService.createThread |

### 2.6 post/reply — 回复帖子

| 项 | 值 |
|----|-----|
| **URL** | app_api.php?__lib=post&__act=reply&__output=14 |
| **方法** | POST |
| **Body** | tid, content, repid（可选） |
| **调用处** | ForumService.reply |

---

## 三、nuke.php 接口

| 接口 | __lib | __act | 用途 |
|------|-------|-------|------|
| topic_recommend add | topic_recommend | add | 点赞/点踩 |
| login/login | login | login | 登录（WebView: name/password；Native: AES 加密） |
| forum_favor2/get | forum_favor2 | get | 我的收藏 |
| app_inter/recmd_topic | app_inter | recmd_topic | 首页推荐 |
| login/account | login | account | 登出 (logout=1) |
| login/iflogin | login | iflogin | 检查登录 |

---

## 四、静态资源 base

| 用途 | 当前值 |
|------|--------|
| 图片附件 | `https://img.nga.178.com/attachments/` |
| 头像 | `https://img.nga.178.com/avatars/` |
| 帖子内相对链接补齐 | `https://ngabbs.com` |

---

## 五、帖子内容解析（PostContentParser）

帖子 `content` 为 BBCode + HTML 混合格式，由 `PostContentParser` 统一解析为 `PostContentSegment`：

| 支持格式 | 说明 |
|----------|------|
| `[b]...[/b]` | 加粗 |
| `[url=...]...[/url]` | 链接 |
| `[img]...[/img]` | 图片（补齐 img.nga.178.com/attachments/） |
| `[quote]...[/quote]` | 引用块 |
| `<b>...</b>` 等 | 简单 HTML 转为 BBCode |
| `[s:a2:xxx]` | NGA 表情（自闭合，替换为空） |
