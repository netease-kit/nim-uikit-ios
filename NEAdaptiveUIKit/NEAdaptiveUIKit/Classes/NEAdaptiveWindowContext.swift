import CoreGraphics
import Foundation

public enum NEWindowSizeClass: Equatable {
  case unspecified, compact, regular
}

/// 当前激活的系统占位区（折叠区 / 摄像头遮挡等）的快照。
///
/// 只用于判断窗口几何是否发生变化并触发一次刷新，不直接参与页面或
/// rail 的尺寸计算；布局仍读取实时 `reservedRegions`。
public struct NEReservedRegionSnapshot: Equatable {
  public enum Kind: Equatable {
    case occlusion
    case division
  }

  public let kind: Kind
  public let frame: CGRect

  public init(kind: Kind, frame: CGRect) {
    self.kind = kind
    self.frame = frame
  }

  public static func == (lhs: NEReservedRegionSnapshot, rhs: NEReservedRegionSnapshot) -> Bool {
    lhs.kind == rhs.kind &&
      lhs.frame.origin.x == rhs.frame.origin.x &&
      lhs.frame.origin.y == rhs.frame.origin.y &&
      lhs.frame.size.width == rhs.frame.size.width &&
      lhs.frame.size.height == rhs.frame.size.height
  }
}

public struct NEWindowSnapshot: Equatable {
  public let size: CGSize
  public let safeAreaTop: CGFloat
  public let safeAreaLeft: CGFloat
  public let safeAreaBottom: CGFloat
  public let safeAreaRight: CGFloat
  public let horizontalSizeClass: NEWindowSizeClass
  public let verticalSizeClass: NEWindowSizeClass
  /// 窗口所在屏幕的 display scale。
  public let displayScale: CGFloat
  /// 当前激活的 division / occlusion 占位区，按类别与位置稳定排序。
  public let reservedRegions: [NEReservedRegionSnapshot]
  public init(size: CGSize, safeAreaTop: CGFloat, safeAreaLeft: CGFloat, safeAreaBottom: CGFloat, safeAreaRight: CGFloat,
              horizontalSizeClass: NEWindowSizeClass, verticalSizeClass: NEWindowSizeClass,
              displayScale: CGFloat = 0, reservedRegions: [NEReservedRegionSnapshot] = []) {
    self.size = size; self.safeAreaTop = safeAreaTop; self.safeAreaLeft = safeAreaLeft; self.safeAreaBottom = safeAreaBottom
    self.safeAreaRight = safeAreaRight; self.horizontalSizeClass = horizontalSizeClass; self.verticalSizeClass = verticalSizeClass
    self.displayScale = displayScale
    self.reservedRegions = reservedRegions
  }

  /// 占位区集合的稳定指纹，便于诊断与比较；相等性仍以 `reservedRegions` 为准。
  public var reservedRegionFingerprint: UInt64 {
    var hash: UInt64 = 0xcbf2_9ce4_8422_2325
    for region in reservedRegions {
      hash = Self.mix(hash, region.kind == .occlusion ? 1 : 2)
      hash = Self.mix(hash, Double(region.frame.minX).bitPattern)
      hash = Self.mix(hash, Double(region.frame.minY).bitPattern)
      hash = Self.mix(hash, Double(region.frame.width).bitPattern)
      hash = Self.mix(hash, Double(region.frame.height).bitPattern)
    }
    return hash
  }

  public static func == (lhs: NEWindowSnapshot, rhs: NEWindowSnapshot) -> Bool {
    lhs.size.width == rhs.size.width && lhs.size.height == rhs.size.height &&
      lhs.safeAreaTop == rhs.safeAreaTop && lhs.safeAreaLeft == rhs.safeAreaLeft &&
      lhs.safeAreaBottom == rhs.safeAreaBottom && lhs.safeAreaRight == rhs.safeAreaRight &&
      lhs.horizontalSizeClass == rhs.horizontalSizeClass && lhs.verticalSizeClass == rhs.verticalSizeClass &&
      lhs.displayScale == rhs.displayScale && lhs.reservedRegions == rhs.reservedRegions
  }

  private static func mix(_ hash: UInt64, _ value: UInt64) -> UInt64 {
    (hash ^ value) &* 0x100_0000_01b3
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
          verticalSizeClass: NEWindowSizeClass(window.traitCollection.verticalSizeClass),
          displayScale: window.traitCollection.displayScale,
          reservedRegions: NEWindowSnapshot.activeReservedRegions(in: window)
        )
      }, onChange: onChange)
    }
  }

  extension NEWindowSnapshot {
    /// 读取窗口当前激活的 division / occlusion 占位区。
    /// 同一类别内按坐标排序，避免系统返回顺序变化造成误判。
    static func activeReservedRegions(in window: UIWindow) -> [NEReservedRegionSnapshot] {
      guard #available(iOS 27.1, *) else { return [] }
      let occlusions = window.reservedRegions(kind: .occlusion)
        .filter(\.isActive)
        .map { NEReservedRegionSnapshot(kind: .occlusion, frame: $0.frame) }
      let divisions = window.reservedRegions(kind: .division)
        .filter(\.isActive)
        .map { NEReservedRegionSnapshot(kind: .division, frame: $0.frame) }
      return (occlusions + divisions).sorted { lhs, rhs in
        if lhs.kind != rhs.kind { return lhs.kind == .occlusion }
        if lhs.frame.minX != rhs.frame.minX { return lhs.frame.minX < rhs.frame.minX }
        if lhs.frame.minY != rhs.frame.minY { return lhs.frame.minY < rhs.frame.minY }
        if lhs.frame.width != rhs.frame.width { return lhs.frame.width < rhs.frame.width }
        return lhs.frame.height < rhs.frame.height
      }
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
