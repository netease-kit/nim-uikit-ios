# 网易云信 UI 组件 	· iOS
[![Build Status](https://img.shields.io/travis/netease-im/NIM_iOS_UIKit/master.svg?style=flat)](https://travis-ci.org/netease-im/NIM_iOS_UIKit)
[![Pod Version](https://img.shields.io/cocoapods/v/NIMKit.svg?style=flat)](#)
[![Pod Platform](http://img.shields.io/cocoapods/p/NIMKit.svg?style=flat)](#)
[![Minimum Requirement](http://img.shields.io/badge/Requirement-iOS%208.0%2B-green.svg?style=flat)](#)
[![LICENSE](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](./LICENSE)

## 简介

云信 UI 组件，全称 `Netease Instant Message Kit`，简称 `NIMKit`，是一款开源的聊天组件，并支持二次开发。开发者只需要稍作配置就可以打造出属于自己的聊天界面，而通过一些自定义的设置，也可以轻松添加业务相关的功能，如阅后即焚，红包，点赞等功能。NIMKit 底层依赖 `NIMSDK`，是一款由网易开发的 IM SDK，通过它可以轻松快速在你的 App 中集成 IM 功能。

## 源起

在一个开发首次做 IM App 时，聊天界面的 ViewController 几乎会变成项目开发中的泥潭，随着项目推进和需求迭代，聊天界面 ViewController 往往会变成 Massive View Controller，所有聊天界面相关的代码都堆积在一起，整个 ViewController 的代码轻松就上千行，无法很好的解耦。

造成聊天界面代码臃肿的原因往往有:

* 消息种类繁多，没有做很好的归类与统一，代码可拓展性低
* 聊天界面 UI 元素，事件，回调众多，没有合理解耦

而在日常的 iOS 开发中，大牛们为我们总结出各种方法来进行各个模块的解耦，大方向上有 

* MVCS 
* MVP 
* MVVM 
* VIPER 

落实到细节上，又有使用组合，抽取数据源等等小技巧。但对于一些经验不足的 iOS 开发而言，做出一个优雅的聊天界面 ViewController 仍旧是一件难于上青天的事。

在开发云信的前期，我们虽然也意识到这方面的困难，在提供云信 SDK 的同时也开源了相应的 Demo 源码，意在提供一个比较优雅的实现参考，但对于接入的开发者而言，成本仍然过大。这也是这个组件库的由来和目的：开发者在不写任何一行代码的情况下也能够轻松实现一个聊天界面。


## 集成环境
* 编译版本 : iOS SDK 10.0 及以上。
* 操作系统 : iOS 8.0 及以上。

## 集成说明

### Cocoapods 集成

我们建议你通过 [Cocoapods](https://cocoapods.org/) 来进行 `NIMKit` 的集成,在 `Podfile` 中加入以下内容:

```shell
pod 'NIMKit'
```

需要注意的是默认 `NIMKit` 依赖于 [轻量版本](https://github.com/netease-im/NIM_iOS_SDK_Lite) 的 `NIMSDK`，而 [完整版本](https://github.com/netease-im/NIM_iOS_SDK) 的 `NIMSDK` 不仅有 IM 模块，也有音视频模块。对于很多产品而言，只需要接入单纯的 IM 模块，这样可以减少对不必要模块的依赖，进而减少 App 体积。所以我们有两个版本的组件可供选择，安装完组件之后，则不必再安装 `NIMSDK` 依赖。

* 轻量版本

  ```shell
  pod 'NIMKit'
  ```

    或

  ```shell
  pod 'NIMKit/Lite'
  ```

* 完整版本

  ```shell
  pod 'NIMKit/Full'
  ```

### Swift 集成

由于使用 Swift 开发的第三方库不支持编译为静态库，`NIMKit` 和这些库同时使用 [Cocoapods](https://cocoapods.org/) 的时候会出现一些问题，具体解决方案可以参考这个[文档](./Documents/nim_swift.md)。


### 手动集成

我们`强烈`不推荐你使用手动导入的方式来集成 `NIMKit`，但如果你一定要这么做，可以参考这个[文档](./Documents/nim_mi.md)。



## 快速使用

`NIMKit` 提供两个最重要的类

* `NIMSessionViewController`
* `NIMSessionListViewController`

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
NIMSessionListViewController *vc = [[NIMSessionListViewController alloc] init];
```

## 集成效果


| 最近会话进入会话                                 | 群组会话                                     | 发送多张图片                                   |
| ---------------------------------------- | ---------------------------------------- | ---------------------------------------- |
| ![image](https://github.com/netease-im/NIM_Resources/blob/master/iOS/Images/nimkit_1.gif) | ![image](https://github.com/netease-im/NIM_Resources/blob/master/iOS/Images/nimkit_2.gif) | ![image](https://github.com/netease-im/NIM_Resources/blob/master/iOS/Images/nimkit_3.gif) |

| 发送语音                                     | 发送地理位置                                   | 发送中与发送失败，点击叹号可重发                         |
| ---------------------------------------- | ---------------------------------------- | ---------------------------------------- |
| ![image](https://github.com/netease-im/NIM_Resources/blob/master/iOS/Images/nimkit_4.gif) | ![image](https://github.com/netease-im/NIM_Resources/blob/master/iOS/Images/nimkit_5.gif) | ![image](https://github.com/netease-im/NIM_Resources/blob/master/iOS/Images/nimkit_6.gif) |

| 自定义消息-阅后即焚示例                             | 最近联系人选择器                                 | 最近会话删除与未读删除                              |
| ---------------------------------------- | ---------------------------------------- | ---------------------------------------- |
| ![image](https://github.com/netease-im/NIM_Resources/blob/master/iOS/Images/nimkit_7.gif) | ![image](https://github.com/netease-im/NIM_Resources/blob/master/iOS/Images/nimkit_8.gif) | ![image](https://github.com/netease-im/NIM_Resources/blob/master/iOS/Images/nimkit_9.gif) |


## 定制化

在不做任何修改，直接套用 `NIMKit` 组件，就能够达到上述效果。但不同的产品往往会有不同的定制化需求，定制化需求参考

1.[《项目结构介绍》](./Documents/nim_arch.md)

2.[《界面排版自定义》](./Documents/nim_custom_ui.md)

3.[《新消息类型集成》](./Documents/nim_custom_message.md)

4.[《用户信息自定义》](./Documents/nim_userinfo.md)

5.[《机器人消息排版指南》](./Documents/nim_robot.md)


## 更新日志

你可以在 [这里](./Documents/nim_changelog.md) 查看组件 2.1.0 版本之后的所有更新信息

