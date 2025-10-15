# Release 发布指南

## 自动发布流程

本项目配置了自动化的 Release 发布流程，可以为所有 6 个平台（Android、iOS、Linux、macOS、Web、Windows）构建并发布应用。

## 发布方式

### 方式 1：通过 Git Tag 触发（推荐）

1. 创建并推送一个版本标签：

```bash
# 创建标签
git tag v1.0.0

# 推送标签到 GitHub
git push origin v1.0.0
```

2. GitHub Actions 会自动：
   - 并行构建所有 6 个平台的 3 个应用
   - 等待所有构建完成
   - 创建 GitHub Release
   - 上传所有构建产物到 Release

### 方式 2：手动触发

1. 访问 GitHub Actions 页面
2. 选择 "Create Release" workflow
3. 点击 "Run workflow"
4. 输入版本标签（如 `v1.0.0`）
5. 点击 "Run workflow" 按钮

## 构建产物

每次 Release 会包含以下文件：

### alouette_app
- `alouette_app-android.apk` - Android 应用
- `alouette_app-ios.ipa` - iOS 应用
- `alouette_app-linux-x64.tar.gz` - Linux 应用
- `alouette_app-macos.dmg` - macOS 应用
- `alouette_app-web.zip` - Web 应用
- `alouette_app-windows-x64.zip` - Windows 应用

### alouette_app_trans（翻译应用）
- `alouette_app_trans-android.apk`
- `alouette_app_trans-ios.ipa`
- `alouette_app_trans-linux-x64.tar.gz`
- `alouette_app_trans-macos.dmg`
- `alouette_app_trans-web.zip`
- `alouette_app_trans-windows-x64.zip`

### alouette_app_tts（语音合成应用）
- `alouette_app_tts-android.apk`
- `alouette_app_tts-ios.ipa`
- `alouette_app_tts-linux-x64.tar.gz`
- `alouette_app_tts-macos.dmg`
- `alouette_app_tts-web.zip`
- `alouette_app_tts-windows-x64.zip`

## 版本号规范

建议使用语义化版本号（Semantic Versioning）：

- `v1.0.0` - 主版本.次版本.修订号
- `v1.0.0-beta.1` - 预发布版本
- `v1.0.0-rc.1` - 候选发布版本

## 注意事项

1. **构建时间**：完整构建所有平台可能需要 30-60 分钟
2. **iOS 构建**：需要配置签名证书和 Provisioning Profile
3. **失败处理**：如果任何一个平台构建失败，Release 不会创建
4. **权限要求**：需要仓库的 `contents: write` 权限

## 查看 Release

发布完成后，访问：
https://github.com/feuyeux/alouette/releases

## 删除 Release

如果需要删除某个 Release：

```bash
# 删除远程标签
git push --delete origin v1.0.0

# 删除本地标签
git tag -d v1.0.0
```

然后在 GitHub Releases 页面手动删除对应的 Release。

## 故障排查

### 构建失败
- 检查各个平台的构建日志
- 确保所有依赖都已正确配置
- 验证代码在本地可以成功构建

### Release 未创建
- 确认所有 6 个平台的构建都成功完成
- 检查 GitHub Actions 日志中的错误信息
- 验证仓库权限设置

### 产物缺失
- 检查各个构建 workflow 的 artifact 上传步骤
- 确认文件路径和命名正确
- 查看 artifact 下载日志
