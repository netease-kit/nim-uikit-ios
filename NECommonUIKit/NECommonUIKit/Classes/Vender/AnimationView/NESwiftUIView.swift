// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#if canImport(SwiftUI)
  import SwiftUI

  // MARK: - NESwiftUIView

  /// A `UIViewRepresentable` SwiftUI `View` that wraps its `Content` `UIView` within a
  /// `NESwiftUIMeasurementContainer`, used to size a UIKit view correctly within a SwiftUI view
  /// hierarchy.
  ///
  /// Includes an optional generic `Storage` value, which can be used to compare old and new values
  /// across state changes to prevent redundant view updates.
  @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
  struct NESwiftUIView<Content: NEViewType, Storage>: NEMeasuringViewRepresentable,
    NEUIViewConfiguringSwiftUIView {
    // MARK: Lifecycle

    /// Creates a SwiftUI representation of the content view with the given storage and the provided
    /// `makeContent` closure to construct the content whenever `makeUIView(…)` is invoked.
    init(storage: Storage, makeContent: @escaping () -> Content) {
      self.storage = storage
      self.makeContent = makeContent
    }

    /// Creates a SwiftUI representation of the content view with the provided `makeContent` closure
    /// to construct it whenever `makeUIView(…)` is invoked.
    init(makeContent: @escaping () -> Content) where Storage == Void {
      storage = ()
      self.makeContent = makeContent
    }

    // MARK: Internal

    var configurations: [Configuration] = []

    var sizing: NESwiftUIMeasurementContainerStrategy = .automatic

    // MARK: Private

    /// The current stored value, with the previous value provided to the configuration closure as
    /// the `oldStorage`.
    private var storage: Storage

    /// A closure that's invoked to construct the represented content view.
    private var makeContent: () -> Content
  }

  // MARK: UIViewRepresentable

  @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
  extension NESwiftUIView {
    func makeCoordinator() -> Coordinator {
      Coordinator(storage: storage)
    }

    #if os(macOS)
      func makeNSView(context _: Context) -> NESwiftUIMeasurementContainer<Content> {
        NESwiftUIMeasurementContainer(content: makeContent(), strategy: sizing)
      }

      func updateNSView(_ uiView: NESwiftUIMeasurementContainer<Content>, context: Context) {
        let oldStorage = context.coordinator.storage
        context.coordinator.storage = storage

        let configurationContext = ConfigurationContext(
          oldStorage: oldStorage,
          viewRepresentableContext: context,
          container: uiView
        )

        for configuration in configurations {
          configuration(configurationContext)
        }
      }
    #else
      func makeUIView(context _: Context) -> NESwiftUIMeasurementContainer<Content> {
        NESwiftUIMeasurementContainer(content: makeContent(), strategy: sizing)
      }

      func updateUIView(_ uiView: NESwiftUIMeasurementContainer<Content>, context: Context) {
        let oldStorage = context.coordinator.storage
        context.coordinator.storage = storage

        let configurationContext = ConfigurationContext(
          oldStorage: oldStorage,
          viewRepresentableContext: context,
          container: uiView
        )

        for configuration in configurations {
          configuration(configurationContext)
        }
      }
    #endif
  }

  // MARK: NESwiftUIView.ConfigurationContext

  @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
  extension NESwiftUIView {
    /// The configuration context that's available to configure the `Content` view whenever the
    /// `updateUIView()` method is invoked via a configuration closure.
    struct ConfigurationContext: NEViewProviding {
      /// The previous value for the `Storage` of this `NESwiftUIView`, which can be used to store
      /// values across state changes to prevent redundant view updates.
      var oldStorage: Storage

      /// The `UIViewRepresentable.Context`, with information about the transaction and environment.
      var viewRepresentableContext: Context

      /// The backing measurement container that contains the `Content`.
      var container: NESwiftUIMeasurementContainer<Content>

      /// The `UIView` content that's being configured.
      ///
      /// Setting this to a new value updates the backing measurement container's `content`.
      var view: Content {
        get { container.content }
        nonmutating set { container.content = newValue }
      }

      /// A convenience accessor indicating whether this content update should be animated.
      var animated: Bool {
        viewRepresentableContext.transaction.animation != nil
      }
    }
  }

  // MARK: NESwiftUIView.Coordinator

  @available(iOS 13.0, tvOS 13.0, macOS 10.15, *)
  extension NESwiftUIView {
    /// A coordinator that stores the `storage` associated with this view, enabling the old storage
    /// value to be accessed during the `updateUIView(…)`.
    final class Coordinator {
      // MARK: Lifecycle

      fileprivate init(storage: Storage) {
        self.storage = storage
      }

      // MARK: Internal

      fileprivate(set) var storage: Storage
    }
  }
#endif
