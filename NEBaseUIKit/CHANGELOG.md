# NEBaseUIKit Changelog

## 10.9.60(2026-09-21)
### Behavior changes
* 隔离 NormalUI 与 FunUI 的资源和文案，完善双皮肤独立构建能力。
* 统一多行输入、个性签名和用户搜索展示的基础 UI 行为。

## 10.9.51(2026-08-21)
### Behavior changes
* 新增独立的 NEBaseUIKit 通用 UI 模块，保留原兼容模块不变。
* NOS、NOS_Special、FCS、FCS_Special 分别依赖对应的 NEChatKit 渠道。
* 隔离 Toast 的 Objective-C 运行时符号，支持新旧通用 UI 模块共存。

## 10.9.50(2026-08-21)
### Behavior changes
* IMUIKit 通用 UI 模块重命名为 NEBaseUIKit
* NOS、NOS_Special、FCS、FCS_Special 分别依赖对应的 NEChatKit 渠道

## 9.8.2(2025-10-17)
### New Features
* tabbar 适配 iOS26
### Behavior changes
* NENavigationController 标题宽度布局优化

## 9.8.1(2025-9-5)
### New Features
* 新增 UI 配置类 CommonUIConfig，用于配置 Common UI
* 新增支持自动识别手机号、网页链接和邮箱的 NELinkableLabel
* 新增点击手机号和邮箱的通用底部弹窗
* 新增 NEWKWebViewController，用于显示链接
* 新增 NENavigationController
### Behavior changes
* CopyableLabel 继承自 NELinkableLabel
* 组件开源

## 9.7.9(2025-6-30)
### New Features
* UIView 新增扩展属性 isVisibleInWindow，用于检查视图是否在屏幕可见范围内

## 9.7.8(2025-6-13)
### New Features
* 导航栏底部分割线高度支持自定义
### Behavior changes
* 资源文件去重

## 9.7.4(2024-12-06)
### Behavior changes
* stringFromTimeInterval、stringFromDate 等扩展移至 NEBaseUIKit

## 9.7.0(2024-01-25)
### Behavior changes
* UITextField 类新增扩展方法 removeAllAutoLayout，用于移除所有约束

## 9.6.5(2023-12-8)
### Behavior changes
* PagingKit 开源库改造并集成于CommonUIKit

## 9.6.0(2023-06-14)
### New Features
* 新增 NECustomActionSheetController 类和 NECustomAlertAction 类，用于自定义 alertSheet 弹窗

### Behavior changes
* showToast 方法添加缺省参数 position: ToastPosition，用于设定弹窗展示位置

## 9.5.0(2023-04-20)
### New Features
* NEEmptyDataView 新增setEmptyImage(image:）方法，支持自定义背景图

## 9.4.0(2023-03-08)
### New Features
* 图片预览保存相册支持GIF
### Behavior changes
* 图片浏览器保存相册添加权限申请
* 相机、照片、定位服务无权限提示，由 toast 弹窗改为 alert 弹窗
