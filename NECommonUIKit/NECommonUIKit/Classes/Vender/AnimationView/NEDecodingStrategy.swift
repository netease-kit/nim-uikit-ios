
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

/// How animation files should be decoded
public enum NEDecodingStrategy: Hashable {
  /// Use Codable. This is was the default strategy introduced on Lottie 3, but should be rarely
  /// used as it's slower than `dictionaryBased`. Kept here for any possible compatibility issues
  /// that may come up, but consider it soft-deprecated.
  case legacyCodable

  /// Manually deserialize a dictionary into an Animation.
  /// This should be at least 2-3x faster than using Codable and due to that
  /// it's the default as of Lottie 4.x.
  case dictionaryBased
}
