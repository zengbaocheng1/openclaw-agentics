# Peekaboo - 截图 + 视觉问答

## 功能
- CLI + MCP server 截图
- 可选视觉问答（本地或远程AI模型）
- 4439 ⭐

## 核心文件
- `Core/Screenshot.swift` - 截图核心
- `Commander/` - CLI 命令
- `AXorcist/` - Swift Accessibility 包装
- `docs/` - 文档

## 安装
```bash
brew install openclaw/tap/peekaboo
```

## 使用
```bash
peekaboo snap --output screenshot.png
peekaboo snap --vqa "描述图片内容"
```
