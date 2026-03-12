
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#if canImport(SwiftUI)
  import SwiftUI

  @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
  extension Binding {
    /// Helper to transform a `Binding` from one `Value` type to another.
    func neMap<Transformed>(transform: @escaping (Value) -> Transformed) -> Binding<Transformed> {
      .init {
        transform(wrappedValue)
      } set: { newValue in
        guard let newValue = newValue as? Value else { return }
        self.wrappedValue = newValue
      }
    }
  }
#endif
