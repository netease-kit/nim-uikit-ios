
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NEBaseUIKit
import UIKit

@objcMembers
open class NEBaseChatTeamMemberCell: UITableViewCell {
  open var searchHighlightColor: UIColor { .ne_searchHighlight }
  open var nameHorizontalSpacing: CGFloat { 14 }
  open var nameTrailingInset: CGFloat { 70 }
  private var currentSearchResult: NETeamMemberSearchResult?
  private var isApplyingSearchLayout = false

  public lazy var headerView: NEUserHeaderView = {
    let header = NEUserHeaderView(frame: .zero)
    header.titleLabel.font = NEConstant.defaultTextFont(14)
    header.titleLabel.textColor = UIColor.white
    header.clipsToBounds = true
    header.translatesAutoresizingMaskIntoConstraints = false
    header.accessibilityIdentifier = "id.atCellHeaderView"
    return header
  }()

  public lazy var nameLabel: UILabel = {
    let label = UILabel()
    label.textColor = .ne_darkText
    label.font = NEConstant.defaultTextFont(16)
    label.numberOfLines = 1
    label.lineBreakMode = .byTruncatingTail
    label.accessibilityIdentifier = "id.atCellName"
    return label
  }()

  public lazy var subtitleLabel: UILabel = {
    let label = UILabel()
    label.textColor = .ne_greyText
    label.font = NEConstant.defaultTextFont(13)
    label.numberOfLines = 1
    label.lineBreakMode = .byTruncatingTail
    label.accessibilityIdentifier = "id.atCellSubtitle"
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

  override open func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

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
    NSLayoutConstraint.activate([
      headerView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 21),
      headerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      headerView.widthAnchor.constraint(equalToConstant: chat_min_h),
      headerView.heightAnchor.constraint(equalToConstant: chat_min_h),
    ])

    contentView.addSubview(nameStackView)
    NSLayoutConstraint.activate([
      nameStackView.leftAnchor.constraint(equalTo: headerView.rightAnchor, constant: nameHorizontalSpacing),
      nameStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      nameStackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -nameTrailingInset),
    ])
  }

  open func configure(_ model: NETeamMemberInfoModel) {
    configure(model, searchResult: nil)
  }

  open func configure(_ model: NETeamMemberInfoModel,
                      searchResult: NETeamMemberSearchResult?) {
    let url = model.nimUser?.user?.avatar
    let accountId = model.nimUser?.user?.accountId ?? model.teamMember?.accountId ?? ""
    let name = model.getShortName(model.nimUser?.showName(false) ?? accountId)
    headerView.configHeadData(headUrl: url, name: name, uid: accountId)
    currentSearchResult = searchResult
    guard let searchResult else {
      configureName(model.atNameInTeam() ?? accountId)
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
      matchRange: primary.matchRange,
      baseColor: .ne_darkText,
      baseFont: nameLabel.font
    )
    if let secondaryText = searchResult.secondaryDisplayText {
      let subtitle = NETextSearchLayout.result(
        text: secondaryText,
        matchRange: searchResult.secondaryDisplayMatchRange,
        font: subtitleLabel.font,
        maxWidth: subtitleLabel.bounds.width
      )
      subtitleLabel.attributedText = highlightedText(
        subtitle.text,
        matchRange: subtitle.matchRange,
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

  open func configureAll(title: String) {
    configureName(title)
  }

  open func configureAll(title: String, image: UIImage?) {
    headerView.configStaticImage(image)
    configureName(title)
  }

  private func configureName(_ name: String) {
    currentSearchResult = nil
    nameLabel.attributedText = nil
    nameLabel.text = name
    subtitleLabel.attributedText = nil
    subtitleLabel.text = nil
    subtitleLabel.isHidden = true
  }

  private func highlightedText(_ text: String,
                               matchRange: NSRange,
                               baseColor: UIColor,
                               baseFont: UIFont) -> NSAttributedString {
    let attributedText = NSMutableAttributedString(
      string: text,
      attributes: [
        .foregroundColor: baseColor,
        .font: baseFont,
      ]
    )
    guard matchRange.location != NSNotFound,
          NSMaxRange(matchRange) <= attributedText.length else {
      return attributedText
    }
    attributedText.addAttribute(.foregroundColor, value: searchHighlightColor, range: matchRange)
    return attributedText
  }
}
