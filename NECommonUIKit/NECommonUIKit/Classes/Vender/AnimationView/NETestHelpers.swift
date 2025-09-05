// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

enum NETestHelpers {
  /// Whether or not snapshot tests are currently running in a test target
  static var snapshotTestsAreRunning = false

  /// Whether or not performance tests are currently running in a test target
  static var performanceTestsAreRunning = false
}
