#!/bin/bash

# 脚本用于设置GitHub仓库

echo "=== 配置alouette-app仓库 ==="
cd /Users/han/coding/alouette/alouette-app
git add .
git commit -m "Initial commit: alouette-app setup"
git branch -M main
git remote add origin git@github.com:feuyeux/alouette-app.git
# git push -u origin main

echo "=== 配置主alouette仓库 ==="
cd /Users/han/coding/alouette

# 移除现有的子项目目录（稍后作为submodule添加）
rm -rf alouette-translator alouette-tts

# 添加主仓库文件
git add README.md .gitignore .gitmodules
git commit -m "Initial commit: main alouette repository setup"
git branch -M main
git remote add origin git@github.com:feuyeux/alouette.git

# 添加子模块
git submodule add git@github.com:feuyeux/alouette-app.git alouette-app
git submodule add git@github.com:feuyeux/alouette-translator.git alouette-translator
git submodule add git@github.com:feuyeux/alouette-tts.git alouette-tts

# 提交子模块配置
git add .
git commit -m "Add submodules: alouette-app, alouette-translator, alouette-tts"

echo "=== 配置完成 ==="
echo "请在GitHub上创建仓库后，取消注释并运行推送命令"
echo "1. git push -u origin main  # 在alouette-app目录"
echo "2. git push -u origin main  # 在主alouette目录"
