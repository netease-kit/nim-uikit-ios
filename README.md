# 网易云信 UI 组件 	· iOS

## 简介

云信 UI 组件，全称 `Netease Instant Message Kit`，简称 `NIMKit`，是一款开源的聊天组件，并支持二次开发。开发者只需要稍作配置就可以打造出属于自己的聊天界面，而通过一些自定义的设置，也可以轻松添加业务相关的功能，如阅后即焚，红包，点赞等功能。NIMKit 底层依赖 `NIMSDK`，是一款由网易开发的 IM SDK，通过它可以轻松快速在你的 App 中集成 IM 功能。

## 源起

在一个开发首次做 IM App 时，聊天界面的 ViewController 几乎会变成项目开发中的泥潭，随着项目推进和需求迭代，聊天界面 ViewController 往往会变成 Massive View Controller，所有聊天界面相关的代码都堆积在一起，整个 ViewController 的代码轻松就上千行，无法很好的解耦。造成这个的原因往往有

* 消息种类繁多，没有做很好的归类与统一，代码可拓展性低
* 聊天界面 UI 元素，事件，回调众多，没有合理解耦

而在日常的 iOS 开发中，大牛们为我们总结出各种方法来进行各个模块的解耦，大方向上有 MVCS, MVP, MVVM, VIPER 等，而落实到细节上，又有使用组合，抽取数据源等等小技巧。但对于一些经验不足的 iOS 开发而言，做出一个优雅的聊天界面 ViewController 仍旧是一件难于上青天的事。在开发云信的前期，我们虽然也意识到这方面的困难，在提供云信 SDK 的同时也开源了相应的 Demo 源码，意在提供一个比较优雅的实现参考，但对于接入的开发者而言，成本仍然过大。这也是这个组件库的由来和目的：开发者在不写任何一行代码的情况下也能够轻松实现一个聊天界面。


## 集成说明

### Cocoapods 集成

我们建议你通过 [Cocoapods](https://cocoapods.org/) 来进行 `NIMKit` 的集成,在 `Podfile` 中加入以下内容:

```shell
pod 'NIMKit'
```

需要注意的是 `NIMKit` 依赖于 `NIMSDK`，但是我们并没有在对应的 `podspec` 文件类添加 `NIMSDK` 为 `NIMKit` 的 dependency，原因是完整的 `NIMSDK` 不仅有 IM 模块，也有音视频模块。对于很多产品而言，只需要接入单纯的 IM 模块，所以我们推荐使用 [NIMSDK_Lite](https://github.com/netease-im/NIM_iOS_SDK_Lite) 以减少对不必要模块的依赖，进而减少 App 体积。基于这个考虑，用于需要自行添加 `NIMSDK` 的依赖，即

```shell
pod 'NIMSDK'
```

或者添加

```shell
pod 'NIMSDK_Lite'
```

### 手动集成

当然你也可以通过手动导入 `NIMKit`。步骤如下

* 添加 `NIMKit` 下所有源文件到你的工程中

* 添加 `NIMKitResource.bundle` 到你的工程中

* 添加必要的依赖项
	* CoreText.framework
	
* 如果你选择手动添加 NIMSDK，还需要添加如下依赖项
	* CoreTelephony.framework
	* AVFoundation.framework
	* MobileCoreServices.framework
	* SystemConfiguration.framework
	* AudioToolbox.framework
	* CoreMedia.framework
	* libc++.tbd  <sup> 注<sup>1</sup> </sup>
	* libsqlite3.0.tbd  
	* libz.tbd 

* 设置 `Other Linker Flags` 为 `-ObjC`

* 在需要使用到组件的地方导入头文件 `NIMKit.h` 

## 快速使用

`NIMKit` 提供两个最重要的类

* NIMSessionViewController
* NIMSessionListViewController

前者用于会话界面的显示和互动，而后者提供了最近会话功能。在集成 `NIMSDK` 且完成了基础设置后，直接调用这两个类就可以得到完善的聊天界面和会话列表。

### 聊天界面

初始化聊天界面时，上层需要传入当前聊天界面对应的会话信息，即 `NIMSession`

```objc
NIMSession *session = [NIMSession session:uid type:NIMSessionTypeP2P];
NIMSessionViewController *vc = [[NIMSessionViewController alloc] initWithSession:session];
[self.navigationController pushViewController:vc animated:YES];
```

### 会话列表

初始化会话列表不需要任何前置条件，直接初始化即可。

```objc
NIMSessionListViewController *vc = [[NIMSessionViewController alloc] init];
```

## 集成效果

（此处贴图 by 小王~~~）

## 定制化

在不做任何修改，直接套用 `NIMKit` 组件，就能够达到上述效果。但不同的产品往往会有不同的定制化需求，定制化需求参考

1.《项目结构介绍》

2.《界面排版自定义》

3.《用户信息自定义》

4.《新消息类型集成》

