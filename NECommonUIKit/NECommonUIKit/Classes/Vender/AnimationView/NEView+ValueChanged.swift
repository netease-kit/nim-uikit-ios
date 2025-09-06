// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#if canImport(Combine) && canImport(SwiftUI)
  import Combine
  import SwiftUI

  @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
  extension View {
    /// A backwards compatible wrapper for iOS 14 `onChange`
    @ViewBuilder
    func neValueChanged<T: Equatable>(value: T, onChange: @escaping (T) -> Void) -> some View {
      if #available(iOS 14.0, *, macOS 11.0, tvOS 14.0) {
        self.onChange(of: value, perform: onChange)
      } else {
        onReceive(Just(value)) { value in
          onChange(value)
        }
      }
    }
  }
#endif
