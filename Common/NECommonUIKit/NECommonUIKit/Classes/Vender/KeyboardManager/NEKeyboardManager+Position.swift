
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// import Foundation - UIKit contains Foundation
import UIKit

@available(iOSApplicationExtension, unavailable)
public extension NEKeyboardManager {
  private enum AssociatedKeys {
    static var movedDistance = "movedDistance"
    static var movedDistanceChanged = "movedDistanceChanged"
    static var lastScrollView = "lastScrollView"
    static var startingContentOffset = "startingContentOffset"
    static var startingScrollIndicatorInsets = "startingScrollIndicatorInsets"
    static var startingContentInsets = "startingContentInsets"
    static var startingTextViewContentInsets = "startingTextViewContentInsets"
    static var startingTextViewScrollIndicatorInsets = "startingTextViewScrollIndicatorInsets"
    static var isTextViewContentInsetChanged = "isTextViewContentInsetChanged"
    static var hasPendingAdjustRequest = "hasPendingAdjustRequest"
  }

  /**
   moved distance to the top used to maintain distance between keyboard and textField. Most of the time this will be a positive value.
   */
  @objc private(set) var movedDistance: CGFloat {
    get {
      objc_getAssociatedObject(self, &AssociatedKeys.movedDistance) as? CGFloat ?? 0.0
    }
    set(newValue) {
      objc_setAssociatedObject(
        self,
        &AssociatedKeys.movedDistance,
        newValue,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
      movedDistanceChanged?(movedDistance)
    }
  }

  /**
   Will be called then movedDistance will be changed
    */
  @objc var movedDistanceChanged: ((CGFloat) -> Void)? {
    get {
      objc_getAssociatedObject(self,
                               &AssociatedKeys.movedDistanceChanged) as? ((CGFloat) -> Void)
    }
    set(newValue) {
      objc_setAssociatedObject(
        self,
        &AssociatedKeys.movedDistanceChanged,
        newValue,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
      movedDistanceChanged?(movedDistance)
    }
  }

  /** Variable to save lastScrollView that was scrolled. */
  internal weak var lastScrollView: UIScrollView? {
    get {
      (objc_getAssociatedObject(
        self,
        &AssociatedKeys.lastScrollView
      ) as? WeakObjectContainer)?.object as? UIScrollView
    }
    set(newValue) {
      objc_setAssociatedObject(
        self,
        &AssociatedKeys.lastScrollView,
        WeakObjectContainer(object: newValue),
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }

  /** LastScrollView's initial contentOffset. */
  internal var startingContentOffset: CGPoint {
    get {
      objc_getAssociatedObject(self, &AssociatedKeys.startingContentOffset) as? CGPoint ??
        NEKeyboardManager.kNECGPointInvalid
    }
    set(newValue) {
      objc_setAssociatedObject(
        self,
        &AssociatedKeys.startingContentOffset,
        newValue,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }

  /** LastScrollView's initial scrollIndicatorInsets. */
  internal var startingScrollIndicatorInsets: UIEdgeInsets {
    get {
      objc_getAssociatedObject(
        self,
        &AssociatedKeys.startingScrollIndicatorInsets
      ) as? UIEdgeInsets ?? .init()
    }
    set(newValue) {
      objc_setAssociatedObject(
        self,
        &AssociatedKeys.startingScrollIndicatorInsets,
        newValue,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }

  /** LastScrollView's initial contentInsets. */
  internal var startingContentInsets: UIEdgeInsets {
    get {
      objc_getAssociatedObject(
        self,
        &AssociatedKeys.startingContentInsets
      ) as? UIEdgeInsets ??
        .init()
    }
    set(newValue) {
      objc_setAssociatedObject(
        self,
        &AssociatedKeys.startingContentInsets,
        newValue,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }

  /** used to adjust contentInset of UITextView. */
  internal var startingTextViewContentInsets: UIEdgeInsets {
    get {
      objc_getAssociatedObject(
        self,
        &AssociatedKeys.startingTextViewContentInsets
      ) as? UIEdgeInsets ?? .init()
    }
    set(newValue) {
      objc_setAssociatedObject(
        self,
        &AssociatedKeys.startingTextViewContentInsets,
        newValue,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }

  /** used to adjust scrollIndicatorInsets of UITextView. */
  internal var startingTextViewScrollIndicatorInsets: UIEdgeInsets {
    get {
      objc_getAssociatedObject(
        self,
        &AssociatedKeys.startingTextViewScrollIndicatorInsets
      ) as? UIEdgeInsets ?? .init()
    }
    set(newValue) {
      objc_setAssociatedObject(
        self,
        &AssociatedKeys.startingTextViewScrollIndicatorInsets,
        newValue,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }

  /** used with textView to detect a textFieldView contentInset is changed or not. (Bug ID: #92) */
  internal var isTextViewContentInsetChanged: Bool {
    get {
      objc_getAssociatedObject(
        self,
        &AssociatedKeys.isTextViewContentInsetChanged
      ) as? Bool ??
        false
    }
    set(newValue) {
      objc_setAssociatedObject(
        self,
        &AssociatedKeys.isTextViewContentInsetChanged,
        newValue,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }

  /** To know if we have any pending request to adjust view position. */
  private var hasPendingAdjustRequest: Bool {
    get {
      objc_getAssociatedObject(self, &AssociatedKeys.hasPendingAdjustRequest) as? Bool ??
        false
    }
    set(newValue) {
      objc_setAssociatedObject(
        self,
        &AssociatedKeys.hasPendingAdjustRequest,
        newValue,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }

  internal func optimizedAdjustPosition() {
    if !hasPendingAdjustRequest {
      hasPendingAdjustRequest = true
      OperationQueue.main.addOperation {
        self.adjustPosition()
        self.hasPendingAdjustRequest = false
      }
    }
  }

  /* Adjusting RootViewController's frame according to interface orientation. */
  private func adjustPosition() {
    //  We are unable to get textField object while keyboard showing on WKWebView's textField.  (Bug
    //  ID: #11)
    guard hasPendingAdjustRequest,
          let textFieldView = textFieldView,
          let rootController = textFieldView.neParentContainerViewController(),
          let window = keyWindow(),
          let textFieldViewRectInWindow = textFieldView.superview?.convert(
            textFieldView.frame,
            to: window
          ),
          let textFieldViewRectInRootSuperview = textFieldView.superview?.convert(
            textFieldView.frame,
            to: rootController.view?.superview
          ) else {
      return
    }

    let startTime = CACurrentMediaTime()
    showLog("****** \(#function) started ******", indentation: 1)

    //  Getting RootViewOrigin.
    var rootViewOrigin = rootController.view.frame.origin

    // Maintain keyboardDistanceFromTextField
    var specialKeyboardDistanceFromTextField = textFieldView.neKeyboardDistanceFromTextField

    if let searchBar = textFieldView.neTextFieldSearchBar() {
      specialKeyboardDistanceFromTextField = searchBar.neKeyboardDistanceFromTextField
    }

    let newKeyboardDistanceFromTextField =
      (specialKeyboardDistanceFromTextField == kNEUseDefaultKeyboardDistance) ?
      keyboardDistanceFromTextField : specialKeyboardDistanceFromTextField

    var kbSize = keyboardFrame.size

    do {
      var kbFrame = keyboardFrame

      kbFrame.origin.y -= newKeyboardDistanceFromTextField
      kbFrame.size.height += newKeyboardDistanceFromTextField

      // Calculating actual keyboard covered size respect to window, keyboard frame may be different when
      // hardware keyboard is attached (Bug ID: #469) (Bug ID: #381) (Bug ID: #1506)
      let intersectRect = kbFrame.intersection(window.frame)

      if intersectRect.isNull {
        kbSize = CGSize(width: kbFrame.size.width, height: 0)
      } else {
        kbSize = intersectRect.size
      }
    }

    let statusBarHeight: CGFloat

    #if swift(>=5.1)
      if #available(iOS 13, *) {
        statusBarHeight = window.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
      } else {
        statusBarHeight = UIApplication.shared.statusBarFrame.height
      }
    #else
      statusBarHeight = UIApplication.shared.statusBarFrame.height
    #endif

    let navigationBarAreaHeight: CGFloat = statusBarHeight +
      (rootController.navigationController?.navigationBar.frame.height ?? 0)
    let layoutAreaHeight: CGFloat = rootController.view.layoutMargins.bottom

    let topLayoutGuide: CGFloat = max(navigationBarAreaHeight, layoutAreaHeight) + 5
    let bottomLayoutGuide: CGFloat = (textFieldView is UIScrollView && textFieldView
      .responds(to: #selector(getter: UITextView.isEditable))) ? 0 : rootController.view
          .layoutMargins
          .bottom

    var move: CGFloat = min(
      textFieldViewRectInRootSuperview.minY - topLayoutGuide,
      textFieldViewRectInWindow.maxY - (window.frame.height - kbSize.height) + bottomLayoutGuide
    )

    showLog("Need to move: \(move)")

    var superScrollView: UIScrollView?
    var superView = textFieldView.neSuperviewOfClassType(UIScrollView.self) as? UIScrollView

    // Getting UIScrollView whose scrolling is enabled.    //  (Bug ID: #285)
    while let view = superView {
      if view.isScrollEnabled, !view.neShouldIgnoreScrollingAdjustment {
        superScrollView = view
        break
      } else {
        //  Getting it's superScrollView.   //  (Enhancement ID: #21, #24)
        superView = view.neSuperviewOfClassType(UIScrollView.self) as? UIScrollView
      }
    }

    // If there was a lastScrollView.    //  (Bug ID: #34)
    if let lastScrollView = lastScrollView {
      // If we can't find current superScrollView, then setting lastScrollView to it's original form.
      if superScrollView == nil {
        if lastScrollView.contentInset != startingContentInsets {
          showLog("Restoring contentInset to: \(startingContentInsets)")
          UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            options: animationCurve,
            animations: { () in
              lastScrollView.contentInset = self.startingContentInsets
              lastScrollView.scrollIndicatorInsets = self.startingScrollIndicatorInsets
            }
          )
        }

        if lastScrollView.neShouldRestoreScrollViewContentOffset,
           !lastScrollView.contentOffset.equalTo(startingContentOffset) {
          showLog("Restoring contentOffset to: \(startingContentOffset)")

          let animatedContentOffset = textFieldView.neSuperviewOfClassType(
            UIStackView.self,
            belowView: lastScrollView
          ) != nil //  (Bug ID: #1365, #1508, #1541)

          if animatedContentOffset {
            lastScrollView.setContentOffset(
              startingContentOffset,
              animated: UIView.areAnimationsEnabled
            )
          } else {
            lastScrollView.contentOffset = startingContentOffset
          }
        }

        startingContentInsets = UIEdgeInsets()
        startingScrollIndicatorInsets = UIEdgeInsets()
        startingContentOffset = CGPoint.zero
        self.lastScrollView = nil
      } else if superScrollView !=
        lastScrollView {
        // If both scrollView's are different, then reset lastScrollView to it's original frame and
        // setting current scrollView as last scrollView.
        if lastScrollView.contentInset != startingContentInsets {
          showLog("Restoring contentInset to: \(startingContentInsets)")
          UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            options: animationCurve,
            animations: { () in
              lastScrollView.contentInset = self.startingContentInsets
              lastScrollView.scrollIndicatorInsets = self.startingScrollIndicatorInsets
            }
          )
        }

        if lastScrollView.neShouldRestoreScrollViewContentOffset,
           !lastScrollView.contentOffset.equalTo(startingContentOffset) {
          showLog("Restoring contentOffset to: \(startingContentOffset)")

          let animatedContentOffset = textFieldView.neSuperviewOfClassType(
            UIStackView.self,
            belowView: lastScrollView
          ) != nil //  (Bug ID: #1365, #1508, #1541)

          if animatedContentOffset {
            lastScrollView.setContentOffset(
              startingContentOffset,
              animated: UIView.areAnimationsEnabled
            )
          } else {
            lastScrollView.contentOffset = startingContentOffset
          }
        }

        self.lastScrollView = superScrollView
        if let scrollView = superScrollView {
          startingContentInsets = scrollView.contentInset
          startingContentOffset = scrollView.contentOffset

          #if swift(>=5.1)
            if #available(iOS 11.1, *) {
              startingScrollIndicatorInsets = scrollView.verticalScrollIndicatorInsets
            } else {
              startingScrollIndicatorInsets = scrollView.scrollIndicatorInsets
            }
          #else
            startingScrollIndicatorInsets = scrollView.scrollIndicatorInsets
          #endif
        }

        showLog(
          "Saving ScrollView New contentInset: \(startingContentInsets) and contentOffset: \(startingContentOffset)"
        )
      }
      // Else the case where superScrollView == lastScrollView means we are on same scrollView after
      // switching to different textField. So doing nothing, going ahead
    } else if let unwrappedSuperScrollView = superScrollView {
      // If there was no lastScrollView and we found a current scrollView. then setting it as
      // lastScrollView.
      lastScrollView = unwrappedSuperScrollView
      startingContentInsets = unwrappedSuperScrollView.contentInset
      startingContentOffset = unwrappedSuperScrollView.contentOffset

      #if swift(>=5.1)
        if #available(iOS 11.1, *) {
          startingScrollIndicatorInsets = unwrappedSuperScrollView
            .verticalScrollIndicatorInsets
        } else {
          startingScrollIndicatorInsets = unwrappedSuperScrollView.scrollIndicatorInsets
        }
      #else
        startingScrollIndicatorInsets = unwrappedSuperScrollView.scrollIndicatorInsets
      #endif

      showLog(
        "Saving ScrollView contentInset: \(startingContentInsets) and contentOffset: \(startingContentOffset)"
      )
    }

    //  Special case for ScrollView.
    //  If we found lastScrollView then setting it's contentOffset to show textField.
    if let lastScrollView = lastScrollView {
      // Saving
      var lastView = textFieldView
      var superScrollView = self.lastScrollView

      while let scrollView = superScrollView {
        var shouldContinue = false

        if move > 0 {
          shouldContinue = move >
            (-scrollView.contentOffset.y - scrollView.contentInset.top)

        } else if let tableView = scrollView
          .neSuperviewOfClassType(UITableView.self) as? UITableView {
          shouldContinue = scrollView.contentOffset.y > 0

          if shouldContinue,
             let tableCell = textFieldView
             .neSuperviewOfClassType(UITableViewCell.self) as? UITableViewCell,
             let indexPath = tableView.indexPath(for: tableCell),
             let previousIndexPath = tableView.nePreviousIndexPath(of: indexPath) {
            let previousCellRect = tableView.rectForRow(at: previousIndexPath)
            if !previousCellRect.isEmpty {
              let previousCellRectInRootSuperview = tableView.convert(
                previousCellRect,
                to: rootController.view.superview
              )

              move = min(0, previousCellRectInRootSuperview.maxY - topLayoutGuide)
            }
          }
        } else if let collectionView = scrollView
          .neSuperviewOfClassType(UICollectionView.self) as? UICollectionView {
          shouldContinue = scrollView.contentOffset.y > 0

          if shouldContinue,
             let collectionCell = textFieldView
             .neSuperviewOfClassType(UICollectionViewCell.self) as? UICollectionViewCell,
             let indexPath = collectionView.indexPath(for: collectionCell),
             let previousIndexPath = collectionView.nePreviousIndexPath(of: indexPath),
             let attributes = collectionView
             .layoutAttributesForItem(at: previousIndexPath) {
            let previousCellRect = attributes.frame
            if !previousCellRect.isEmpty {
              let previousCellRectInRootSuperview = collectionView.convert(
                previousCellRect,
                to: rootController.view.superview
              )

              move = min(0, previousCellRectInRootSuperview.maxY - topLayoutGuide)
            }
          }
        } else {
          shouldContinue = textFieldViewRectInRootSuperview.origin.y < topLayoutGuide

          if shouldContinue {
            move = min(0, textFieldViewRectInRootSuperview.origin.y - topLayoutGuide)
          }
        }

        // Looping in upper hierarchy until we don't found any scrollView in it's upper hirarchy till
        // UIWindow object.
        if shouldContinue {
          var tempScrollView = scrollView
            .neSuperviewOfClassType(UIScrollView.self) as? UIScrollView
          var nextScrollView: UIScrollView?
          while let view = tempScrollView {
            if view.isScrollEnabled, !view.neShouldIgnoreScrollingAdjustment {
              nextScrollView = view
              break
            } else {
              tempScrollView = view
                .neSuperviewOfClassType(UIScrollView.self) as? UIScrollView
            }
          }

          // Getting lastViewRect.
          if let lastViewRect = lastView.superview?.convert(
            lastView.frame,
            to: scrollView
          ) {
            // Calculating the expected Y offset from move and scrollView's contentOffset.
            var shouldOffsetY = scrollView.contentOffset.y - min(
              scrollView.contentOffset.y,
              -move
            )

            // Rearranging the expected Y offset according to the view.
            shouldOffsetY = min(shouldOffsetY, lastViewRect.origin.y)

            // [_textFieldView isKindOfClass:[UITextView class]] If is a UITextView type
            // nextScrollView == nil    If processing scrollView is last scrollView in upper hierarchy (there is
            // no other scrollView upper hierrchy.)
            // [_textFieldView isKindOfClass:[UITextView class]] If is a UITextView type
            // shouldOffsetY >= 0     shouldOffsetY must be greater than in order to keep distance from
            // navigationBar (Bug ID: #92)
            if textFieldView is UIScrollView, textFieldView
              .responds(to: #selector(getter: UITextView.isEditable)),
              nextScrollView == nil,
              shouldOffsetY >= 0 {
              //  Converting NERectangle according to window bounds.
              if let currentTextFieldViewRect = textFieldView.superview?.convert(
                textFieldView.frame,
                to: window
              ) {
                // Calculating expected fix distance which needs to be managed from navigation bar
                let expectedFixDistance = currentTextFieldViewRect
                  .minY - topLayoutGuide

                // Now if expectedOffsetY (superScrollView.contentOffset.y + expectedFixDistance) is
                // lower than current shouldOffsetY, which means we're in a position where navigationBar
                // up and hide, then reducing shouldOffsetY with expectedOffsetY
                // (superScrollView.contentOffset.y + expectedFixDistance)
                shouldOffsetY = min(
                  shouldOffsetY,
                  scrollView.contentOffset.y + expectedFixDistance
                )

                // Setting move to 0 because now we don't want to move any view anymore (All will be
                // managed by our contentInset logic.
                move = 0
              } else {
                // Subtracting the Y offset from the move variable, because we are going to change scrollView's
                // contentOffset.y to shouldOffsetY.
                move -= (shouldOffsetY - scrollView.contentOffset.y)
              }
            } else {
              // Subtracting the Y offset from the move variable, because we are going to change scrollView's
              // contentOffset.y to shouldOffsetY.
              move -= (shouldOffsetY - scrollView.contentOffset.y)
            }

            let newContentOffset = CGPoint(
              x: scrollView.contentOffset.x,
              y: shouldOffsetY
            )

            if scrollView.contentOffset.equalTo(newContentOffset) == false {
              showLog(
                "old contentOffset: \(scrollView.contentOffset) new contentOffset: \(newContentOffset)"
              )
              showLog("Remaining Move: \(move)")

              // Getting problem while using `setContentOffset:animated:`, So I used animation API.
              UIView.animate(
                withDuration: animationDuration,
                delay: 0,
                options: animationCurve,
                animations: { () in
                  let animatedContentOffset = textFieldView.neSuperviewOfClassType(
                    UIStackView.self,
                    belowView: scrollView
                  ) != nil //  (Bug ID: #1365, #1508, #1541)

                  if animatedContentOffset {
                    scrollView.setContentOffset(
                      newContentOffset,
                      animated: UIView.areAnimationsEnabled
                    )
                  } else {
                    scrollView.contentOffset = newContentOffset
                  }
                },
                completion: { _ in
                  if scrollView is UITableView || scrollView is UICollectionView {
                    // This will update the next/previous states
                    self.addToolbarIfRequired()
                  }
                }
              )
            }
          }

          //  Getting next lastView & superScrollView.
          lastView = scrollView
          superScrollView = nextScrollView
        } else {
          move = 0
          break
        }
      }

      // Updating contentInset
      if let lastScrollViewRect = lastScrollView.superview?.convert(
        lastScrollView.frame,
        to: window
      ),
        lastScrollView.neShouldIgnoreContentInsetAdjustment == false {
        var bottomInset: CGFloat = (kbSize.height) -
          (window.frame.height - lastScrollViewRect.maxY)
        var bottomScrollIndicatorInset = bottomInset - newKeyboardDistanceFromTextField

        // Update the insets so that the scroll vew doesn't shift incorrectly when the offset is near the
        // bottom of the scroll view.
        bottomInset = max(startingContentInsets.bottom, bottomInset)
        bottomScrollIndicatorInset = max(
          startingScrollIndicatorInsets.bottom,
          bottomScrollIndicatorInset
        )

        if #available(iOS 11, *) {
          bottomInset -= lastScrollView.safeAreaInsets.bottom
          bottomScrollIndicatorInset -= lastScrollView.safeAreaInsets.bottom
        }

        var movedInsets = lastScrollView.contentInset
        movedInsets.bottom = bottomInset

        if lastScrollView.contentInset != movedInsets {
          showLog(
            "old ContentInset: \(lastScrollView.contentInset) new ContentInset: \(movedInsets)"
          )

          UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            options: animationCurve,
            animations: { () in
              lastScrollView.contentInset = movedInsets

              var newScrollIndicatorInset: UIEdgeInsets

              #if swift(>=5.1)
                if #available(iOS 11.1, *) {
                  newScrollIndicatorInset = lastScrollView.verticalScrollIndicatorInsets
                } else {
                  newScrollIndicatorInset = lastScrollView.scrollIndicatorInsets
                }
              #else
                newScrollIndicatorInset = lastScrollView.scrollIndicatorInsets
              #endif

              newScrollIndicatorInset.bottom = bottomScrollIndicatorInset
              lastScrollView.scrollIndicatorInsets = newScrollIndicatorInset
            }
          )
        }
      }
    }
    // Going ahead. No else if.

    // Special case for UITextView(Readjusting textView.contentInset when textView hight is too big to fit
    // on screen)
    // _lastScrollView       If not having inside any scrollView, (now contentInset manages the full screen
    // textView.
    // [_textFieldView isKindOfClass:[UITextView class]] If is a UITextView type
    if let textView = textFieldView as? UIScrollView, textView.isScrollEnabled,
       textFieldView.responds(to: #selector(getter: UITextView.isEditable)) {
      //                CGRect rootSuperViewFrameInWindow = [_rootViewController.view.superview
      //                convertRect:_rootViewController.view.superview.bounds toView:keyWindow];
      //
      //                CGFloat keyboardOverlapping = CGRectGetMaxY(rootSuperViewFrameInWindow) -
      //                keyboardYPosition;
      //
      //                CGFloat textViewHeight = MIN(CGRectGetHeight(_textFieldView.frame),
      //                (CGRectGetHeight(rootSuperViewFrameInWindow)-topLayoutGuide-keyboardOverlapping));

      let keyboardYPosition = window.frame
        .height - (kbSize.height - newKeyboardDistanceFromTextField)
      var rootSuperViewFrameInWindow = window.frame
      if let rootSuperview = rootController.view.superview {
        rootSuperViewFrameInWindow = rootSuperview.convert(rootSuperview.bounds, to: window)
      }

      let keyboardOverlapping = rootSuperViewFrameInWindow.maxY - keyboardYPosition

      let textViewHeight = min(
        textView.frame.height,
        rootSuperViewFrameInWindow.height - topLayoutGuide - keyboardOverlapping
      )

      if textView.frame.size.height - textView.contentInset.bottom > textViewHeight {
        // _isTextViewContentInsetChanged,  If frame is not change by library in past, then saving user textView properties  (Bug
        // ID: #92)
        if !isTextViewContentInsetChanged {
          startingTextViewContentInsets = textView.contentInset

          #if swift(>=5.1)
            if #available(iOS 11.1, *) {
              self.startingTextViewScrollIndicatorInsets = textView
                .verticalScrollIndicatorInsets
            } else {
              startingTextViewScrollIndicatorInsets = textView.scrollIndicatorInsets
            }
          #else
            startingTextViewScrollIndicatorInsets = textView.scrollIndicatorInsets
          #endif
        }

        isTextViewContentInsetChanged = true

        var newContentInset = textView.contentInset
        newContentInset.bottom = textView.frame.size.height - textViewHeight

        if #available(iOS 11, *) {
          newContentInset.bottom -= textView.safeAreaInsets.bottom
        }

        if textView.contentInset != newContentInset {
          showLog(
            "\(textFieldView) Old UITextView.contentInset: \(textView.contentInset) New UITextView.contentInset: \(newContentInset)"
          )

          UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            options: animationCurve,
            animations: { () in
              textView.contentInset = newContentInset
              textView.scrollIndicatorInsets = newContentInset
            },
            completion: { _ in }
          )
        }
      }
    }

    //  +Positive or zero.
    if move >= 0 {
      rootViewOrigin.y = max(
        rootViewOrigin.y - move,
        min(0, -(kbSize.height - newKeyboardDistanceFromTextField))
      )

      if rootController.view.frame.origin.equalTo(rootViewOrigin) == false {
        showLog("Moving Upward")

        UIView.animate(
          withDuration: animationDuration,
          delay: 0,
          options: animationCurve,
          animations: { () in
            var rect = rootController.view.frame
            rect.origin = rootViewOrigin
            rootController.view.frame = rect

            // Animating content if needed (Bug ID: #204)
            if self.layoutIfNeededOnUpdate {
              // Animating content (Bug ID: #160)
              rootController.view.setNeedsLayout()
              rootController.view.layoutIfNeeded()
            }

            self.showLog("Set \(rootController) origin to: \(rootViewOrigin)")
          }
        )
      }

      movedDistance = (topViewBeginOrigin.y - rootViewOrigin.y)
    } else { //  -Negative
      let disturbDistance: CGFloat = rootViewOrigin.y - topViewBeginOrigin.y

      //  disturbDistance Negative = frame disturbed.
      //  disturbDistance positive = frame not disturbed.
      if disturbDistance <= 0 {
        rootViewOrigin.y -= max(move, disturbDistance)

        if rootController.view.frame.origin.equalTo(rootViewOrigin) == false {
          showLog("Moving Downward")
          //  Setting adjusted rootViewRect
          //  Setting adjusted rootViewRect

          UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            options: animationCurve,
            animations: { () in
              var rect = rootController.view.frame
              rect.origin = rootViewOrigin
              rootController.view.frame = rect

              // Animating content if needed (Bug ID: #204)
              if self.layoutIfNeededOnUpdate {
                // Animating content (Bug ID: #160)
                rootController.view.setNeedsLayout()
                rootController.view.layoutIfNeeded()
              }

              self.showLog("Set \(rootController) origin to: \(rootViewOrigin)")
            }
          )
        }

        movedDistance = (topViewBeginOrigin.y - rootViewOrigin.y)
      }
    }

    let elapsedTime = CACurrentMediaTime() - startTime
    showLog("****** \(#function) ended: \(elapsedTime) seconds ******", indentation: -1)
  }

  internal func restorePosition() {
    hasPendingAdjustRequest = false

    //  Setting rootViewController frame to it's original position. //  (Bug ID: #18)
    guard topViewBeginOrigin.equalTo(NEKeyboardManager.kNECGPointInvalid) == false,
          let rootViewController = rootViewController else {
      return
    }

    if rootViewController.view.frame.origin.equalTo(topViewBeginOrigin) == false {
      // Used UIViewAnimationOptionBeginFromCurrentState to minimize strange animations.
      UIView.animate(
        withDuration: animationDuration,
        delay: 0,
        options: animationCurve,
        animations: { () in
          self
            .showLog("Restoring \(rootViewController) origin to: \(self.topViewBeginOrigin)")

          //  Setting it's new frame
          var rect = rootViewController.view.frame
          rect.origin = self.topViewBeginOrigin
          rootViewController.view.frame = rect

          // Animating content if needed (Bug ID: #204)
          if self.layoutIfNeededOnUpdate {
            // Animating content (Bug ID: #160)
            rootViewController.view.setNeedsLayout()
            rootViewController.view.layoutIfNeeded()
          }
        }
      )
    }

    movedDistance = 0

    if rootViewController.navigationController?.interactivePopGestureRecognizer?
      .state == .began {
      rootViewControllerWhilePopGestureRecognizerActive = rootViewController
      topViewBeginOriginWhilePopGestureRecognizerActive = topViewBeginOrigin
    }

    self.rootViewController = nil
  }
}
