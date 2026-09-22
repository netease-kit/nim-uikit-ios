//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEBaseUIKit
import NEChatKit
import UIKit

@objcMembers
open class NEBaseTeamMemberSelectCell: UITableViewCell {
  public var currentModel: NESelectTeamMember?
  private var currentSearchResult: NETeamMemberSearchResult?
  private var isApplyingSearchLayout = false

  // check box image
  public lazy var checkImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFit
    imageView.image = coreLoader.loadImage("unselect")
    return imageView
  }()

  public lazy var headerView: NEUserHeaderView = {
    let headerView = NEUserHeaderView(frame: .zero)
    headerView.titleLabel.font = NEConstant.defaultTextFont(14)
    headerView.titleLabel.textColor = UIColor.white
    headerView.clipsToBounds = true
    headerView.translatesAutoresizingMaskIntoConstraints = false
    headerView.accessibilityIdentifier = "id.avatar"
    return headerView
  }()

  public lazy var nameLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = NEConstant.defaultTextFont(16.0)
    label.textColor = .ne_darkText
    label.numberOfLines = 1
    label.lineBreakMode = .byTruncatingTail
    label.accessibilityIdentifier = "id.userName"
    return label
  }()

  public lazy var subtitleLabel: UILabel = {
    let label = UILabel()
    label.font = NEConstant.defaultTextFont(13.0)
    label.textColor = .ne_greyText
    label.numberOfLines = 1
    label.lineBreakMode = .byTruncatingTail
    label.accessibilityIdentifier = "id.userSubtitle"
    label.isHidden = true
    return label
  }()

  public lazy var nameStackView: UIStackView = {
    let stack = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.axis = .vertical
    stack.alignment = .fill
    stack.spacing = 1
    return stack
  }()

  override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func setupUI() {
    contentView.addSubview(headerView)
    contentView.addSubview(nameStackView)
    contentView.addSubview(checkImageView)
  }

  open func configureMember(_ model: NESelectTeamMember?) {
    configureMember(model, searchResult: nil)
  }

  open func configureMember(_ model: NESelectTeamMember?,
                            searchResult: NETeamMemberSearchResult?) {
    currentModel = model
    currentSearchResult = searchResult
    checkImageView.isHighlighted = model?.isSelected ?? false

    let url = model?.member?.nimUser?.user?.avatar
    let accountId = model?.member?.teamMember?.accountId
      ?? model?.member?.nimUser?.user?.accountId
      ?? ""
    let name = model?.member?.getShortName(model?.member?.nimUser?.showName(false) ?? accountId) ?? ""
    headerView.configHeadData(headUrl: url, name: name, uid: accountId)
    guard let searchResult else {
      configureName(model?.member?.atNameInTeam() ?? accountId)
      return
    }
    applySearchResult(searchResult)
  }

  override open func layoutSubviews() {
    super.layoutSubviews()
    guard let currentSearchResult, !isApplyingSearchLayout else { return }
    isApplyingSearchLayout = true
    applySearchResult(currentSearchResult)
    isApplyingSearchLayout = false
  }

  private func applySearchResult(_ searchResult: NETeamMemberSearchResult) {
    let primary = NETextSearchLayout.result(
      text: searchResult.primaryDisplayText,
      matchRange: searchResult.primaryDisplayMatchRange,
      font: nameLabel.font,
      maxWidth: nameLabel.bounds.width
    )
    nameLabel.attributedText = highlightedText(
      primary.text,
      range: primary.matchRange,
      baseColor: .ne_darkText,
      baseFont: nameLabel.font
    )
    if let secondary = searchResult.secondaryDisplayText {
      let subtitle = NETextSearchLayout.result(
        text: secondary,
        matchRange: searchResult.secondaryDisplayMatchRange,
        font: subtitleLabel.font,
        maxWidth: subtitleLabel.bounds.width
      )
      subtitleLabel.attributedText = highlightedText(
        subtitle.text,
        range: subtitle.matchRange,
        baseColor: .ne_greyText,
        baseFont: subtitleLabel.font
      )
      subtitleLabel.isHidden = false
    } else {
      subtitleLabel.attributedText = nil
      subtitleLabel.text = nil
      subtitleLabel.isHidden = true
    }
  }

  private func configureName(_ name: String) {
    currentSearchResult = nil
    nameLabel.attributedText = nil
    nameLabel.text = name
    subtitleLabel.attributedText = nil
    subtitleLabel.text = nil
    subtitleLabel.isHidden = true
  }

  private func highlightedText(_ value: String,
                               range: NSRange,
                               baseColor: UIColor,
                               baseFont: UIFont) -> NSAttributedString {
    let text = NSMutableAttributedString(
      string: value,
      attributes: [
        .foregroundColor: baseColor,
        .font: baseFont,
      ]
    )
    guard range.location != NSNotFound,
          range.location >= 0,
          NSMaxRange(range) <= text.length else {
      return text
    }
    text.addAttribute(.foregroundColor, value: UIColor.ne_searchHighlight, range: range)
    return text
  }
}
