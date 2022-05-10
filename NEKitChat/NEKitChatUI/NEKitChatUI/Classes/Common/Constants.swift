
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import Foundation
@_exported import NEKitCore
@_exported import NEKitCommonUI
@_exported import NEKitCommon
@_exported import SDWebImage
//@_exported 
let coreLoader = CoreLoader<ChatBaseViewController>()
func localizable(_ key: String) -> String{
    return coreLoader.localizable(key)
}

func getJSONStringFromDictionary(_ dictionary: [String: Any]) -> String {
    if (!JSONSerialization.isValidJSONObject(dictionary)) {
        print("not parse to json string")
        return ""
    }
    if let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []),
       let JSONString = String(data: data, encoding: .utf8){
        return JSONString
    }
    return ""
}

func getDictionaryFromJSONString(_ jsonString: String) -> NSDictionary? {
    if let jsonData = jsonString.data(using: .utf8),
       let dict = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? NSDictionary{
        return dict
    }
    return nil
}

@objc public protocol ViewModelDelegate: AnyObject {
    func dataDidChange()
    func dataDidError(_ error: Error)
    @objc optional func dataNoMore()
}

// MARK: 常量
public let kScreenWidth:CGFloat = UIScreen.main.bounds.size.width
public let kScreenHeight:CGFloat = UIScreen.main.bounds.size.height
public let kUISreenWidthScale = kScreenWidth / 375.0
public let kUISreenHeightScale = kScreenHeight / 667.0
public let kNavigationHeight   = 44.0
public let KStatusBarHeight = UIApplication.shared.statusBarFrame.height //获取statusBar的高度
/// 屏幕间隔
public let kScreenInterval:CGFloat = 20


// MARK: 字体
let TextFont:((String ,Float ) -> UIFont) = {
    (fontName:String ,fontSize:Float ) -> UIFont in
    if #available(iOS 9.0, macOS 10,*) {
        return UIFont.init(name: fontName, size: CGFloat(fontSize))!
    }else {
        return UIFont.systemFont(ofSize: CGFloat(fontSize))
    }
}

let DefaultTextFont:((Float) -> UIFont) = {
    (fontSize:Float ) -> UIFont in
    return TextFont("PingFangSC-Regular",fontSize)
}




// MARK: 颜色
let TextNormalColor:UIColor = HexRGB(0x333333)
let SubTextColor:UIColor = HexRGB(0x666666)
let PlaceholderTextColor:UIColor = HexRGB(0xA6ADB6)


let HexRGB:((Int) -> UIColor) = { (rgbValue : Int) -> UIColor in
    return HexRGBAlpha(rgbValue,1.0)
}

let HexRGBAlpha:((Int,Float) -> UIColor) = { (rgbValue : Int, alpha : Float) -> UIColor in
    return UIColor(red: CGFloat(CGFloat((rgbValue & 0xFF0000) >> 16)/255), green: CGFloat(CGFloat((rgbValue & 0xFF00) >> 8)/255), blue: CGFloat(CGFloat(rgbValue & 0xFF)/255), alpha: CGFloat(alpha))
}

// MARK: notificationkey
struct NotificationName {
    // 参数 serverId: string
    static let createServer = Notification.Name(rawValue:"qchat.createServer")
    //param channel: ChatChannel
    static let createChannel = Notification.Name(rawValue:"qchat.createChannel")
    static let updateChannel = Notification.Name(rawValue:"qchat.updateChannel")
    static let deleteChannel = Notification.Name(rawValue:"qchat.deleteChannel")
    
//    static let login = Notification.Name(rawValue:"qchat.login")
    static let logout = Notification.Name(rawValue:"qchat.logout")


}
