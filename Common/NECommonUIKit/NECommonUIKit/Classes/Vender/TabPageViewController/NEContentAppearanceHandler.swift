// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

protocol NEContentsAppearanceHandlerProtocol {
  var contentsDequeueHandler: (() -> [UIViewController?]?)? { get set }
  func beginDragging(at index: Int)
  func stopScrolling(at index: Int)
  func callApparance(_ apperance: NEContentsAppearanceHandler.Apperance, animated: Bool, at index: Int)
  func preReload(at index: Int)
  func postReload(at index: Int)
}

class NEContentsAppearanceHandler: NEContentsAppearanceHandlerProtocol {
  enum Apperance {
    case viewDidAppear
    case viewWillAppear
    case viewDidDisappear
    case viewWillDisappear
  }

  private var dissapearingIndex: Int?
  var contentsDequeueHandler: (() -> [UIViewController?]?)?

  func beginDragging(at index: Int) {
    guard let vcs = contentsDequeueHandler?(), index < vcs.endIndex, let vc = vcs[index] else {
      return
    }

    if let dissapearingIndex = dissapearingIndex, dissapearingIndex < vcs.endIndex, let prevVc = vcs[dissapearingIndex] {
      prevVc.endAppearanceTransition()
    }

    vc.beginAppearanceTransition(false, animated: false)
    dissapearingIndex = index
  }

  func stopScrolling(at index: Int) {
    guard let vcs = contentsDequeueHandler?(), index < vcs.endIndex, let vc = vcs[index] else {
      return
    }

    if let dissapearingIndex = dissapearingIndex, dissapearingIndex < vcs.endIndex, let prevVc = vcs[dissapearingIndex] {
      prevVc.endAppearanceTransition()
    }

    vc.beginAppearanceTransition(true, animated: false)
    vc.endAppearanceTransition()
    dissapearingIndex = nil
  }

  func callApparance(_ apperance: Apperance, animated: Bool, at index: Int) {
    guard let vcs = contentsDequeueHandler?(), index < vcs.endIndex, let vc = vcs[index] else {
      return
    }

    if let dissapearingIndex = dissapearingIndex,
       dissapearingIndex < vcs.endIndex,
       let prevVc = vcs[dissapearingIndex],
       dissapearingIndex == index {
      prevVc.endAppearanceTransition()
    }
    dissapearingIndex = nil

    switch apperance {
    case .viewDidAppear, .viewDidDisappear:
      vc.endAppearanceTransition()
    case .viewWillAppear:
      vc.beginAppearanceTransition(true, animated: animated)
    case .viewWillDisappear:
      vc.beginAppearanceTransition(false, animated: animated)
    }
  }

  func preReload(at index: Int) {
    guard let vcs = contentsDequeueHandler?(), index < vcs.endIndex, let vc = vcs[index] else {
      return
    }

    vc.beginAppearanceTransition(false, animated: false)
    vc.endAppearanceTransition()
  }

  func postReload(at index: Int) {
    guard let vcs = contentsDequeueHandler?(), index < vcs.endIndex, let vc = vcs[index] else {
      return
    }

    vc.beginAppearanceTransition(true, animated: false)
    vc.endAppearanceTransition()
  }
}
