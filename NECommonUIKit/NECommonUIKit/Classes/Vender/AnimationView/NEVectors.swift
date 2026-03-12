// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// MARK: - NELottieVector1D

public struct NELottieVector1D: Hashable, Sendable {
  public init(_ value: Double) {
    self.value = value
  }

  public let value: Double
}

// MARK: - NELottieVector3D

/// A three dimensional vector.
/// These vectors are encoded and decoded from [Double]
public struct NELottieVector3D: Hashable, Sendable {
  public let x: Double
  public let y: Double
  public let z: Double

  public init(x: Double, y: Double, z: Double) {
    self.x = x
    self.y = y
    self.z = z
  }
}
