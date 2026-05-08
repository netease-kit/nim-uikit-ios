// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK

@objcMembers
public class ResourceRepo: NSObject {
  public static let shared = ResourceRepo()

  /// 资源存储Provider
  public let storageProvider = StorageProvider.shared

  override private init() {
    super.init()
  }

  // MARK: - StorageProvider

  /// 创建文件上传任务
  /// - Parameters:
  ///   - fileParams 文件上传的相关参数
  open func createUploadFileTask(_ filePath: String,
                                 _ sceneName: String? = nil) -> V2NIMUploadFileTask {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + " filePath: \(filePath)")
    let fileParams = V2NIMUploadFileParams()
    fileParams.filePath = filePath
    if let sceneName = sceneName {
      fileParams.sceneName = sceneName
    }

    return storageProvider.createUploadFileTask(fileParams)
  }

  /// 上传文件
  /// - Parameters:
  ///   - filepath: 上传文件路径
  ///   - progress: 进度回调
  ///   - completion: 完成回调
  open func uploadFile(_ fileTask: V2NIMUploadFileTask,
                       _ progress: ((Float) -> Void)?,
                       _ completion: ((String?, NSError?) -> Void)?) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", taskId:\(fileTask.taskId)")
    storageProvider.uploadFile(fileTask, progress, completion)
  }

  /// 取消上传任务
  /// - Parameter filepath: 上传/下载任务对应的文件路径
  open func cancelTask(_ fileTask: V2NIMUploadFileTask,
                       _ completion: ((NSError?) -> Void)?) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", taskId:\(fileTask.taskId)")
    storageProvider.cancelUploadFile(fileTask, completion)
  }

  /// 下载文件
  /// - Parameters:
  ///   - urlString: 下载的 URL
  ///   - filePath: 保存路径
  ///   - progress: 进度回调
  ///   - completion: 完成回调
  open func downLoadFile(_ urlString: String,
                         _ filePath: String,
                         _ progress: ((UInt) -> Void)?,
                         _ completion: ((String?, NSError?) -> Void)?) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", urlString:\(urlString), filePath:\(filePath)")
    storageProvider.downloadFile(urlString, filePath, progress, completion)
  }

  /// 使用短链换源链
  /// - Parameters:
  ///   - targetUrl:  短链
  ///   - completion: 完成回调
  open func shortUrlToLong(url: String, _ completion: @escaping (Error?, String?) -> Void) {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", url:\(url)")
    storageProvider.shortUrlToLong(url: url, completion)
  }
}
