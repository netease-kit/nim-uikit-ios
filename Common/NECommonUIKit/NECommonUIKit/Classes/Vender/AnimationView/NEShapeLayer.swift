// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import QuartzCore

// MARK: - NEShapeLayer

/// The CALayer type responsible for rendering `NEShapeLayerModel`s
final class NEShapeLayer: NEBaseCompositionLayer {
  // MARK: Lifecycle

  init(shapeLayer: NEShapeLayerModel, context: NELayerContext) throws {
    self.shapeLayer = shapeLayer
    super.init(layerModel: shapeLayer)
    try setUpGroups(context: context)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// Called by CoreAnimation to create a shadow copy of this layer
  /// More details: https://developer.apple.com/documentation/quartzcore/calayer/1410842-init
  override init(layer: Any) {
    guard let typedLayer = layer as? Self else {
      fatalError("\(Self.self).init(layer:) incorrectly called with \(type(of: layer))")
    }

    shapeLayer = typedLayer.shapeLayer
    super.init(layer: typedLayer)
  }

  // MARK: Private

  private let shapeLayer: NEShapeLayerModel

  private func setUpGroups(context: NELayerContext) throws {
    let shapeItems = shapeLayer.items.map { NEShapeItemLayer.Item(item: $0, groupPath: []) }
    try setupGroups(from: shapeItems, parentGroup: nil, parentGroupPath: [], context: context)
  }
}

// MARK: - NEGroupLayer

/// The CALayer type responsible for rendering `NEGroup`s
final class NEGroupLayer: NEBaseAnimationLayer {
  // MARK: Lifecycle

  init(group: NEGroup, items: [NEShapeItemLayer.Item], groupPath: [String], context: NELayerContext) throws {
    self.group = group
    self.items = items
    self.groupPath = groupPath
    super.init()
    try setupLayerHierarchy(context: context)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// Called by CoreAnimation to create a shadow copy of this layer
  /// More details: https://developer.apple.com/documentation/quartzcore/calayer/1410842-init
  override init(layer: Any) {
    guard let typedLayer = layer as? Self else {
      fatalError("\(Self.self).init(layer:) incorrectly called with \(type(of: layer))")
    }

    group = typedLayer.group
    items = typedLayer.items
    groupPath = typedLayer.groupPath
    super.init(layer: typedLayer)
  }

  // MARK: Internal

  override func setupAnimations(context: NELayerAnimationContext) throws {
    try super.setupAnimations(context: context)

    if let (shapeTransform, context) = nonGroupItems.first(NEShapeTransform.self, context: context) {
      try addTransformAnimations(for: shapeTransform, context: context)
      try addOpacityAnimation(for: shapeTransform, context: context)
    }
  }

  // MARK: Private

  private let group: NEGroup

  /// `NEShapeItemLayer.Item`s rendered by this `NEGroup`
  ///  - In the original `NEShapeLayer` data model, these items could have originated from a different group
  private let items: [NEShapeItemLayer.Item]

  /// The keypath that represents this group, with respect to the parent `NEShapeLayer`
  ///  - Due to the way `NEGroupLayer`s are setup, the original `NEShapeItem`
  ///    hierarchy from the `NEShapeLayer` data model may no longer exactly
  ///    match the hierarchy of `NEGroupLayer` / `NEShapeItemLayer`s constructed
  ///    at runtime. Since animation keypaths need to match the original
  ///    structure of the `NEShapeLayer` data model, we track that info here.
  private let groupPath: [String]

  /// Child group items contained in this group. Correspond to a child `NEGroupLayer`
  private lazy var childGroups = items.filter { $0.item is NEGroup }

  /// `NEShapeItem`s (other than nested `NEGroup`s) that are rendered by this layer
  private lazy var nonGroupItems = items.filter { !($0.item is NEGroup) }

  private func setupLayerHierarchy(context: NELayerContext) throws {
    // Groups can contain other groups, so we may have to continue
    // recursively creating more `NEGroupLayer`s
    try setupGroups(from: items, parentGroup: group, parentGroupPath: groupPath, context: context)

    // Create `NEShapeItemLayer`s for each subgroup of shapes that should be rendered as a single unit
    //  - These groups are listed from front-to-back, so we have to add the sublayers in reverse order
    let renderGroups = items.shapeRenderGroups(groupHasChildGroupsToInheritUnusedItems: !childGroups.isEmpty)
    for shapeRenderGroup in renderGroups.validGroups.reversed() {
      // When there are multiple path-drawing items, they're supposed to be rendered
      // in a single `CAShapeLayer` (instead of rendering them in separate layers) so
      // `CAShapeLayerFillRule.evenOdd` can be applied correctly if the paths overlap.
      // Since a `CAShapeLayer` only supports animating a single `CGPath` from a single `NEKeyframeGroup<NEBezierPath>`,
      // this requires combining all of the path-drawing items into a single set of keyframes.
      if
        shapeRenderGroup.pathItems.count > 1,
        // We currently only support this codepath for `NEShape` items that directly contain bezier path keyframes.
        // We could also support this for other path types like rectangles, ellipses, and polygons with more work.
        shapeRenderGroup.pathItems.allSatisfy({ $0.item is NEShape }),
        // `NETrim`s are currently only applied correctly using individual `NEShapeItemLayer`s,
        // because each path has to be trimmed separately.
        !shapeRenderGroup.otherItems.contains(where: { $0.item is NETrim }) {
        let allPathKeyframes = shapeRenderGroup.pathItems.compactMap { ($0.item as? NEShape)?.path }
        let combinedShape = NECombinedShapeItem(
          shapes: NEKeyframes.combined(allPathKeyframes),
          name: group.name
        )

        let sublayer = try NEShapeItemLayer(
          shape: NEShapeItemLayer.Item(item: combinedShape, groupPath: shapeRenderGroup.pathItems[0].groupPath),
          otherItems: shapeRenderGroup.otherItems,
          context: context
        )

        addSublayer(sublayer)
      }

      // Otherwise, if each `NEShapeItem` that draws a `GGPath` animates independently,
      // we have to create a separate `NEShapeItemLayer` for each one. This may render
      // incorrectly if there are multiple paths that overlap with each other.
      else {
        for pathDrawingItem in shapeRenderGroup.pathItems {
          let sublayer = try NEShapeItemLayer(
            shape: pathDrawingItem,
            otherItems: shapeRenderGroup.otherItems,
            context: context
          )

          addSublayer(sublayer)
        }
      }
    }
  }
}

extension CALayer {
  // MARK: Fileprivate

  /// Sets up `NEGroupLayer`s for each `NEGroup` in the given list of `NEShapeItem`s
  ///  - Each `NEGroup` item becomes its own `NEGroupLayer` sublayer.
  ///  - Other `NEShapeItem` are applied to all sublayers
  fileprivate func setupGroups(from items: [NEShapeItemLayer.Item],
                               parentGroup: NEGroup?,
                               parentGroupPath: [String],
                               context: NELayerContext)
    throws {
    // If the layer has any `NERepeater`s, set up each repeater
    // and then handle any remaining groups like normal.
    if items.contains(where: { $0.item is NERepeater }) {
      let repeaterGroupings = items.split(whereSeparator: { $0.item is NERepeater })

      // Iterate through the groupings backwards to preserve the expected rendering order
      for repeaterGrouping in repeaterGroupings.reversed() {
        // Each repeater applies to the previous items in the list
        if let repeater = repeaterGrouping.trailingSeparator?.item as? NERepeater {
          try setUpRepeater(
            repeater,
            items: repeaterGrouping.grouping,
            parentGroupPath: parentGroupPath,
            context: context
          )
        }

        // Any remaining items after the last repeater are handled like normal
        else {
          try setupGroups(
            from: repeaterGrouping.grouping,
            parentGroup: parentGroup,
            parentGroupPath: parentGroupPath,
            context: context
          )
        }
      }
    }

    else {
      let groupLayers = try makeGroupLayers(
        from: items,
        parentGroup: parentGroup,
        parentGroupPath: parentGroupPath,
        context: context
      )

      for groupLayer in groupLayers {
        addSublayer(groupLayer)
      }
    }
  }

  // MARK: Private

  /// Sets up this layer using the given `NERepeater`
  private func setUpRepeater(_ repeater: NERepeater,
                             items allItems: [NEShapeItemLayer.Item],
                             parentGroupPath: [String],
                             context: NELayerContext)
    throws {
    let items = allItems.filter { !($0.item is NERepeater) }
    let copyCount = try Int(repeater.copies.exactlyOneKeyframe(context: context, description: "repeater copies").value)

    for index in 0 ..< copyCount {
      let groupLayers = try makeGroupLayers(
        from: items,
        parentGroup: nil, // The repeater layer acts as the parent of its sublayers
        parentGroupPath: parentGroupPath,
        context: context
      )

      for groupLayer in groupLayers {
        let repeatedLayer = NERepeaterLayer(repeater: repeater, childLayer: groupLayer, index: index)
        addSublayer(repeatedLayer)
      }
    }
  }

  /// Creates a `NEGroupLayer` for each `NEGroup` in the given list of `NEShapeItem`s
  ///  - Each `NEGroup` item becomes its own `NEGroupLayer` sublayer.
  ///  - Other `NEShapeItem` are applied to all sublayers
  private func makeGroupLayers(from items: [NEShapeItemLayer.Item],
                               parentGroup: NEGroup?,
                               parentGroupPath: [String],
                               context: NELayerContext)
    throws -> [NEGroupLayer] {
    var groupItems = items.compactMap { $0.item as? NEGroup }.filter { !$0.hidden }
    var otherItems = items.filter { !($0.item is NEGroup) && !$0.item.hidden }

    // Handle the top-level `shapeLayer.items` array. This is typically just a single `NEGroup`,
    // but in practice can be any combination of items. The implementation expects all path-drawing
    // shape items to be managed by a `NEGroupLayer`, so if there's a top-level path item we
    // have to create a placeholder group.
    if parentGroup == nil, otherItems.contains(where: { $0.item.drawsCGPath }) {
      groupItems = [NEGroup(items: items.map { $0.item }, name: "")]
      otherItems = []
    }

    // Any child items that wouldn't be included in a valid shape render group
    // need to be applied to child groups (otherwise they'd be silently ignored).
    let inheritedItemsForChildGroups = otherItems
      .shapeRenderGroups(groupHasChildGroupsToInheritUnusedItems: !groupItems.isEmpty)
      .unusedItems

    // Groups are listed from front to back,
    // but `CALayer.sublayers` are listed from back to front.
    let groupsInZAxisOrder = groupItems.reversed()

    return try groupsInZAxisOrder.compactMap { group in
      var pathForChildren = parentGroupPath
      if !group.name.isEmpty {
        pathForChildren.append(group.name)
      }

      let childItems = group.items
        .filter { !$0.hidden }
        .map { NEShapeItemLayer.Item(item: $0, groupPath: pathForChildren) }

      // Some shape item properties are affected by scaling (e.g. stroke width).
      // The child group may have a `NEShapeTransform` that affects the scale of its items,
      // but shouldn't affect the scale of any inherited items. To prevent this scale
      // from affecting inherited items, we have to apply an inverse scale to them.
      let inheritedItems = try inheritedItemsForChildGroups.map { item in
        try NEShapeItemLayer.Item(
          item: item.item.scaledCopyForChildGroup(group, context: context),
          groupPath: item.groupPath
        )
      }

      return try NEGroupLayer(
        group: group,
        items: childItems + inheritedItems,
        groupPath: pathForChildren,
        context: context
      )
    }
  }
}

extension NEShapeItem {
  /// Whether or not this `NEShapeItem` is responsible for rendering a `CGPath`
  var drawsCGPath: Bool {
    switch type {
    case .ellipse, .rectangle, .shape, .star:
      return true

    case .fill, .gradientFill, .group, .gradientStroke, .merge,
         .repeater, .round, .stroke, .trim, .transform, .unknown:
      return false
    }
  }

  /// Whether or not this `NEShapeItem` provides a fill for a set of shapes
  var isFill: Bool {
    switch type {
    case .fill, .gradientFill:
      return true

    case .ellipse, .rectangle, .shape, .star, .group, .gradientStroke,
         .merge, .repeater, .round, .stroke, .trim, .transform, .unknown:
      return false
    }
  }

  /// Whether or not this `NEShapeItem` provides a stroke for a set of shapes
  var isStroke: Bool {
    switch type {
    case .stroke, .gradientStroke:
      return true

    case .ellipse, .rectangle, .shape, .star, .group, .gradientFill,
         .merge, .repeater, .round, .fill, .trim, .transform, .unknown:
      return false
    }
  }

  // For any inherited shape items that are affected by scaling (e.g. strokes but not fills),
  // any `NEShapeTransform` in the given child group isn't supposed to be applied to the item.
  // To cancel out the effect of the transform, we can apply an inverse transform to the
  // shape item.
  func scaledCopyForChildGroup(_ childGroup: NEGroup, context: NELayerContext) throws -> NEShapeItem {
    guard
      // Path-drawing items aren't inherited by child groups in this way
      !drawsCGPath,
      // NEStroke widths are affected by scaling, but fill colors aren't.
      // We can expand this to other types of items in the future if necessary.
      let stroke = self as? NEStrokeShapeItem,
      // We only need to handle scaling if there's a `NEShapeTransform` present
      let transform = childGroup.items.first(where: { $0 is NEShapeTransform }) as? NEShapeTransform
    else { return self }

    let newWidth = try NEKeyframes.combined(stroke.width, transform.scale) { strokeWidth, scale -> NELottieVector1D in
      // Since we're applying this scale to a scalar value rather than to a layer,
      // we can only handle cases where the scale is also a scalar (e.g. the same for both x and y)
      try context.compatibilityAssert(scale.x == scale.y, """
      The Core Animation rendering engine doesn't support applying separate x/y scale values \
      (x: \(scale.x), y: \(scale.y)) to this stroke item (\(self.name)).
      """)

      return NELottieVector1D(strokeWidth.value * (100 / scale.x))
    }

    return stroke.copy(width: newWidth)
  }
}

extension Collection {
  /// Splits this collection into two groups, based on the given predicate
  func grouped(by predicate: (Element) -> Bool) -> (trueElements: [Element], falseElements: [Element]) {
    var trueElements = [Element]()
    var falseElements = [Element]()

    for element in self {
      if predicate(element) {
        trueElements.append(element)
      } else {
        falseElements.append(element)
      }
    }

    return (trueElements, falseElements)
  }

  /// Splits this collection into an array of grouping separated by the given separator.
  /// For example, `[A, B, C]` split by `B` returns an array with two elements:
  ///  1. `(grouping: [A], trailingSeparator: B)`
  ///  2. `(grouping: [C], trailingSeparator: nil)`
  func split(whereSeparator separatorPredicate: (Element) -> Bool)
    -> [(grouping: [Element], trailingSeparator: Element?)] {
    guard !isEmpty else { return [] }

    var groupings: [(grouping: [Element], trailingSeparator: Element?)] = []

    for element in self {
      if groupings.isEmpty || groupings.last?.trailingSeparator != nil {
        groupings.append((grouping: [], trailingSeparator: nil))
      }

      if separatorPredicate(element) {
        groupings[groupings.indices.last!].trailingSeparator = element
      } else {
        groupings[groupings.indices.last!].grouping.append(element)
      }
    }

    return groupings
  }
}

// MARK: - NEShapeRenderGroup

/// A group of `NEShapeItem`s that should be rendered together as a single unit
struct NEShapeRenderGroup {
  /// The items in this group that render `CGPath`s.
  /// Valid shape render groups must have at least one path-drawing item.
  var pathItems: [NEShapeItemLayer.Item] = []
  /// NEShape items that modify the appearance of the shapes rendered by this group
  var otherItems: [NEShapeItemLayer.Item] = []
}

extension [NEShapeItemLayer.Item] {
  /// Splits this list of `NEShapeItem`s into groups that should be rendered together as individual units,
  /// plus the remaining items that were not included in any group.
  ///  - groupHasChildGroupsToInheritUnusedItems: whether or not this group has child groups
  ///    that will inherit any items that aren't used as part of a valid render group
  func shapeRenderGroups(groupHasChildGroupsToInheritUnusedItems: Bool)
    -> (validGroups: [NEShapeRenderGroup], unusedItems: [NEShapeItemLayer.Item]) {
    var renderGroups = [NEShapeRenderGroup()]

    for item in self {
      // `renderGroups` is non-empty, so is guaranteed to have a valid end index
      var lastIndex: Int {
        renderGroups.indices.last!
      }

      if item.item.drawsCGPath {
        // Trims should only affect paths that precede them in the group,
        // so if the existing group already has a trim we create a new group for this path item.
        if renderGroups[lastIndex].otherItems.contains(where: { $0.item is NETrim }) {
          renderGroups.append(NEShapeRenderGroup())
        }

        renderGroups[lastIndex].pathItems.append(item)
      }

      // `NEFill` items are unique, because they specifically only apply to _previous_ shapes in a `NEGroup`
      //  - For example, with [NERectangle, NEFill(Red), Circle, NEFill(Blue)], the NERectangle should be Red
      //    but the Circle should be Blue.
      //  - To handle this, we create a new `NEShapeRenderGroup` when we encounter a `NEFill` item
      else if item.item.isFill {
        renderGroups[lastIndex].otherItems.append(item)

        // There are cases where the current render group doesn't have a path-drawing
        // shape item yet, and could just contain this fill. Some examples:
        //  - `[Circle, NEFill(Red), NEFill(Green)]`: In this case, the second fill would
        //    be unused and silently ignored. To avoid this we render the fill using
        //    the shape items from the previous group.
        // - `[Circle, NEFill(Red), NEGroup, NEFill(Green)]`: In this case, the second fill
        //   is inherited and rendered by the child group.
        if
          renderGroups[lastIndex].pathItems.isEmpty,
          !groupHasChildGroupsToInheritUnusedItems,
          lastIndex != renderGroups.indices.first {
          renderGroups[lastIndex].pathItems = renderGroups[lastIndex - 1].pathItems
        }

        // Finalize the group so the fill item doesn't affect following shape items
        renderGroups.append(NEShapeRenderGroup())
      }

      // Other items in the list are applied to all subgroups
      else {
        for index in renderGroups.indices {
          renderGroups[index].otherItems.append(item)
        }
      }
    }

    /// The main thread rendering engine draws each NEStroke and NEFill as a separate `CAShapeLayer`.
    /// As an optimization, we can combine them into a single shape layer when a few conditions are met:
    ///  1. There is at most one stroke and one fill (a `CAShapeLayer` can only render one of each)
    ///  2. The stroke is drawn on top of the fill (the behavior of a `CAShapeLayer`)
    ///  3. The fill and stroke have the same `opacity` animations (since a `CAShapeLayer` can only render
    ///     a single set of `opacity` animations).
    /// Otherwise, each stroke / fill needs to be split into a separate layer.
    renderGroups = renderGroups.flatMap { group -> [NEShapeRenderGroup] in
      let (strokesAndFills, otherItems) = group.otherItems.grouped(by: { $0.item.isFill || $0.item.isStroke })
      let (strokes, fills) = strokesAndFills.grouped(by: { $0.item.isStroke })

      // A `CAShapeLayer` can only draw a single fill and a single stroke
      let hasAtMostOneFill = fills.count <= 1
      let hasAtMostOneStroke = strokes.count <= 1

      // A `CAShapeLayer` can only draw a stroke on top of a fill -- if the fill is supposed to be
      // drawn on top of the stroke, then they have to be rendered as separate layers.
      let strokeDrawnOnTopOfFill: Bool
      if
        let strokeIndex = strokesAndFills.firstIndex(where: { $0.item.isStroke }),
        let fillIndex = strokesAndFills.firstIndex(where: { $0.item.isFill }) {
        strokeDrawnOnTopOfFill = strokeIndex < fillIndex
      } else {
        strokeDrawnOnTopOfFill = false
      }

      // `NEFill` and `NEStroke` items have an `alpha` property that can be animated separately,
      // but each layer only has a single `opacity` property. We can only use a single `CAShapeLayer`
      // when the items have the same `alpha` animations.
      let allAlphaAnimationsAreIdentical = {
        strokesAndFills.allSatisfy { item in
          (item.item as? NEOpacityAnimationModel)?.opacity
            == (strokesAndFills.first?.item as? NEOpacityAnimationModel)?.opacity
        }
      }

      // If all the required conditions are met, this group can be rendered using a single `NEShapeItemLayer`
      if
        hasAtMostOneFill,
        hasAtMostOneStroke,
        strokeDrawnOnTopOfFill,
        allAlphaAnimationsAreIdentical() {
        return [group]
      }

      // Otherwise each stroke / fill needs to be rendered as a separate `NEShapeItemLayer`
      return strokesAndFills.map { strokeOrFill in
        NEShapeRenderGroup(
          pathItems: group.pathItems,
          otherItems: [strokeOrFill] + otherItems
        )
      }
    }

    // All valid render groups must have a path, otherwise the items wouldn't be rendered
    renderGroups = renderGroups.filter { renderGroup in
      !renderGroup.pathItems.isEmpty
    }

    let itemsInValidRenderGroups = NSSet(
      array: renderGroups.lazy
        .flatMap { $0.pathItems + $0.otherItems }
        .map { $0.item })

    // `unusedItems` should only include each original item a single time,
    // and should preserve the existing order
    let itemsNotInValidRenderGroups = filter { item in
      !itemsInValidRenderGroups.contains(item.item)
    }

    return (validGroups: renderGroups, unusedItems: itemsNotInValidRenderGroups)
  }
}
