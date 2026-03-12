//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

public extension UITableView {
  /// 重新加载单元格
  /// - Parameters:
  ///   - indexs: 位置
  ///   - animation: 动画效果
  func reloadData(_ indexs: [IndexPath],
                  _ animation: UITableView.RowAnimation = .none,
                  _ completion: ((Bool) -> Void)? = nil) {
    performBatchUpdates {
      self.reloadRows(at: indexs, with: animation)
    } completion: { succ in
      completion?(succ)
    }
  }

  /// 删除单元格
  /// - Parameters:
  ///   - indexs: 位置
  ///   - animation: 动画效果
  func deleteData(_ indexs: [IndexPath],
                  _ animation: UITableView.RowAnimation = .none,
                  _ completion: ((Bool) -> Void)? = nil) {
    performBatchUpdates {
      self.deleteRows(at: indexs, with: animation)
    } completion: { succ in
      completion?(succ)
    }
  }

  /// 添加单元格
  /// - Parameters:
  ///   - indexs: 位置
  ///   - animation: 动画效果
  func insertData(_ indexs: [IndexPath],
                  _ animation: UITableView.RowAnimation = .none,
                  _ completion: ((Bool) -> Void)? = nil) {
    performBatchUpdates {
      self.insertRows(at: indexs, with: animation)
    } completion: { succ in
      completion?(succ)
    }
  }
}
