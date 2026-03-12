
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation

// MARK: NEAutoToolbarManageBehaviour

/**
 `NEAutoToolbarBySubviews`
 Creates Toolbar according to subview's hirarchy of Textfield's in view.

 `NEAutoToolbarByTag`
 Creates Toolbar according to tag property of TextField's.

 `NEAutoToolbarByPosition`
 Creates Toolbar according to the y,x position of textField in it's superview coordinate.
 */
@available(iOSApplicationExtension, unavailable)
@objc public enum NEAutoToolbarManageBehaviour: Int {
  case bySubviews
  case byTag
  case byPosition
}

/**
 `NEPreviousNextDisplayModeDefault`
 Show NextPrevious when there are more than 1 textField otherwise hide.

 `NEPreviousNextDisplayModeAlwaysHide`
 Do not show NextPrevious buttons in any case.

 `NEPreviousNextDisplayModeAlwaysShow`
 Always show nextPrevious buttons, if there are more than 1 textField then both buttons will be visible but will be shown as disabled.
 */
@available(iOSApplicationExtension, unavailable)
@objc public enum NEPreviousNextDisplayMode: Int {
  case `default`
  case alwaysHide
  case alwaysShow
}

/**
 `NEEnableModeDefault`
 Pick default settings.

 `NEEnableModeEnabled`
 setting is enabled.

 `NEEnableModeDisabled`
 setting is disabled.
 */
@available(iOSApplicationExtension, unavailable)
@objc public enum NEEnableMode: Int {
  case `default`
  case enabled
  case disabled
}
