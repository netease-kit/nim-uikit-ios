// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NEKeyframeGroup + exactlyOneKeyframe

extension NEKeyframeGroup {
  /// Retrieves the first `NEKeyframe` from this group,
  /// and asserts that there are not any extra keyframes that would be ignored
  ///  - This should only be used in cases where it's fundamentally not possible to
  ///    support animating a given property (e.g. if Core Animation itself doesn't
  ///    support the property).
  func exactlyOneKeyframe(context: NECompatibilityTrackerProviding,
                          description: String,
                          fileID _: StaticString = #fileID,
                          line _: UInt = #line)
    throws
    -> T {
    try context.compatibilityAssert(
      keyframes.count == 1,
      """
      The Core Animation rendering engine does not support animating multiple keyframes
      for \(description) values, due to limitations of Core Animation.
      """
    )

    return keyframes[0].value
  }
}
