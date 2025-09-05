//
//  NETabPagingMenuView.swift
//  NEPagingKit
//
//  Copyright (c) 2017 Kazuhiro Hayashi
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit

/**
 A NEPagingMenuViewCell object presents the content for a single menu item when that item is within the paging menu view's visible bounds.
 You can use this class as-is or subclass it to add additional properties and methods. The layout and presentation of cells is managed by the paging menu view.
 */
open class NEPagingMenuViewCell: UIView {
  /**
   The selection state of the cell.

   It is not managed by this class and paging menu view now.
   You can use this property as an utility to manage selected state.
   */
  open var isSelected: Bool = false

  /**
    A string that identifies the purpose of the view.

    The paging menu view identifies and queues reusable views using their reuse identifiers. The paging menu view sets this value when it first creates the view, and the value cannot be changed later. When your data source is prompted to provide a given view, it can use the reuse identifier to dequeue a view of the appropriate type.
   */
  public internal(set) var identifier: String!

  /**
   A index that identifier where the view locate on.

   The paging menu view identifiers and queues reusable views using their reuse identifiers. The index specify current state for the view's position.
   */
  public internal(set) var index: Int!
}

/// A set of methods that provides support for animations associated with a focus view transition.
/// You can use a coordinator object to perform tasks that are related to a transition but that are separate from what the animator objects are doing.
open class PagingMenuFocusViewAnimationCoordinator {
  /// A frame at the start position
  public let beginFrame: CGRect
  /// A frame at the end position
  public let endFrame: CGRect

  fileprivate var animationHandler: ((PagingMenuFocusViewAnimationCoordinator) -> Void)?
  fileprivate var completionHandler: ((Bool) -> Void)?

  public init(beginFrame: CGRect, endFrame: CGRect) {
    self.beginFrame = beginFrame
    self.endFrame = endFrame
  }

  /// Runs the specified animations at the same time as the focus view animations.
  ///
  /// - Parameters:
  ///   - animation: A block containing the animations you want to perform. These animations run in the same context as the focus view animations and therefore have the same default attributes.
  ///   - completion: The block of code to execute after the animation finishes. You may specify nil for this
  open func animateFocusView(alongside animation: @escaping (PagingMenuFocusViewAnimationCoordinator) -> Void, completion: ((Bool) -> Void)?) {
    animationHandler = animation
    completionHandler = completion
  }
}

/// A view that focus menu corresponding to current page.
open class PagingMenuFocusView: UIView {
  open var selectedIndex: Int?

  override public init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}

/**
 An object that adopts the PagingMenuViewDataSource protocol is responsible for providing the data and views required by a paging menu view.
 A data source object represents your app’s data model and vends information to the collection view as needed.
 It also handles the creation and configuration of cells and supplementary views used by the collection view to display your data.
 */
public protocol PagingMenuViewDataSource: AnyObject {
  /// Asks your data source object for the number of sections in the paging menu view.
  ///
  /// - Returns: The number of items in paging menu view.
  func numberOfItemForPagingMenuView() -> Int

  /// Asks your data source object for the cell that corresponds to the specified item in the paging menu view.
  /// You can use this delegate methid like UITableView or UICollectionVew.
  ///
  /// - Parameters:
  ///   - pagingMenuView: The paging menu view requesting this information.
  ///   - index: The index that specifies the location of the item.
  /// - Returns: A configured cell object. You must not return nil from this method.
  func pagingMenuView(pagingMenuView: NETabPagingMenuView, cellForItemAt index: Int) -> NEPagingMenuViewCell

  /// Asks the delegate for the width to use for a row in a specified location.
  ///
  /// - Parameters:
  ///   - pagingMenuView: The paging menu view requesting this information.
  ///   - index: The index that specifies the location of the item.
  /// - Returns: A nonnegative floating-point value that specifies the width (in points) that row should be.
  func pagingMenuView(pagingMenuView: NETabPagingMenuView, widthForItemAt index: Int) -> CGFloat
}

/**
 The PagingMenuViewDelegate protocol defines methods that allow you to manage the selection of items in a paging menu view and to perform actions on those items.
 */
public protocol PagingMenuViewDelegate: AnyObject {
  /// Tells the delegate that the specified row is now selected.
  ///
  /// - Parameters:
  ///   - pagingMenuView: The paging menu view requesting this information.
  ///   - index: The index that specifies the location of the item.
  func pagingMenuView(pagingMenuView: NETabPagingMenuView, didSelectItemAt index: Int)

  /// Notifies the menu view that the frame of its focus view is about to change.
  /// The menu view calls this method before adding a cell to its content. Use this method to detect cell additions, as opposed to monitoring the cell itself to see when it appears.
  ///
  /// - Parameters:
  ///   - pagingMenuView: a menu view object informing the delegate.
  ///   - index: end index
  ///   - coordinator: animator coordinator
  func pagingMenuView(pagingMenuView: NETabPagingMenuView, willAnimateFocusViewTo index: Int, with coordinator: PagingMenuFocusViewAnimationCoordinator)

  /// Tells the delegate that the specified cell is about to be displayed in the menu view.
  ///
  /// - Parameters:
  ///   - pagingMenuView: a menu view object informing the delegate.
  ///   - cell: The cell object being added.
  ///   - index: The index path of the data item that the cell represents.
  func pagingMenuView(pagingMenuView: NETabPagingMenuView, willDisplay cell: NEPagingMenuViewCell, forItemAt index: Int)
}

public extension PagingMenuViewDelegate {
  func pagingMenuView(pagingMenuView: NETabPagingMenuView, didSelectItemAt index: Int) {}
  func pagingMenuView(pagingMenuView: NETabPagingMenuView, willAnimateFocusViewTo index: Int, with coordinator: PagingMenuFocusViewAnimationCoordinator) {}
  func pagingMenuView(pagingMenuView: NETabPagingMenuView, willDisplay cell: NEPagingMenuViewCell, forItemAt index: Int) {}
}

/// Displays menu lists of information and supports selection and paging of the information.
open class NETabPagingMenuView: UIScrollView {
  enum RegisteredCell {
    case nib(nib: UINib)
    case type(type: NEPagingMenuViewCell.Type)
  }

  /// If contentSize.width is not over safe area, paging menu view applys this value to each thecells.
  ///
  /// - center: centering each NEPagingMenuViewCell object.
  /// - left: aligning each NEPagingMenuViewCell object on the left side.
  /// - right: aligning each NEPagingMenuViewCell object on the right side.
  public enum Alignment {
    case center
    case left
    case right

    /// calculation origin.x from max offset.x
    ///
    /// - Parameter maxOffsetX: maximum offset.x on scroll view
    /// - Returns: container view's origin.x
    func calculateOriginX(from maxOffsetX: CGFloat) -> CGFloat {
      switch self {
      case .center:
        return maxOffsetX / 2
      case .left:
        return 0
      case .right:
        return maxOffsetX
      }
    }
  }

  // MARK: - open

  /// The object that acts as the indicator to focus current menu.
  public let focusView = PagingMenuFocusView(frame: .zero)

  /// Returns an array of visible cells currently displayed by the menu view.
  open fileprivate(set) var visibleCells = [NEPagingMenuViewCell]()

  fileprivate var queue = [String: [NEPagingMenuViewCell]]()
  fileprivate var registeredCells = [String: RegisteredCell]()
  fileprivate var widths = [CGFloat]()
  fileprivate(set) var containerView = UIView()
  fileprivate var touchingIndex: Int?

  /// If contentSize.width is not over safe area, paging menu view applys cellAlignment to each the cells. (default: .left)
  open var cellAlignment: Alignment = .left

  /// space setting between cells
  open var cellSpacing: CGFloat = 0

  /// total space between cells
  open var totalSpacing: CGFloat {
    return cellSpacing * numberOfCellSpacing
  }

  /// The object that acts as the data source of the paging menu view.
  open weak var dataSource: PagingMenuViewDataSource?

  /// The object that acts as the delegate of the paging menu view.
  open weak var menuDelegate: PagingMenuViewDelegate?

  override public init(frame: CGRect) {
    super.init(frame: frame)
    configureContainerView()
    configureFocusView()
    configureView()
  }

  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    configureContainerView()
    configureFocusView()
    configureView()
  }

  /// The number of items in the paging menu view.
  open var numberOfItem: Int = 0

  /// Returns an index identifying the row and section at the given point.
  ///
  /// - Parameter point: A point in the local coordinate system of the paging menu view (the paging menu view’s bounds).
  /// - Returns: An index path representing the item associated with point, or nil if the point is out of the bounds of any item.
  open func indexForItem(at point: CGPoint) -> Int? {
    var currentOffsetX: CGFloat = 0
    var resultIndex: Int? = nil
    for (idx, width) in widths.enumerated() {
      let nextOffsetX = currentOffsetX + width
      if (currentOffsetX ..< nextOffsetX) ~= point.x {
        resultIndex = idx
        break
      }
      currentOffsetX = nextOffsetX
    }
    return resultIndex
  }

  /// Returns the paging menu cell at the specified index .
  ///
  /// - Parameter index: The index locating the item in the paging menu view.
  /// - Returns: An object representing a cell of the menu, or nil if the cell is not visible or index is out of range.
  open func cellForItem(at index: Int) -> NEPagingMenuViewCell? {
    return visibleCells.filter { $0.index == index }.first
  }

  /// Reloads the rows and sections of the menu view.
  ///
  /// - Parameters:
  ///   - index: focusing index
  ///   - completion: completion handler
  open func reloadData(with index: Int = 0, completion: ((Bool) -> Void)? = nil) {
    focusView.selectedIndex = index
    contentOffset = .zero
    _reloadData()
    UIView.pk.catchLayoutCompletion(
      layout: { [weak self] in
        self?.scroll(index: index)
      },
      completion: { finish in
        completion?(finish)
      }
    )
  }

  /// Registers a nib object containing a cell with the paging menu view under a specified identifier.
  ///
  /// - Parameters:
  ///   - nib: A nib object that specifies the nib file to use to create the cell.
  ///   - identifier: The reuse identifier for the cell. This parameter must not be nil and must not be an empty string.
  open func register(nib: UINib?, with identifier: String) {
    registeredCells[identifier] = nib.flatMap { .nib(nib: $0) }
  }

  /// Registers a cell type under a specified identifier.
  ///
  /// - Parameters:
  ///   - type: A type that specifies the cell to use to create it.
  ///   - identifier: The reuse identifier for the cell. This parameter must not be nil and must not be an empty string.
  open func register(type: NEPagingMenuViewCell.Type, with identifier: String) {
    registeredCells[identifier] = .type(type: type)
  }

  open func registerFocusView(view: UIView, isBehindCell: Bool = false) {
    view.autoresizingMask = [
      .flexibleWidth,
      .flexibleHeight,
    ]
    view.translatesAutoresizingMaskIntoConstraints = true
    view.frame = CGRect(
      origin: .zero,
      size: focusView.bounds.size
    )
    focusView.addSubview(view)
    focusView.layer.zPosition = isBehindCell ? -1 : 0
  }

  open func registerFocusView(nib: UINib, isBehindCell: Bool = false) {
    let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
    registerFocusView(view: view, isBehindCell: isBehindCell)
  }

  /// Returns a reusable paging menu view cell object for the specified reuse identifier and adds it to the menu.
  ///
  /// - Parameter identifier: A string identifying the cell object to be reused. This parameter must not be nil.
  /// - Returns: The index specifying the location of the cell.
  open func dequeue(with identifier: String) -> NEPagingMenuViewCell {
    if var cells = queue[identifier], !cells.isEmpty {
      let cell = cells.removeFirst()
      queue[identifier] = cells
      cell.identifier = identifier
      return cell
    }

    switch registeredCells[identifier] {
    case let .nib(nib)?:
      let cell = nib.instantiate(withOwner: self, options: nil).first as! NEPagingMenuViewCell
      cell.identifier = identifier
      return cell
    case let .type(type)?:
      let cell = type.init()
      cell.identifier = identifier
      return cell
    default:
      fatalError()
    }
  }

  /// Returns the drawing area for a row identified by index.
  ///
  /// - Parameter index: An index that identifies a item by its index.
  /// - Returns: A rectangle defining the area in which the table view draws the row or right edge rect if index is over the number of items.
  open func rectForItem(at index: Int) -> CGRect {
    guard widths.count > 0 else {
      return CGRect(x: 0, y: 0, width: 0, height: bounds.height)
    }

    guard index < widths.count else {
      let rightEdge = widths.reduce(CGFloat(0)) { sum, width in sum + width } + totalSpacing
      let mostRightWidth = widths[widths.endIndex - 1]
      return CGRect(x: rightEdge, y: 0, width: mostRightWidth, height: bounds.height)
    }

    guard index >= 0 else {
      let leftEdge = -widths[0]
      let mostLeftWidth = widths[0]
      return CGRect(x: leftEdge, y: 0, width: mostLeftWidth, height: bounds.height)
    }

    var x = (0 ..< index).reduce(0) { sum, idx in
      sum + widths[idx]
    }
    x += cellSpacing * CGFloat(index)
    return CGRect(x: x, y: 0, width: widths[index], height: bounds.height)
  }

  open func invalidateLayout() {
    guard let dataSource = dataSource else {
      return
    }

    widths = []
    var containerWidth: CGFloat = 0
    for index in 0 ..< numberOfItem {
      let width = dataSource.pagingMenuView(pagingMenuView: self, widthForItemAt: index)
      widths.append(width)
      containerWidth += width
    }
    containerWidth += totalSpacing
    contentSize = CGSize(width: containerWidth, height: bounds.height)
    containerView.frame = CGRect(origin: .zero, size: contentSize)

    alignEachVisibleCell()
  }

  override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
    if keyPath == #keyPath(UIView.bounds), let newFrame = change?[.newKey] as? CGRect, let oldFrame = change?[.oldKey] as? CGRect, newFrame.height != oldFrame.height {
      adjustComponentHeights(from: newFrame.height)
    }
  }

  /// Scrolls a specific index of the menu so that it is visible in the receiver.
  ///
  /// - Parameters:
  ///   - index: A index defining an menu of the menu view.
  ///   - percent: A rate that transit from the index. (percent ranges from -0.5 to 0.5.)
  open func scroll(index: Int, percent: CGFloat = 0) {
    // Specification in this method is difference from the interface specification.
    let (index, percent) = correctScrollIndexAndPercent(index: index, percent: percent)

    let rightIndex = index + 1
    let leftFrame = rectForItem(at: index)
    let rightFrame = rectForItem(at: rightIndex)

    let width = (rightFrame.width - leftFrame.width) * percent + leftFrame.width
    focusView.frame.size = CGSize(width: width, height: bounds.height)

    let centerPointX = leftFrame.midX + (rightFrame.midX - leftFrame.midX) * percent
    let offsetX = centerPointX - bounds.width / 2
    let normaizedOffsetX = min(max(minContentOffsetX, offsetX), maxContentOffsetX)
    focusView.center = CGPoint(x: centerPointX, y: center.y)

    let expectedIndex = (focusView.center.x < leftFrame.maxX) ? index : rightIndex
    focusView.selectedIndex = max(0, min(expectedIndex, numberOfItem - 1))

    contentOffset = CGPoint(x: normaizedOffsetX, y: 0)

    if let index = focusView.selectedIndex {
      visibleCells.selectCell(with: index)
    }
  }

  /// Scrolls a specific index of the menu so that it is visible in the receiver and calls handler when finishing scroll.
  ///
  /// - Parameters:
  ///   - index: A index defining an menu of the menu view.
  ///   - completeHandler: handler called after completion
  open func scroll(index: Int, completeHandler: @escaping (Bool) -> Void) {
    let itemFrame = rectForItem(at: index)

    let offsetX = itemFrame.midX - bounds.width / 2
    let offset = CGPoint(x: min(max(minContentOffsetX, offsetX), maxContentOffsetX), y: 0)

    focusView.selectedIndex = index
    visibleCells.selectCell(with: index)

    let coordinator = PagingMenuFocusViewAnimationCoordinator(beginFrame: focusView.frame, endFrame: itemFrame)
    menuDelegate?.pagingMenuView(pagingMenuView: self, willAnimateFocusViewTo: index, with: coordinator)
    UIView.perform(.delete, on: [], options: UIView.AnimationOptions(rawValue: 0), animations: { [weak self] in
      guard let _self = self else { return }
      _self.contentOffset = offset
      _self.focusView.frame = itemFrame
      _self.focusView.layoutIfNeeded()
      coordinator.animationHandler?(coordinator)
    }, completion: { finished in
      coordinator.completionHandler?(finished)
      completeHandler(finished)
    })
  }

  // MARK: - Internal

  var contentSafeAreaInsets: UIEdgeInsets {
    safeAreaInsets
  }

  var safedViewWidth: CGFloat {
    return bounds.width - contentSafeAreaInsets.horizontal
  }

  var hasScrollableArea: Bool {
    return safedViewWidth < contentSize.width
  }

  var maxContentOffsetX: CGFloat {
    return max(bounds.width, contentSize.width + contentSafeAreaInsets.right + contentInset.right) - bounds.width
  }

  var minContentOffsetX: CGFloat {
    return -(contentSafeAreaInsets.left + contentInset.left)
  }

  // max offset inside safe area
  var maxSafedOffset: CGFloat {
    return safedViewWidth - containerView.frame.width
  }

  // MARK: - Private

  /// Reloads the rows and sections of the menu view.
  private func _reloadData() {
    guard let dataSource = dataSource else {
      return
    }

    visibleCells.forEach { $0.removeFromSuperview() }
    visibleCells = []

    numberOfItem = dataSource.numberOfItemForPagingMenuView()

    invalidateLayout()

    setNeedsLayout()
    layoutIfNeeded()
  }

  private func configureContainerView() {
    containerView.frame = bounds
    containerView.center = center
    addSubview(containerView)
  }

  private func configureFocusView() {
    focusView.frame = CGRect(x: 0, y: 0, width: 1, height: 1) // to avoid ignoring focus view's layout
    containerView.addSubview(focusView)
  }

  private func configureView() {
    backgroundColor = .clear
    addObserver(self, forKeyPath: #keyPath(UIView.bounds), options: [.old, .new], context: nil)
  }

  private var numberOfCellSpacing: CGFloat {
    return max(CGFloat(numberOfItem - 1), 0)
  }

  private func recenterIfNeeded() {
    let currentOffset = contentOffset
    let contentWidth = contentSize.width
    let centerOffsetX = (contentWidth - bounds.size.width) / 2
    let distanceFromCenter = abs(currentOffset.x - centerOffsetX)

    if distanceFromCenter > (contentWidth - bounds.size.width) / 4 {
      contentOffset = CGPoint(x: centerOffsetX, y: currentOffset.y)

      for cell in visibleCells {
        var center = containerView.convert(cell.center, to: self)
        center.x += centerOffsetX - currentOffset.x
        cell.center = convert(center, to: containerView)
      }
    }
  }

  private func alignEachVisibleCell() {
    for cell in visibleCells {
      let leftEdge = (0 ..< cell.index).reduce(CGFloat(0)) { sum, idx in sum + widths[idx] + cellSpacing }
      cell.frame.origin = CGPoint(x: leftEdge, y: 0)
      cell.frame.size = CGSize(width: widths[cell.index], height: containerView.bounds.height)
    }
  }

  private func adjustComponentHeights(from newHeight: CGFloat) {
    contentSize.height = newHeight
    containerView.frame.size.height = newHeight
    visibleCells.forEach { $0.frame.size.height = newHeight }
    focusView.frame.size.height = newHeight
  }

  @discardableResult
  private func placeNewCellOnRight(with rightEdge: CGFloat, index: Int, dataSource: PagingMenuViewDataSource) -> CGFloat {
    let nextIndex = (index + 1) % numberOfItem
    let cell = dataSource.pagingMenuView(pagingMenuView: self, cellForItemAt: nextIndex)
    cell.isSelected = (focusView.selectedIndex == nextIndex)
    cell.index = nextIndex
    containerView.insertSubview(cell, at: 0)

    visibleCells.append(cell)
    cell.frame.origin = CGPoint(x: rightEdge, y: 0)
    cell.frame.size = CGSize(width: widths[nextIndex], height: containerView.bounds.height)

    menuDelegate?.pagingMenuView(pagingMenuView: self, willDisplay: cell, forItemAt: nextIndex)

    return cell.frame.maxX
  }

  private func placeNewCellOnLeft(with leftEdge: CGFloat, index: Int, dataSource: PagingMenuViewDataSource) -> CGFloat {
    let nextIndex: Int
    if index == 0 {
      nextIndex = numberOfItem - 1
    } else {
      nextIndex = (index - 1) % numberOfItem
    }
    let cell = dataSource.pagingMenuView(pagingMenuView: self, cellForItemAt: nextIndex)
    cell.isSelected = (focusView.selectedIndex == nextIndex)
    cell.index = nextIndex

    containerView.insertSubview(cell, at: 0)

    visibleCells.insert(cell, at: 0)
    cell.frame.size = CGSize(width: widths[nextIndex], height: containerView.bounds.height)
    cell.frame.origin = CGPoint(x: leftEdge - widths[nextIndex] - cellSpacing, y: 0)

    menuDelegate?.pagingMenuView(pagingMenuView: self, willDisplay: cell, forItemAt: nextIndex)

    return cell.frame.minX
  }

  private func tileCell(from minX: CGFloat, to maxX: CGFloat) {
    guard let dataSource = dataSource, numberOfItem > 0 else {
      return
    }

    if visibleCells.isEmpty {
      placeNewCellOnRight(with: minX, index: numberOfItem - 1, dataSource: dataSource)
    }

    var lastCell = visibleCells.last
    var rightEdge = lastCell.flatMap { $0.frame.maxX + cellSpacing }
    while let _lastCell = lastCell, let _rightEdge = rightEdge,
          _rightEdge < maxX, (0 ..< numberOfItem) ~= _lastCell.index + 1 {
      rightEdge = placeNewCellOnRight(with: _rightEdge, index: _lastCell.index, dataSource: dataSource) + cellSpacing
      lastCell = visibleCells.last
    }

    var firstCell = visibleCells.first
    var leftEdge = firstCell?.frame.minX
    while let _firstCell = firstCell, let _leftEdge = leftEdge,
          _leftEdge > minX, (0 ..< numberOfItem) ~= _firstCell.index - 1 {
      leftEdge = placeNewCellOnLeft(with: _leftEdge, index: _firstCell.index, dataSource: dataSource)
      firstCell = visibleCells.first
    }

    while let lastCell = visibleCells.last, lastCell.frame.minX > maxX {
      lastCell.removeFromSuperview()
      let recycleCell = visibleCells.removeLast()

      if let cells = queue[recycleCell.identifier] {
        queue[recycleCell.identifier] = cells + [recycleCell]
      } else {
        queue[recycleCell.identifier] = [recycleCell]
      }
    }

    while let firstCell = visibleCells.first, firstCell.frame.maxX < minX {
      firstCell.removeFromSuperview()
      let recycleCell = visibleCells.removeFirst()

      if let cells = queue[recycleCell.identifier] {
        queue[recycleCell.identifier] = cells + [recycleCell]
      } else {
        queue[recycleCell.identifier] = [recycleCell]
      }
    }
  }

  /// If contentSize.width is not over safe area, paging menu view applys cellAlignment to each the cells.
  private func alignContainerViewIfNeeded() {
    guard let expectedOriginX = getExpectedAlignmentPositionXIfNeeded() else {
      return
    }

    if expectedOriginX != containerView.frame.origin.x {
      containerView.frame.origin.x = expectedOriginX
    }
  }

  /// get correct origin X of menu view's container view, If menu view is scrollable.
  func getExpectedAlignmentPositionXIfNeeded() -> CGFloat? {
    let expectedOriginX = cellAlignment.calculateOriginX(from: maxSafedOffset)
    guard !hasScrollableArea else {
      return nil
    }
    return expectedOriginX
  }

  /// correct a page index as starting index is always left side.
  ///
  /// - Parameters:
  ///   - index: current page index defined in NEPagingKit
  ///   - percent: current percent defined in NEPagingKit
  /// - Returns: index and percent
  private func correctScrollIndexAndPercent(index: Int, percent: CGFloat) -> (index: Int, percent: CGFloat) {
    let pagingPositionIsLeftSide = (percent < 0)
    if pagingPositionIsLeftSide {
      if index == 0 {
        return (index: index, percent: percent)
      } else {
        return (index: max(index - 1, 0), percent: percent + 1)
      }
    } else {
      return (index: index, percent: percent)
    }
  }

  // MARK: - Life Cycle

  override open func layoutSubviews() {
    super.layoutSubviews()

    if numberOfItem != 0 {
      let visibleBounds = convert(bounds, to: containerView)
      let extraOffset = visibleBounds.width / 2
      tileCell(
        from: max(0, visibleBounds.minX - extraOffset),
        to: min(contentSize.width, visibleBounds.maxX + extraOffset)
      )
    }

    alignContainerViewIfNeeded()
  }

  @available(iOS 11.0, *)
  override open func safeAreaInsetsDidChange() {
    super.safeAreaInsetsDidChange()
    alignEachVisibleCell()
  }

  deinit {
    removeObserver(self, forKeyPath: #keyPath(UIView.bounds))
  }
}

// MARK: - Touch Event

extension NETabPagingMenuView {
  override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    guard let touchPoint = touches.first.flatMap({ $0.location(in: containerView) }) else { return }
    touchingIndex = visibleCells.filter { cell in cell.frame.contains(touchPoint) }.first?.index
  }

  override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    defer {
      touchingIndex = nil
    }

    guard let touchingIndex = touchingIndex,
          let touchPoint = touches.first.flatMap({ $0.location(in: containerView) }),
          let touchEndedIndex = visibleCells.filter({ $0.frame.contains(touchPoint) }).first?.index else { return }

    if touchingIndex == touchEndedIndex {
      menuDelegate?.pagingMenuView(pagingMenuView: self, didSelectItemAt: touchingIndex)
    }
  }

  override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesCancelled(touches, with: event)
    touchingIndex = nil
  }
}

// MARK: - Array

private extension Array where Element == NEPagingMenuViewCell {
  func resetSelected() {
    forEach { $0.isSelected = false }
  }

  @discardableResult
  func selectCell(with index: Int) -> Int? {
    resetSelected()
    let selectedCell = filter { $0.index == index }.first
    selectedCell?.isSelected = true
    return selectedCell?.index
  }
}
