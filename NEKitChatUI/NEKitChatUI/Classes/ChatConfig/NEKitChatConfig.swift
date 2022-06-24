//
//  NEKitChatConfig.swift
//  NEKitChatUI
//
//  Created by vvj on 2022/6/15.
//

import UIKit

@objcMembers
public class NEKitChatConfig: NSObject {
    
    
    public static let shared = NEKitChatConfig()
    
    
    //chat UI配置相关
    public var ui = ChatUIConfig()
    
    //chat 其他配置 待扩展
}
