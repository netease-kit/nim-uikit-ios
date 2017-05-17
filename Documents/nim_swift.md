# Swift 集成
### 前言

正如我们的 [README](../README.MD) 所描述：由于使用 Swift 开发的第三方库不支持编译为静态库，`NIMKit` 和这些库同时使用 [Cocoapods](https://cocoapods.org/) 的时候，需要使用 `use_framework!` 关键字，由于 `NIMKit` 有静态库依赖，Cocoapods 在这种情况下无法直接安装。

### 解决方案

在 NIMKit 1.4.1 版本之前，我们推荐完全手动集成,具体可以参考这个[文档](./nim_mi.md)。

在 NIMKit 1.4.1 版本以及之后，我们推荐手动导入 NIMKit 组件源码，通过 Cocoapods 安装第三方库的方案。较完全手动集成，可以解决寻找第三方库，匹配版本，设置编译链接参数等枯燥繁琐的问题。

具体步骤如下：

### 导入代码

将 `NIMKit/NIMKit` 下的所有源代码导入你的工程


### 导入资源文件

将 `NIMKit/Resources/` 下的资源文件导入你的工程，包括

* `NIMKitResource.bundle`  
* `NIMKitEmoticon.bundle`  
* `NIMKitSettings.bundle`  

### 在 Podfile 中添加依赖

```shell
   ...

   pod 'NIMSDK'
   pod 'SDWebImage', '~> 3.8.2'
   pod 'Toast', '~> 3.0'
   pod 'SVProgressHUD', '~> 2.0.3'
   pod 'M80AttributedLabel', '~> 1.6.3'
   pod 'TZImagePickerController', '~> 1.7.7'

   ...
```

其中 `···` 为开发者原有依赖，`NIMSDK` 为包含实时音视频库的完整版本，如果不需要实时音视频，可替换为 `pod 'NIMSDK_LITE'` 。


为防止文档更新不够及时，推荐在导入第三方库时参考当前的 [podspec](https://github.com/netease-im/NIM_iOS_UIKit/blob/master/NIMKit.podspec) 内指定的版本号。



