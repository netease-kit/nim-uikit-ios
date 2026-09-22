
# NELocalConversationUIKit

> IMUIKit 本地会话列表UI模块，提供通快速集成本地会话列表UI能力。

## Change Log

[change log](CHANGELOG.md)

## 本地引用

### 其他Kit引用
如果是其他Kit引用NELocalConversationUIKit，就在对应Kit的podspec文件中添加依赖。

```
s.dependency 'NELocalConversationUIKit'
```

由于podspec中无法通过路径来依赖本地的pod库，所以，需要在对应 Demo 的 Podfile 中添加对NELocalConversationUIKit的依赖。

```
pod 'NELocalConversationUIKit', :path => '../NELocalConversationUIKit/NELocalConversationUIKit.podspec'
```
### 界面工程直接引用
如果是example直接依赖NELocalConversationUIKit，则直接在对应 Demo 的 Podfile 中添加对NELocalConversationUIKit的依赖。

```
// 本地引用示例，path路径根据实际相对路径填写
pod 'NELocalConversationUIKit', :path => '../NELocalConversationUIKit/NELocalConversationUIKit.podspec'
```

## Pod引用
```
pod 'NELocalConversationUIKit', '10.6.0'
```
## 开发、打包与发布

在 `IMUIKitSwift` 根目录安装对应 Demo 的依赖：

```bash
pod install --project-directory=IMUIKitExample
```

先执行组件级发布检查，再构建并校验 XCFramework：

```bash
python3 xkit_im_push.py --product im -k NELocalConversationUIKit --dry-run
python3 xkit_im_push.py --product im -k NELocalConversationUIKit --prepare
```

实际发布统一使用根目录 `xkit_im_push.py`，版本来自 `../PodConfigs/config_podspec.rb`。完整开发、IPA 打包和发布流程见 [IMUIKitSwift README](../README.md)。
