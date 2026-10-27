// Copyright (c) 2026 NetEase. All rights reserved.

import Foundation

public enum NEAdaptiveLayoutMode: Equatable {
  case compact, medium, expanded
}

public enum NEAdaptiveLayoutFallback: Equatable {
  case none, invalidInput, insufficientSingleContent, insufficientPairedContent
}

/// Insets belong to the raw window bounds, not an already inset content host.
public struct NEAdaptiveWindowGeometry {
  public let width: CGFloat
  public let height: CGFloat
  public let top: CGFloat
  public let left: CGFloat
  public let bottom: CGFloat
  public let right: CGFloat
  public init(width: CGFloat, height: CGFloat, top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) {
    self.width = width; self.height = height; self.top = top; self.left = left; self.bottom = bottom; self.right = right
  }
}

public struct NEAdaptiveColumnConfiguration {
  public let preferredMasterWidth: CGFloat
  public let maximumMasterWidth: CGFloat
  public init(preferredMasterWidth: CGFloat, maximumMasterWidth: CGFloat) {
    self.preferredMasterWidth = preferredMasterWidth; self.maximumMasterWidth = maximumMasterWidth
  }
}

/// No default rail or column dimensions until device/design calibration.
public struct NEAdaptiveLayoutConfiguration {
  public var mediumThreshold: CGFloat = 600
  public var expandedThreshold: CGFloat = 840
  public var compactAspectRatio: CGFloat = 1.2
  /// When true, the trailing rail owns the physical trailing edge, including
  /// the window's horizontal trailing safe-area region. This is the Duo
  /// presentation contract; the default keeps the original safe-rect budget.
  public var railUsesTrailingEdge = false
  public let railWidth: CGFloat
  public let singleContentMinimumWidth: CGFloat
  public let masterMinimumWidth: CGFloat
  public let detailMinimumWidth: CGFloat
  public let dividerWidth: CGFloat
  public let medium: NEAdaptiveColumnConfiguration
  public let expanded: NEAdaptiveColumnConfiguration
  public init(railWidth: CGFloat, singleContentMinimumWidth: CGFloat, masterMinimumWidth: CGFloat,
              detailMinimumWidth: CGFloat, dividerWidth: CGFloat,
              medium: NEAdaptiveColumnConfiguration, expanded: NEAdaptiveColumnConfiguration) {
    self.railWidth = railWidth; self.singleContentMinimumWidth = singleContentMinimumWidth
    self.masterMinimumWidth = masterMinimumWidth; self.detailMinimumWidth = detailMinimumWidth
    self.dividerWidth = dividerWidth; self.medium = medium; self.expanded = expanded
  }
}

public struct NEAdaptiveLayoutDecision: Equatable {
  /// nil means the existing shell must be retained.
  public let mode: NEAdaptiveLayoutMode?
  public let fallback: NEAdaptiveLayoutFallback
  public let contentWidth: CGFloat
  public let contentHeight: CGFloat
  public let masterWidth: CGFloat
  public let detailWidth: CGFloat
  public let dividerWidth: CGFloat

  public static func legacy(_ reason: NEAdaptiveLayoutFallback) -> Self {
    Self(mode: nil, fallback: reason, contentWidth: 0, contentHeight: 0,
         masterWidth: 0, detailWidth: 0, dividerWidth: 0)
  }
}

/// Pure per-call policy; no global geometry, SDK state, keyboard or view ownership.
public enum NEAdaptiveLayoutPolicy {
  public static func resolve(window: NEAdaptiveWindowGeometry,
                             configuration: NEAdaptiveLayoutConfiguration) -> NEAdaptiveLayoutDecision {
    let c = configuration
    let positive = [window.width, window.height, c.mediumThreshold, c.expandedThreshold,
                    c.compactAspectRatio, c.singleContentMinimumWidth,
                    c.masterMinimumWidth, c.detailMinimumWidth,
                    c.medium.preferredMasterWidth, c.medium.maximumMasterWidth,
                    c.expanded.preferredMasterWidth, c.expanded.maximumMasterWidth]
    let nonnegative = [window.top, window.left, window.bottom, window.right, c.dividerWidth, c.railWidth]
    guard positive.allSatisfy({ $0.isFinite && $0 > 0 }),
          nonnegative.allSatisfy({ $0.isFinite && $0 >= 0 }),
          c.expandedThreshold > c.mediumThreshold,
          c.medium.maximumMasterWidth >= c.masterMinimumWidth,
          c.expanded.maximumMasterWidth >= c.masterMinimumWidth
    else { return .legacy(.invalidInput) }

    let safeWidth = window.width - window.left - window.right
    let safeHeight = window.height - window.top - window.bottom
    let contentWidth = (c.railUsesTrailingEdge
      ? window.width - window.left - c.railWidth
      : safeWidth - c.railWidth)
    guard safeWidth.isFinite, safeHeight.isFinite, contentWidth.isFinite,
          safeWidth > 0, safeHeight > 0, contentWidth >= c.singleContentMinimumWidth
    else { return .legacy(.insufficientSingleContent) }

    let candidate: NEAdaptiveLayoutMode
    if window.width < c.mediumThreshold || window.height / window.width >= c.compactAspectRatio {
      candidate = .compact
    } else if window.width < c.expandedThreshold {
      candidate = .medium
    } else {
      candidate = .expanded
    }

    let pairedMinimum = c.masterMinimumWidth + c.dividerWidth + c.detailMinimumWidth
    guard pairedMinimum.isFinite else { return .legacy(.invalidInput) }
    if candidate == .compact || contentWidth < pairedMinimum {
      return NEAdaptiveLayoutDecision(
        mode: .compact,
        fallback: candidate == .compact ? .none : .insufficientPairedContent,
        contentWidth: contentWidth, contentHeight: safeHeight,
        masterWidth: 0, detailWidth: contentWidth, dividerWidth: 0
      )
    }

    let columns = candidate == .medium ? c.medium : c.expanded
    let upper = min(columns.maximumMasterWidth, contentWidth - c.dividerWidth - c.detailMinimumWidth)
    let master = min(max(columns.preferredMasterWidth, c.masterMinimumWidth), upper)
    return NEAdaptiveLayoutDecision(
      mode: candidate, fallback: .none, contentWidth: contentWidth, contentHeight: safeHeight,
      masterWidth: master, detailWidth: contentWidth - master - c.dividerWidth,
      dividerWidth: c.dividerWidth
    )
  }
}
