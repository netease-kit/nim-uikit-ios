
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NEChatKit
@_exported import NECommonKit
@_exported import NECommonUIKit
@_exported import NECoreIM2Kit
@_exported import NECoreKit

let coreLoader = CoreLoader<NEChatBaseViewController>()
func chatLocalizable(_ key: String) -> String {
  coreLoader.localizable(key)
}

public func getJSONStringFromDictionary(_ dictionary: [String: Any]) -> String {
  if !JSONSerialization.isValidJSONObject(dictionary) {
    print("not parse to json string")
    return ""
  }
  if let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []),
     let JSONString = String(data: data, encoding: .utf8) {
    return JSONString
  }
  return ""
}

public func getDictionaryFromJSONString(_ jsonString: String) -> NSDictionary? {
  if let jsonData = jsonString.data(using: .utf8),
     let dict = try? JSONSerialization.jsonObject(
       with: jsonData,
       options: .mutableContainers
     ) as? NSDictionary {
    return dict
  }
  return nil
}

// 重载~=运算符, 用于switch-case匹配数组
func ~= <T: Equatable>(caseList: [T], caseOne: T) -> Bool {
  caseList.contains(caseOne)
}

@objc public protocol ViewModelDelegate: NSObjectProtocol {
  func dataDidChange()
  func dataDidError(_ error: Error)
  @objc optional func dataNoMore()
}

// MARK: 常量

public let kScreenWidth: CGFloat = UIScreen.main.bounds.size.width
public let kScreenHeight: CGFloat = UIScreen.main.bounds.size.height
public let kUISreenWidthScale = kScreenWidth / 375.0
public let kUISreenHeightScale = kScreenHeight / 667.0
public let kNavigationHeight = 44.0
public let KStatusBarHeight = UIApplication.shared.statusBarFrame.height // 获取statusBar的高度
public let ModuleName = "NEChatUIKit" // module 模块名称，用于日志输出

/// 支持的文件格式，不区分大小写
// 支持的音频格式
public let file_audio_support: [String] = ["mp3", "aac", "wav", "wma", "flac"]
// 支持的视频格式
public let file_vedio_support: [String] = ["mp4", "avi", "wmv", "mpeg", "m4v", "mov", "asf", "flv", "f4v", "rmvb", "rm", "3gp"]
// 支持的图片格式
public let file_img_support: [String] = ["jpg", "jpeg", "png", "tiff", "heic"]
// 支持的表格格式
public let file_xls_support: [String] = ["xls", "xlsx", "csv"]
// 支持的文档格式
public let file_doc_support: [String] = ["doc", "docx"]
// 支持的PPT格式
public let file_ppt_support: [String] = ["ppt", "pptx"]
// 支持的文本格式
public let file_txt_support: [String] = ["txt"]
// 支持的压缩文件格式
public let file_zip_support: [String] = ["zip", "tar", "rar", "7z"]
// 支持的PDF格式
public let file_pdf_support: [String] = ["pdf", "rtf"]
// 支持的超链接格式
public let file_html_support: [String] = ["html"]

/// 屏幕间隔
public let kScreenInterval: CGFloat = 20
public let NEMoreView_Section_Padding: CGFloat = 24.0

// 更多操作view
public let NEMoreCell_ReuseId: String = "NEMoreCell"
public let NEMoreCell_Image_Size: CGSize = .init(width: 56.0, height: 56.0)
public let NEMoreCell_Title_Height: CGFloat = 20.0
public let NEMoreView_Margin: CGFloat = 16.0
public let NEMoreView_Column_Count: Int = 4

// MARK: 字体

let TextFont: ((String, Float) -> UIFont) = {
  (fontName: String, fontSize: Float) -> UIFont in
  if #available(iOS 9.0, macOS 10,*) {
    return UIFont(name: fontName, size: CGFloat(fontSize))!
  } else {
    return UIFont.systemFont(ofSize: CGFloat(fontSize))
  }
}

let DefaultTextFont: ((Float) -> UIFont) = {
  (fontSize: Float) -> UIFont in
  TextFont("PingFangSC-Regular", fontSize)
}

// MARK: 颜色

let TextNormalColor: UIColor = HexRGB(0x333333)
let SubTextColor: UIColor = HexRGB(0x666666)
let PlaceholderTextColor: UIColor = HexRGB(0xA6ADB6)
let multiForwardLineColor: UIColor = HexRGB(0xF0F1F5)
let forwardLineColor: UIColor = HexRGB(0xE1E6E8)
let multiForwardborderColor: UIColor = HexRGB(0xE4E9F2)

let HexRGB: ((Int) -> UIColor) = { (rgbValue: Int) -> UIColor in
  HexRGBAlpha(rgbValue, 1.0)
}

let HexRGBAlpha: ((Int, Float) -> UIColor) = { (rgbValue: Int, alpha: Float) -> UIColor in
  UIColor(
    red: CGFloat(CGFloat((rgbValue & 0xFF0000) >> 16) / 255),
    green: CGFloat(CGFloat((rgbValue & 0xFF00) >> 8) / 255),
    blue: CGFloat(CGFloat(rgbValue & 0xFF) / 255),
    alpha: CGFloat(alpha)
  )
}

// MARK: notificationkey

extension NENotificationName {
  // 参数 serverId: string
  static let createServer = Notification.Name(rawValue: "qchat.createServer")
  // param channel: ChatChannel
  static let createChannel = Notification.Name(rawValue: "qchat.createChannel")
  static let updateChannel = Notification.Name(rawValue: "qchat.updateChannel")
  static let deleteChannel = Notification.Name(rawValue: "qchat.deleteChannel")
  static let leaveTeamBySelf = Notification.Name(rawValue: "team.leaveTeamBySelf")
  static let popGroupChatVC = Notification.Name(rawValue: "team.popGroupChatVC")

//    static let login = Notification.Name(rawValue:"qchat.login")
  static let logout = Notification.Name(rawValue: "qchat.logout")
}
