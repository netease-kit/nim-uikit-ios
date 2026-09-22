# Feature Manifest Template

每个新增需求使用一个稳定的 kebab-case slug，并建立 `references/features/<slug>.md`。清单至少包含：

1. **边界**：只允许开源仓库的 `NEChatUIKit/` 和 `app/`；`NEChatKit/`、旧 `IMUIKit/`、OC、SwiftUI 固定排除。
2. **整项删除**：完整文件、目录、图片、asset。
3. **局部编辑**：文件路径、要删的类型/属性/方法/调用锚点、必须保留的相邻行为。
4. **入口**：Demo 配置、路由、点击/长按菜单、公开 API、兼容桥。
5. **工程元数据**：仅当真实 Demo 源码或资源引用需要时记录 `app.xcodeproj/`；记录 podspec/resource glob 或依赖变化。
6. **交叉需求**：混合文件中应保留的非目标代码。
7. **闭源边界**：只记录 UI/Demo 对闭源 API 的调用点，不扫描或登记闭源实现文件。
8. **残留指纹**：唯一类型、配置 key、本地化 key、资源名、回调名。
9. **验证**：静态检查、目标构建、NormalUI/FunUI 行为检查。
10. **来源**：引入/修复 commit 仅用于追踪，不作为整体 revert 指令。

同时在 `references/feature-registry.json` 增加对应对象：

```json
{
  "aliases": ["用户可用别名"],
  "owned_paths": ["移除后必须不存在的路径"],
  "edit_paths": ["需要局部编辑且当前应存在的路径"],
  "residual": {
    "roots": ["定向检查根目录"],
    "patterns": ["唯一残留正则"],
    "allowed_paths": ["UI/Demo 中有明确兼容理由的允许残留文件"]
  }
}
```

不要把泛化词（如单独的 `unread`、`message`、`emoji`）作为残留指纹，否则会把其他功能误判为目标需求。
