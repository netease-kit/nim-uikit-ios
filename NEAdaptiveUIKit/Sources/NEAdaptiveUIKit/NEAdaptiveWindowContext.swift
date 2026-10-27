import Foundation

public enum NEWindowSizeClass: Equatable {
  case unspecified, compact, regular
}

public struct NEWindowSnapshot: Equatable {
  public let size: CGSize
  public let safeAreaTop: CGFloat
  public let safeAreaLeft: CGFloat
  public let safeAreaBottom: CGFloat
  public let safeAreaRight: CGFloat
  public let horizontalSizeClass: NEWindowSizeClass
  public let verticalSizeClass: NEWindowSizeClass
  public init(size: CGSize, safeAreaTop: CGFloat, safeAreaLeft: CGFloat, safeAreaBottom: CGFloat, safeAreaRight: CGFloat,
              horizontalSizeClass: NEWindowSizeClass, verticalSizeClass: NEWindowSizeClass) {
    self.size = size; self.safeAreaTop = safeAreaTop; self.safeAreaLeft = safeAreaLeft; self.safeAreaBottom = safeAreaBottom
    self.safeAreaRight = safeAreaRight; self.horizontalSizeClass = horizontalSizeClass; self.verticalSizeClass = verticalSizeClass
  }

  public static func == (lhs: NEWindowSnapshot, rhs: NEWindowSnapshot) -> Bool {
    lhs.size.width == rhs.size.width && lhs.size.height == rhs.size.height &&
      lhs.safeAreaTop == rhs.safeAreaTop && lhs.safeAreaLeft == rhs.safeAreaLeft &&
      lhs.safeAreaBottom == rhs.safeAreaBottom && lhs.safeAreaRight == rhs.safeAreaRight &&
      lhs.horizontalSizeClass == rhs.horizontalSizeClass && lhs.verticalSizeClass == rhs.verticalSizeClass
  }
}

/// Hosts forward scene, root transition and safe-area updates to refresh().
public final class NEAdaptiveWindowContext {
  private var sample: (() -> NEWindowSnapshot?)?
  private var onChange: ((NEWindowSnapshot) -> Void)?
  private var isPublishing = false
  private var needsRefresh = false
  public private(set) var snapshot: NEWindowSnapshot?

  public init(sample: @escaping () -> NEWindowSnapshot?, onChange: @escaping (NEWindowSnapshot) -> Void) {
    precondition(Thread.isMainThread)
    self.sample = sample
    self.onChange = onChange
  }

  public func refresh() {
    precondition(Thread.isMainThread)
    guard sample != nil else { return }
    if isPublishing {
      needsRefresh = true
      return
    }
    isPublishing = true
    defer { isPublishing = false }
    // Reentrant refreshes sample only after the current consumer finishes.
    repeat {
      needsRefresh = false
      guard let sample else { break }
      let next = sample()
      guard self.sample != nil else { break }
      guard next != snapshot else { continue }
      snapshot = next
      if let next { onChange?(next) }
    } while needsRefresh
  }

  public func invalidate() {
    precondition(Thread.isMainThread)
    sample = nil
    onChange = nil
    snapshot = nil
    needsRefresh = false
  }
}

#if canImport(UIKit)
  import UIKit

  public extension NEAdaptiveWindowContext {
    convenience init(window: UIWindow, onChange: @escaping (NEWindowSnapshot) -> Void) {
      self.init(sample: { [weak window] in
        guard let window else { return nil }
        let insets = window.safeAreaInsets
        return NEWindowSnapshot(
          size: window.bounds.size,
          safeAreaTop: insets.top,
          safeAreaLeft: insets.left,
          safeAreaBottom: insets.bottom,
          safeAreaRight: insets.right,
          horizontalSizeClass: NEWindowSizeClass(window.traitCollection.horizontalSizeClass),
          verticalSizeClass: NEWindowSizeClass(window.traitCollection.verticalSizeClass)
        )
      }, onChange: onChange)
    }
  }

  private extension NEWindowSizeClass {
    init(_ value: UIUserInterfaceSizeClass) {
      switch value {
      case .compact: self = .compact
      case .regular: self = .regular
      default: self = .unspecified
      }
    }
  }
#endif
