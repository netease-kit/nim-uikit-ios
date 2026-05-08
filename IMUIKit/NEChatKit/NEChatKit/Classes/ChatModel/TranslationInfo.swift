// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

/// 消息译文信息，存储在消息 localExtension 的 "translation" 节点中。
@objcMembers
public class TranslationInfo: NSObject {
  /// 翻译目标语言代码（如 "zh-CHS"、"en"）
  public var targetLanguage: String = ""

  /// 翻译结果文本
  public var translatedText: String = ""

  /// 翻译发起时刻（毫秒时间戳），非消息创建时间
  public var createTime: TimeInterval = 0

  public init(targetLanguage: String, translatedText: String, createTime: TimeInterval = Date().timeIntervalSince1970 * 1000) {
    self.targetLanguage = targetLanguage
    self.translatedText = translatedText
    self.createTime = createTime
  }

  // MARK: - JSON 序列化 / 反序列化

  /// 从 localExtension JSON 字符串中解析 TranslationInfo
  /// - Parameter localExtension: 消息的 localExtension 字符串
  /// - Returns: 解析成功返回 TranslationInfo，否则 nil
  public static func parse(from localExtension: String?) -> TranslationInfo? {
    guard let ext = localExtension,
          !ext.isEmpty,
          let data = ext.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let translationDict = json["translation"] as? [String: Any],
          let targetLang = translationDict["targetLanguage"] as? String,
          let translatedText = translationDict["translatedText"] as? String,
          !targetLang.isEmpty,
          !translatedText.isEmpty else {
      return nil
    }
    let createTime = translationDict["createTime"] as? TimeInterval ?? 0
    return TranslationInfo(targetLanguage: targetLang, translatedText: translatedText, createTime: createTime)
  }

  /// 将 TranslationInfo 合并写入已有 localExtension JSON 字符串（保留其他字段）
  /// - Parameter localExtension: 已有的 localExtension 字符串（可为 nil）
  /// - Returns: 合并后的 JSON 字符串
  public func merged(into localExtension: String?) -> String {
    var dict: [String: Any] = [:]
    if let ext = localExtension,
       !ext.isEmpty,
       let data = ext.data(using: .utf8),
       let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
      dict = existing
    }
    dict["translation"] = [
      "targetLanguage": targetLanguage,
      "translatedText": translatedText,
      "createTime": createTime,
    ]
    if let data = try? JSONSerialization.data(withJSONObject: dict),
       let result = String(data: data, encoding: .utf8) {
      return result
    }
    return localExtension ?? ""
  }

  /// 从 localExtension JSON 中移除 translation 节点（保留其他字段），用于撤回清除
  /// - Parameter localExtension: 原始 localExtension 字符串
  /// - Returns: 移除 translation 后的 JSON 字符串，若原本无 translation 则返回 nil（无需更新）
  public static func cleared(from localExtension: String?) -> String? {
    guard let ext = localExtension,
          !ext.isEmpty,
          let data = ext.data(using: .utf8),
          var dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          dict["translation"] != nil else {
      return nil
    }
    dict.removeValue(forKey: "translation")
    if let resultData = try? JSONSerialization.data(withJSONObject: dict),
       let result = String(data: resultData, encoding: .utf8) {
      return result
    }
    return nil
  }
}
