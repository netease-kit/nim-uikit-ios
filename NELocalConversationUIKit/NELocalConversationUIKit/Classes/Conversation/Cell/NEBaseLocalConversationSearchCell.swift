
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEBaseUIKit
import UIKit

@objcMembers
open class NEBaseLocalConversationSearchCell: TextBaseCell {
  private var activePrimaryText: String?
  private var activePrimaryMatchRange = NSRange(location: NSNotFound, length: 0)
  private var activeSecondaryText: String?
  private var activeSecondaryMatchRange = NSRange(location: NSNotFound, length: 0)
  private var isApplyingSearchLayout = false
  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  public var searchModel: ConversationSearchListModel? {
    didSet {
      resetTextAppearance()
      subTitleLabel.attributedText = nil
      subTitleLabel.text = nil
      subTitleLabel.isHidden = true

      if let userFriend = searchModel?.userInfo {
        let url = userFriend.user?.avatar
        let accountId = userFriend.user?.accountId ?? userFriend.friend?.accountId ?? ""
        let name = userFriend.user?.name ?? accountId
        headImageView.configHeadData(headUrl: url, name: name, uid: accountId)
        updateFriendDisplay(userFriend)
      } else if let teamInfo = searchModel?.team {
        let url = teamInfo.avatar
        let name = teamInfo.getShortName()
        let accountId = teamInfo.teamId
        headImageView.configHeadData(headUrl: url, name: name, uid: accountId)
        updateTeamDisplay(teamInfo)
      }
      updateSubtitleLayout()
    }
  }

  public var searchText: String = "" {
    didSet {
      resetTextAppearance()
      if let userFriend = searchModel?.userInfo {
        updateFriendDisplay(userFriend)
      } else if let teamInfo = searchModel?.team {
        updateTeamDisplay(teamInfo)
      }
      updateSubtitleLayout()
    }
  }

  override open func layoutSubviews() {
    super.layoutSubviews()
    guard let activePrimaryText, !isApplyingSearchLayout else { return }
    isApplyingSearchLayout = true
    applySearchDisplay(
      primaryText: activePrimaryText,
      primaryRange: activePrimaryMatchRange,
      secondaryText: activeSecondaryText,
      secondaryRange: activeSecondaryMatchRange
    )
    isApplyingSearchLayout = false
  }

  private func updateFriendDisplay(_ userFriend: NEUserWithFriend) {
    let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    if !keyword.isEmpty,
       let result = NETeamMemberSearchMatcher.result(
         keyword: keyword,
         teamNick: nil,
         friendAlias: userFriend.friend?.alias,
         userNickname: userFriend.user?.name,
         accountId: userFriend.user?.accountId ?? userFriend.friend?.accountId
       ) {
      activePrimaryText = result.primaryDisplayText
      activePrimaryMatchRange = result.primaryDisplayMatchRange
      activeSecondaryText = result.secondaryDisplayText
      activeSecondaryMatchRange = result.secondaryDisplayMatchRange
      applySearchDisplay(
        primaryText: result.primaryDisplayText,
        primaryRange: result.primaryDisplayMatchRange,
        secondaryText: result.secondaryDisplayText,
        secondaryRange: result.secondaryDisplayMatchRange
      )
      return
    }
    activePrimaryText = nil
    activeSecondaryText = nil

    let title = userFriend.showName(true)
      ?? userFriend.user?.accountId
      ?? userFriend.friend?.accountId
      ?? ""
    titleLabel.attributedText = nil
    titleLabel.text = title
    subTitleLabel.attributedText = nil
    subTitleLabel.text = nil
  }

  private func updateTeamDisplay(_ teamInfo: V2NIMTeam) {
    let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    if let result = NETeamMemberSearchMatcher.displayResult(
      keyword: keyword,
      text: teamInfo.name
    ) {
      activePrimaryText = result.primaryDisplayText
      activePrimaryMatchRange = result.primaryDisplayMatchRange
      activeSecondaryText = nil
      applySearchDisplay(
        primaryText: result.primaryDisplayText,
        primaryRange: result.primaryDisplayMatchRange,
        secondaryText: nil,
        secondaryRange: NSRange(location: NSNotFound, length: 0)
      )
    } else {
      activePrimaryText = nil
      activeSecondaryText = nil
      titleLabel.attributedText = nil
      titleLabel.text = teamInfo.name
    }
    subTitleLabel.attributedText = nil
    subTitleLabel.text = nil
  }

  private func highlightedText(_ text: String,
                               matchRange: NSRange,
                               baseColor: UIColor) -> NSAttributedString {
    let attributedText = NSMutableAttributedString(
      string: text,
      attributes: [.foregroundColor: baseColor]
    )
    guard matchRange.location != NSNotFound,
          NSMaxRange(matchRange) <= attributedText.length else {
      return attributedText
    }
    attributedText.addAttribute(.foregroundColor, value: getRangeTextColor(), range: matchRange)
    return attributedText
  }

  private func applySearchDisplay(primaryText: String,
                                  primaryRange: NSRange,
                                  secondaryText: String?,
                                  secondaryRange: NSRange) {
    let primary = NETextSearchLayout.result(
      text: primaryText,
      matchRange: primaryRange,
      font: titleLabel.font,
      maxWidth: titleLabel.bounds.width
    )
    titleLabel.attributedText = highlightedText(
      primary.text,
      matchRange: primary.matchRange,
      baseColor: .ne_darkText
    )
    if let secondaryText {
      let secondary = NETextSearchLayout.result(
        text: secondaryText,
        matchRange: secondaryRange,
        font: subTitleLabel.font,
        maxWidth: subTitleLabel.bounds.width
      )
      subTitleLabel.text = secondary.text
      subTitleLabel.attributedText = highlightedText(
        secondary.text,
        matchRange: secondary.matchRange,
        baseColor: .ne_greyText
      )
    } else {
      subTitleLabel.text = nil
      subTitleLabel.attributedText = nil
    }
  }

  private func updateSubtitleLayout() {
    let hasSubtitle = !(subTitleLabel.text ?? "").isEmpty
    subTitleLabel.isHidden = !hasSubtitle
    titleLabelTopAnchor?.isActive = hasSubtitle
    titleLabelCenterYAnchor?.isActive = !hasSubtitle
  }

  private func resetTextAppearance() {
    titleLabel.textColor = .ne_darkText
    subTitleLabel.textColor = .ne_greyText
  }

  func getRangeTextColor() -> UIColor {
    UIColor.ne_searchHighlight
  }
}
