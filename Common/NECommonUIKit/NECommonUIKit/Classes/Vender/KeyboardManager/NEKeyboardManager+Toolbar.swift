
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

// import Foundation - UIKit contains Foundation
import UIKit

@available(iOSApplicationExtension, unavailable)
public extension NEKeyboardManager {
  /**
   Default tag for toolbar with Done button   -1002.
   */
  private static let kNEDoneButtonToolbarTag = -1002

  /**
   Default tag for toolbar with Previous/Next buttons -1005.
   */
  private static let kNEPreviousNextButtonToolbarTag = -1005

  /** Add toolbar if it is required to add on textFields and it's siblings. */
  internal func addToolbarIfRequired() {
    // Either there is no inputAccessoryView or if accessoryView is not appropriate for current
    // situation(There is Previous/Next/Done toolbar).
    guard let siblings = responderViews(), !siblings.isEmpty,
          let textField = textFieldView,
          textField.responds(to: #selector(setter: UITextField.inputAccessoryView)),
          textField.inputAccessoryView == nil ||
          textField.inputAccessoryView?.tag == NEKeyboardManager
          .kNEPreviousNextButtonToolbarTag ||
          textField.inputAccessoryView?.tag == NEKeyboardManager.kNEDoneButtonToolbarTag
    else {
      return
    }

    let startTime = CACurrentMediaTime()
    showLog("****** \(#function) started ******", indentation: 1)

    showLog("Found \(siblings.count) responder sibling(s)")

    let rightConfiguration: NEBarButtonItemConfiguration

    if let doneBarButtonItemImage = toolbarDoneBarButtonItemImage {
      rightConfiguration = NEBarButtonItemConfiguration(
        image: doneBarButtonItemImage,
        action: #selector(doneAction(_:))
      )
    } else if let doneBarButtonItemText = toolbarDoneBarButtonItemText {
      rightConfiguration = NEBarButtonItemConfiguration(
        title: doneBarButtonItemText,
        action: #selector(doneAction(_:))
      )
    } else {
      rightConfiguration = NEBarButtonItemConfiguration(
        barButtonSystemItem: .done,
        action: #selector(doneAction(_:))
      )
    }
    rightConfiguration.accessibilityLabel = toolbarDoneBarButtonItemAccessibilityLabel ?? "Done"

    //    If only one object is found, then adding only Done button.
    if (siblings.count <= 1 && previousNextDisplayMode == .default) || previousNextDisplayMode ==
      .alwaysHide {
      textField.neAddKeyboardToolbarWithTarget(
        target: self,
        titleText: shouldShowToolbarPlaceholder ? textField.neDrawingToolbarPlaceholder : nil,
        rightBarButtonConfiguration: rightConfiguration,
        previousBarButtonConfiguration: nil,
        nextBarButtonConfiguration: nil
      )

      textField.inputAccessoryView?.tag = NEKeyboardManager
        .kNEDoneButtonToolbarTag //  (Bug ID: #78)

    } else if previousNextDisplayMode == .default || previousNextDisplayMode == .alwaysShow {
      let prevConfiguration: NEBarButtonItemConfiguration

      if let doneBarButtonItemImage = toolbarPreviousBarButtonItemImage {
        prevConfiguration = NEBarButtonItemConfiguration(
          image: doneBarButtonItemImage,
          action: #selector(previousAction(_:))
        )
      } else if let doneBarButtonItemText = toolbarPreviousBarButtonItemText {
        prevConfiguration = NEBarButtonItemConfiguration(
          title: doneBarButtonItemText,
          action: #selector(previousAction(_:))
        )
      } else {
        prevConfiguration = NEBarButtonItemConfiguration(
          image: UIImage.neKeyboardPreviousImage() ?? UIImage(),
          action: #selector(previousAction(_:))
        )
      }
      prevConfiguration
        .accessibilityLabel = toolbarPreviousBarButtonItemAccessibilityLabel ?? "Previous"

      let nextConfiguration: NEBarButtonItemConfiguration

      if let doneBarButtonItemImage = toolbarNextBarButtonItemImage {
        nextConfiguration = NEBarButtonItemConfiguration(
          image: doneBarButtonItemImage,
          action: #selector(nextAction(_:))
        )
      } else if let doneBarButtonItemText = toolbarNextBarButtonItemText {
        nextConfiguration = NEBarButtonItemConfiguration(
          title: doneBarButtonItemText,
          action: #selector(nextAction(_:))
        )
      } else {
        nextConfiguration = NEBarButtonItemConfiguration(
          image: UIImage.neKeyboardNextImage() ?? UIImage(),
          action: #selector(nextAction(_:))
        )
      }
      nextConfiguration
        .accessibilityLabel = toolbarNextBarButtonItemAccessibilityLabel ?? "Next"

      textField.neAddKeyboardToolbarWithTarget(
        target: self,
        titleText: shouldShowToolbarPlaceholder ? textField.neDrawingToolbarPlaceholder : nil,
        rightBarButtonConfiguration: rightConfiguration,
        previousBarButtonConfiguration: prevConfiguration,
        nextBarButtonConfiguration: nextConfiguration
      )

      textField.inputAccessoryView?.tag = NEKeyboardManager
        .kNEPreviousNextButtonToolbarTag //  (Bug ID: #78)
    }

    let toolbar = textField.neKeyboardToolbar

    // Setting toolbar tintColor //  (Enhancement ID: #30)
    toolbar.tintColor = shouldToolbarUsesTextFieldTintColor ? textField
      .tintColor : toolbarTintColor

    //  Setting toolbar to keyboard.
    if let textFieldView = textField as? UITextInput {
      // Bar style according to keyboard appearance
      switch textFieldView.keyboardAppearance {
      case .dark?:
        toolbar.barStyle = .black
        toolbar.barTintColor = nil
      default:
        toolbar.barStyle = .default
        toolbar.barTintColor = toolbarBarTintColor
      }
    }

    // Setting toolbar title font.   //  (Enhancement ID: #30)
    if shouldShowToolbarPlaceholder, !textField.neShouldHideToolbarPlaceholder {
      // Updating placeholder font to toolbar.     //(Bug ID: #148, #272)
      if toolbar.titleBarButton.title == nil ||
        toolbar.titleBarButton.title != textField.neDrawingToolbarPlaceholder {
        toolbar.titleBarButton.title = textField.neDrawingToolbarPlaceholder
      }

      // Setting toolbar title font.   //  (Enhancement ID: #30)
      toolbar.titleBarButton.titleFont = placeholderFont

      // Setting toolbar title color.   //  (Enhancement ID: #880)
      toolbar.titleBarButton.titleColor = placeholderColor

      // Setting toolbar button title color.   //  (Enhancement ID: #880)
      toolbar.titleBarButton.selectableTitleColor = placeholderButtonColor

    } else {
      toolbar.titleBarButton.title = nil
    }

    textField.neKeyboardToolbar.previousBarButton
      .isEnabled = (siblings
        .first != textField) //    If firstTextField, then previous should not be enabled.
    textField.neKeyboardToolbar.nextBarButton
      .isEnabled = (siblings
        .last != textField) //    If lastTextField then next should not be enaled.

    let elapsedTime = CACurrentMediaTime() - startTime
    showLog("****** \(#function) ended: \(elapsedTime) seconds ******", indentation: -1)
  }

  /** Remove any toolbar if it is NEToolbar. */
  internal func removeToolbarIfRequired() { //  (Bug ID: #18)
    guard let siblings = responderViews(), !siblings.isEmpty,
          let textField = textFieldView,
          textField.responds(to: #selector(setter: UITextField.inputAccessoryView)),
          textField.inputAccessoryView == nil ||
          textField.inputAccessoryView?.tag == NEKeyboardManager
          .kNEPreviousNextButtonToolbarTag ||
          textField.inputAccessoryView?.tag == NEKeyboardManager.kNEDoneButtonToolbarTag
    else {
      return
    }

    let startTime = CACurrentMediaTime()
    showLog("****** \(#function) started ******", indentation: 1)

    showLog("Found \(siblings.count) responder sibling(s)")

    for view in siblings {
      if let toolbar = view.inputAccessoryView as? NEToolbar {
        // setInputAccessoryView: check   (Bug ID: #307)
        if view.responds(to: #selector(setter: UITextField.inputAccessoryView)),
           toolbar.tag == NEKeyboardManager.kNEDoneButtonToolbarTag || toolbar
           .tag == NEKeyboardManager.kNEPreviousNextButtonToolbarTag {
          if let textField = view as? UITextField {
            textField.inputAccessoryView = nil
          } else if let textView = view as? UITextView {
            textView.inputAccessoryView = nil
          }

          view.reloadInputViews()
        }
      }
    }

    let elapsedTime = CACurrentMediaTime() - startTime
    showLog("****** \(#function) ended: \(elapsedTime) seconds ******", indentation: -1)
  }

  /**    reloadInputViews to reload toolbar buttons enable/disable state on the fly Enhancement ID #434. */
  @objc func reloadInputViews() {
    // If enabled then adding toolbar.
    if privateIsEnableAutoToolbar() {
      addToolbarIfRequired()
    } else {
      removeToolbarIfRequired()
    }
  }
}

// MARK: Previous next button actions

@available(iOSApplicationExtension, unavailable)
public extension NEKeyboardManager {
  /**
   Returns YES if can navigate to previous responder textField/textView, otherwise NO.
   */
  @objc var canGoPrevious: Bool {
    // If it is not first textField. then it's previous object canBecomeFirstResponder.
    guard let textFields = responderViews(), let textFieldRetain = textFieldView,
          let index = textFields.firstIndex(of: textFieldRetain), index > 0 else {
      return false
    }
    return true
  }

  /**
   Returns YES if can navigate to next responder textField/textView, otherwise NO.
   */
  @objc var canGoNext: Bool {
    // If it is not first textField. then it's previous object canBecomeFirstResponder.
    guard let textFields = responderViews(), let textFieldRetain = textFieldView,
          let index = textFields.firstIndex(of: textFieldRetain),
          index < textFields.count - 1 else {
      return false
    }
    return true
  }

  /**
   Navigate to previous responder textField/textView.
   */
  @objc @discardableResult func goPrevious() -> Bool {
    // If it is not first textField. then it's previous object becomeFirstResponder.
    guard let textFields = responderViews(), let textFieldRetain = textFieldView,
          let index = textFields.firstIndex(of: textFieldRetain), index > 0 else {
      return false
    }

    let nextTextField = textFields[index - 1]

    let isAcceptAsFirstResponder = nextTextField.becomeFirstResponder()

    //  If it refuses then becoming previous textFieldView as first responder again.    (Bug ID: #96)
    if isAcceptAsFirstResponder == false {
      // If next field refuses to become first responder then restoring old textField as first
      // responder.
      textFieldRetain.becomeFirstResponder()

      showLog("Refuses to become first responder: \(nextTextField)")
    }

    return isAcceptAsFirstResponder
  }

  /**
   Navigate to next responder textField/textView.
   */
  @objc @discardableResult func goNext() -> Bool {
    // If it is not first textField. then it's previous object becomeFirstResponder.
    guard let textFields = responderViews(), let textFieldRetain = textFieldView,
          let index = textFields.firstIndex(of: textFieldRetain),
          index < textFields.count - 1 else {
      return false
    }

    let nextTextField = textFields[index + 1]

    let isAcceptAsFirstResponder = nextTextField.becomeFirstResponder()

    //  If it refuses then becoming previous textFieldView as first responder again.    (Bug ID: #96)
    if isAcceptAsFirstResponder == false {
      // If next field refuses to become first responder then restoring old textField as first
      // responder.
      textFieldRetain.becomeFirstResponder()

      showLog("Refuses to become first responder: \(nextTextField)")
    }

    return isAcceptAsFirstResponder
  }

  /**    previousAction. */
  @objc internal func previousAction(_ barButton: NEBarButtonItem) {
    // If user wants to play input Click sound.
    if shouldPlayInputClicks {
      // Play Input Click Sound.
      UIDevice.current.playInputClick()
    }

    guard canGoPrevious, let textFieldRetain = textFieldView else {
      return
    }

    let isAcceptAsFirstResponder = goPrevious()

    var invocation = barButton.invocation
    var sender = textFieldRetain

    // Handling search bar special case
    do {
      if let searchBar = textFieldRetain.neTextFieldSearchBar() {
        invocation = searchBar.neKeyboardToolbar.previousBarButton.invocation
        sender = searchBar
      }
    }

    if isAcceptAsFirstResponder {
      invocation?.invoke(from: sender)
    }
  }

  /**    nextAction. */
  @objc internal func nextAction(_ barButton: NEBarButtonItem) {
    // If user wants to play input Click sound.
    if shouldPlayInputClicks {
      // Play Input Click Sound.
      UIDevice.current.playInputClick()
    }

    guard canGoNext, let textFieldRetain = textFieldView else {
      return
    }

    let isAcceptAsFirstResponder = goNext()

    var invocation = barButton.invocation
    var sender = textFieldRetain

    // Handling search bar special case
    do {
      if let searchBar = textFieldRetain.neTextFieldSearchBar() {
        invocation = searchBar.neKeyboardToolbar.nextBarButton.invocation
        sender = searchBar
      }
    }

    if isAcceptAsFirstResponder {
      invocation?.invoke(from: sender)
    }
  }

  /**    doneAction. Resigning current textField. */
  @objc internal func doneAction(_ barButton: NEBarButtonItem) {
    // If user wants to play input Click sound.
    if shouldPlayInputClicks {
      // Play Input Click Sound.
      UIDevice.current.playInputClick()
    }

    guard let textFieldRetain = textFieldView else {
      return
    }

    // Resign textFieldView.
    let isResignedFirstResponder = resignFirstResponder()

    var invocation = barButton.invocation
    var sender = textFieldRetain

    // Handling search bar special case
    do {
      if let searchBar = textFieldRetain.neTextFieldSearchBar() {
        invocation = searchBar.neKeyboardToolbar.doneBarButton.invocation
        sender = searchBar
      }
    }

    if isResignedFirstResponder {
      invocation?.invoke(from: sender)
    }
  }
}
