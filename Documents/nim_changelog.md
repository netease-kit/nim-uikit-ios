# iOS UI 组件更新日志
## [2.8.0] - 2018-05-17
* 组件的云信 SDK 依赖升级为 5.1.0
### 修正
* 上层开发自定义字体大小导致的消息气泡显示异常问题

## [2.6.0] - 2018-02-11
* 组件的云信 SDK 依赖升级为 4.9.0

## [2.5.0] - 2018-02-08
### 新增
* 组件新增下拉加载更多支持
  
  数据源 `NIMSessionMsgDatasource` 新增上拉数据接口
  
  ```objc
  - (void)loadPullUpMessagesWithComplete:(void(^)(NSInteger index, NSArray *messages, NSError *error))handler;
  ```
  
### 修正
* 修复会话组件在某些情况下无法修改标题和子标题的问题


### 变更
* 组件的云信 SDK 依赖升级为 4.8.0

## [2.4.0] - 2018-01-12
### 变更
* 组件的云信 SDK 依赖升级为 4.7.0

## [2.3.0] - 2018-01-04
### 修正
* iPhoneX 适配。
* 点击和长按头像回调改为 NIMMessage


## [2.2.1] - 2017-11-29
### 变更
* 修复在某些工程环境下报 NIMKitSetting 符号重复的问题

## [2.2.0] - 2017-11-23
### 变更
* 组件的云信 SDK 依赖升级为 4.5.0


## [2.1.1] - 2017-11-21
### 修正

* 修复会话页下拉控件无效的问题

## [2.1.0] - 2017-11-16
### 新增
* 适配 iOS11
* 聊天气泡 cell 获取接口，在继承自 NIMSessionViewController 的子类中重写方法即可
  
```objc
@protocol NIMMessageCellDelegate <NSObject>
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
@end
```  
* NIMKit 类增加 UI 配置器属性 `@property (nonatomic,strong) NIMKitConfig *config;`

### 变更

* 组件的云信 SDK 依赖升级为 4.4.0
* 移除 NIMKitBubleSetting.plist 和 NIMKitSetting.plist
* 气泡配置和全局配置从 plist 配置转为对象属性设置，设置的具体接口整理在 NIMKitConfig 中。
  你可以通过以下示例来对组件个性化配置。具体支持的功能请参考[界面排版自定义](https://github.com/netease-im/NIM_iOS_UIKit/blob/master/Documents/nim_custom_ui.md)
  
```objc
/*设置圆角头像*/
 [NIMKit sharedKit].config.avatarType = NIMKitAvatarTypeRadiusCorner 
```




### 修正

* 键盘弹起时可能覆盖气泡的问题
* 键盘和气泡弹起不同步的问题



  


