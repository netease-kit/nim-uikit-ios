# 自定义消息示例

##自定义消息概述
自定义消息用于 APP 拓展自己的消息类型，实现不同业务逻辑。自定义消息的 MessageObject(NIMCustomObject) 仅有一个 id 字段，SDK 会负责透传这个对象序列化后的结果。NIMCustomAttachment 协议包括一个必须实现的序列化接口和三个与上传相关的可选接口，如果需要在自定义消息中上传文件作为附件的一部分，必须实现这三个上传接口，缺一不可。


##收发自定义消息

1.新建消息附件,实现 `NIMCustomAttachment` 协议。

  * 构建自定义消息附件内容

    ```objc
    @interface Attachment : NSObject<NIMCustomAttachment>
        
    //简单新建一个有标题和副标题的自定义消息
    
    @property (nonatomic,copy) NSString *title;
    
    @property (nonatomic,copy) NSString *subTitle;
    
    @end
   ```

    ```objc
    @implementation Attachment
    
    - (NSString *)encodeAttachment{
        NSDictionary *dict = @{@"title":self.title,@"subTitle":self.subTitle};
        NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
        NSString *encodeString = @"";
        if (data) {
            encodeString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
        return encodeString;
    }
    
    //其他协议如上传下载托管可根据自己的业务需求选择实现
    
    
    #pragma mark - Getter
    - (NSString *)title{
        if (!_title) {
            _title = @"";
        }
        return _title;
    }
    
    - (NSString *)subTitle{
        if (!_subTitle) {
            _subTitle = @"";
        }
        return _subTitle;
    }
    
    @end
    ```

2.新建自定义消息解码器，并在程序开始时注入。

* 解码器，实现 `NIMCustomAttachmentCoding` 协议

    ```objc
    @interface AttachmentDecoder : NSObject<NIMCustomAttachmentCoding>
    @end
    
    ```
    
    ```objc
    @implementation AttachmentDecoder
    
    - (id<NIMCustomAttachment>)decodeAttachment:(NSString *)content{
        //所有的自定义消息都会走这个解码方法，如有多种自定义消息请自行做好类型判断和版本兼容。这里仅演示最简单的情况。
        id<NIMCustomAttachment> attachment;
        NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
        if (data) {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([dict isKindOfClass:[NSDictionary class]]) {
                NSString *title = dict[@"title"];
                NSString *subTitle = dict[@"subTitle"];
                Attachment *myAttachment = [[Attachment alloc] init];
                myAttachment.title = title;
                myAttachment.subTitle = subTitle;
                attachment = myAttachment;
            }
        }
        return attachment;
    }
    
    @end
  ```
  
* 在 `- (BOOL)application: didFinishLaunchingWithOptions:` 中注入。

  ```objc
  - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
 ...
 [NIMCustomObject registerCustomDecoder:[[AttachmentDecoder alloc]init]];
 ... 
}
  ```
  
3.发送自定义消息

* <span name="NIMSessionConfig">选择何处发送自定义消息，这里做在输入区的菜单栏中发送的示例。</span>
   
   * 构建自定义会话配置，并加进组件会话控制器中(需要 UI 组件支持，如果没有继承则略过这个步骤)
   
	   ```objc
	   @interface SessionConfig : NSObject<NIMSessionConfig>
	   @end
	   ```
	   
	   ```objc
	   @implementation SessionConfig
	    ...
	    - (NSArray *)mediaItems{
	        NSInteger itemTag = 0; //即button的tag,在点击事件中判断这个tag来确定点了哪个菜单
	        return @[
	                [NIMMediaItem item:itemTag
	                        normalImage:[UIImage imageNamed:@"icon_custom_normal"]
	                    selectedImage:[UIImage imageNamed:@"icon_custom_pressed"]
	                            title:@"自定义消息"]
	        ];
	    }
	    ...
	    @end
	   ```
   
	 ```objc
	 - (void)onTapMediaItem:(NIMMediaItem *)item{
	        switch (item.tag) {
	            case 0:
	            //发送自定义消息
	                [self sendCustomMessage];
	                break;
	            default:
	                break;
	        }
	 }
	 ```
  
 * 构造自定义消息并发送。
 
	   ```objc
	    - (void)sendCustomMessage{
	        //构造自定义内容
	        Attachment *attachment = [[Attachment alloc] init];
	        attachment.title = @"这是一条自定义消息";
	        attachment.subTitle = @"这是自定义消息的副标题";
	        
	        //构造自定义MessageObject
	        NIMCustomObject *object = [[NIMCustomObject alloc] init];
	        object.attachment = attachment;
	        
	        //构造自定义消息
	        NIMMessage *message = [[NIMMessage alloc] init];
	        message.messageObject = object;
	        
	        //发送消息
	        [[NIMSDK sharedSDK].chatManager sendMessage:message toSession:self.session error:nil];
	    }
	   ```
   
4.接收自定义消息
  
自定义消息接收和其他普通消息一样，监听 `NIMChatManager` 的接收消息回调即可。

由于之前解码器已经定义好自定义的解码规则，直接取出消息中 `NIMCustomObject`的 `attachment` 属性。

```objc
- (void)onRecvMessages:(NSArray *)messages{
  ...
  NIMCustomObject *object = (NIMCustomObject *)message.messageObject;
  Attachment *attachment  = (Attachment *)object.attachment;
  ...
}
```

