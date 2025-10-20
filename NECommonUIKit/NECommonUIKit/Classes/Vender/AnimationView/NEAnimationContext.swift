
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import QuartzCore

/// A completion block for animations.
///  - `true` is passed in if the animation completed playing.
///  - `false` is passed in if the animation was interrupted and did not complete playing.
public typealias NELottieCompletionBlock = (_ completed: Bool) -> Void

// MARK: - NEAnimationContext

struct NEAnimationContext {
  init(playFrom: NEAnimationFrameTime,
       playTo: NEAnimationFrameTime,
       closure: NELottieCompletionBlock?) {
    self.playTo = playTo
    self.playFrom = playFrom
    self.closure = NEAnimationCompletionDelegate(completionBlock: closure)
  }

  var playFrom: NEAnimationFrameTime
  var playTo: NEAnimationFrameTime
  var closure: NEAnimationCompletionDelegate
}

// MARK: Equatable

extension NEAnimationContext: Equatable {
  /// Whether or not the two given `NEAnimationContext`s are functionally equivalent
  ///  - This checks whether or not a completion handler was provided,
  ///    but does not check whether or not the two completion handlers are equivalent.
  static func == (_ lhs: NEAnimationContext, _ rhs: NEAnimationContext) -> Bool {
    lhs.playTo == rhs.playTo
      && lhs.playFrom == rhs.playFrom
      && (lhs.closure.completionBlock == nil) == (rhs.closure.completionBlock == nil)
  }
}

// MARK: - NENEAnimationContextState

enum NENEAnimationContextState {
  case playing
  case cancelled
  case complete
}

// MARK: - AnimationCompletionDelegate

class NEAnimationCompletionDelegate: NSObject, CAAnimationDelegate {
  // MARK: Lifecycle

  init(completionBlock: NELottieCompletionBlock?) {
    self.completionBlock = completionBlock
    super.init()
  }

  // MARK: Public

  func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
    guard ignoreDelegate == false else { return }
    animationState = flag ? .complete : .cancelled
    if let animationLayer, let key = animationKey {
      animationLayer.removeAnimation(forKey: key)
      if flag {
        animationLayer.currentFrame = (anim as! CABasicAnimation).toValue as! CGFloat
      }
    }
    if let completionBlock {
      completionBlock(flag)
    }
  }

  // MARK: Internal

  var animationLayer: NERootAnimationLayer?
  var animationKey: String?
  var ignoreDelegate = false
  var animationState: NENEAnimationContextState = .playing

  let completionBlock: NELottieCompletionBlock?
}
