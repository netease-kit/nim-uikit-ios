// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import UIKit

/// 路径处理封装
@objcMembers public class NEPathUtils: NSObject {
  /// 获取document目录下的某个文件夹，支持传入多级，如不存在会新建该文件夹
  /// - Parameter dir: 文件夹名称，支持子路径，如 "123/456/789"
  /// - Returns: 文件夹的绝对路径
  public class func getDirectoryForDocuments(dir: String) -> String? {
    if let documentsDirectory = getDocumentPath() {
      let dirPath = documentsDirectory + "/" + dir
      let isDirPointer = UnsafeMutablePointer<ObjCBool>.allocate(capacity: MemoryLayout<ObjCBool>.stride)
      let isCreated = FileManager.default.fileExists(atPath: dirPath, isDirectory: isDirPointer)
      let isDir = isDirPointer.pointee
      isDirPointer.deallocate()
      if !isCreated || !isDir.boolValue {
        try? FileManager.default.createDirectory(atPath: dirPath, withIntermediateDirectories: true)
      }
      return dirPath
    }
    return nil
  }

  /// 获取document目录路径
  /// - Returns: document目录路径
  public class func getDocumentPath() -> String? {
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    if paths.count > 0,
       let documentsDirectory = paths.first {
      return documentsDirectory
    }
    return nil
  }
}
