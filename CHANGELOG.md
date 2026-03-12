# Changelog

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
