//
//  NEKitConversationConfig.swift
//  NEKitChatUI
//
//  Created by vvj on 2022/6/15.
//

import UIKit

@objcMembers
public class NEKitConversationConfig: NSObject {
    
    
    public static let shared = NEKitConversationConfig()
    
    
    
    //conversation ui 配置
    public var ui = ConversationUIConfig()
    
}
