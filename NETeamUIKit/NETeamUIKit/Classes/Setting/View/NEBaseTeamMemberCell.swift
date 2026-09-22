
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEBaseUIKit
import UIKit

@objc
public protocol TeamMemberCellDelegate: NSObjectProtocol {
  func didClickRemoveButton(_ model: NETeamMemberInfoModel?, _ index: Int)
}

@objcMembers
open class NEBaseTeamMemberCell: UITableViewCell {
  var currentModel: NETeamMemberInfoModel?
  private var currentSearchResult: NETeamMemberSearchResult?
  private var isApplyingSearchLayout = false

  weak var delegate: TeamMemberCellDelegate?

  public var ownerWidth: NSLayoutConstraint?
  var ownerRightMargin: NSLayoutConstraint?
  var ownerRightVisibleConstant: CGFloat = -70
  var ownerRightHiddenConstant: CGFloat = -20

  public var nameLabelRightMargin: NSLayoutConstraint?

  var index = 0

  public lazy var headerView: NEUserHeaderView = {
    let header = NEUserHeaderView(frame: .zero)
    header.titleLabel.font = NEConstant.defaultTextFont(14)
    header.titleLabel.textColor = UIColor.white
    header.layer.cornerRadius = 21
    header.clipsToBounds = true
    header.translatesAutoresizingMaskIntoConstraints = false
    return header
  }()

  public lazy var ownerLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = NEConstant.defaultTextFont(12.0)
    label.textColor = NEConstant.hexRGB(0x337EFF)
    label.backgroundColor = NEConstant.hexRGB(0xE0ECFF)
    label.layer.borderColor = NEConstant.hexRGB(0xB9D3FF).cgColor
    label.clipsToBounds = true
    label.layer.cornerRadius = 4.0
    label.layer.borderWidth = 1.0
    label.text = localizable("team_owner")
    label.textAlignment = .center
    label.accessibilityIdentifier = "id.identify"
    return label
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

  public lazy var removeLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.text = localizable("team_member_remove")
    label.font = UIFont.systemFont(ofSize: 14.0)
    label.textAlignment = .center
    return label
  }()

  public lazy var removeButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
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
    NSLayoutConstraint.activate([
      headerView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 21),
      headerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      headerView.widthAnchor.constraint(equalToConstant: 42),
      headerView.heightAnchor.constraint(equalToConstant: 42),
    ])

    nameLabelRightMargin = nameStackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: NEAppLanguageUtil.getCurrentLanguage() == .english ? -170 : -116)
    contentView.addSubview(nameStackView)
    NSLayoutConstraint.activate([
      nameStackView.leftAnchor.constraint(equalTo: headerView.rightAnchor, constant: 14.0),
      nameStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      nameLabelRightMargin!,
    ])

    ownerWidth = ownerLabel.widthAnchor.constraint(equalToConstant: 48.0)
    contentView.addSubview(ownerLabel)
    ownerRightVisibleConstant = NEAppLanguageUtil.getCurrentLanguage() == .english ? -90 : -70
    ownerRightMargin = ownerLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: ownerRightVisibleConstant)
    NSLayoutConstraint.activate([
      ownerRightMargin!,
      ownerLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      ownerLabel.heightAnchor.constraint(equalToConstant: 22.0),
      ownerWidth!,
    ])
  }

  /// Keeps the role badge aligned with the trailing edge when the remove action is unavailable.
  open func setRemoveControlsVisible(_ visible: Bool) {
    removeButton.isHidden = !visible
    removeLabel.isHidden = !visible
    ownerRightMargin?.constant = visible ? ownerRightVisibleConstant : ownerRightHiddenConstant
  }

  open func configure(_ model: NETeamMemberInfoModel) {
    configure(model, searchResult: nil)
  }

  open func configure(_ model: NETeamMemberInfoModel,
                      searchResult: NETeamMemberSearchResult?) {
    // 更新用户信息
    let accountId = model.teamMember?.accountId ?? model.nimUser?.user?.accountId ?? ""
    if let aiUser = NEAIUserManager.shared.getNEUserById(accountId) {
      model.nimUser = aiUser
    } else if let user = NEFriendUserCache.shared.getFriendInfo(accountId) {
      model.nimUser = user
    }
    currentModel = model
    currentSearchResult = searchResult

    let url = model.nimUser?.user?.avatar
    let name = model.getShortName(model.nimUser?.showName(false) ?? accountId)
    headerView.configHeadData(headUrl: url, name: name, uid: accountId)
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

  open func setupRemoveButton() {
    contentView.addSubview(removeButton)
    NSLayoutConstraint.activate([
      removeButton.topAnchor.constraint(equalTo: contentView.topAnchor),
      removeButton.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      removeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      removeButton.widthAnchor.constraint(equalToConstant: 100),
    ])
    removeButton.addTarget(self, action: #selector(didClickRemove), for: .touchUpInside)
  }

  open func didClickRemove() {
    delegate?.didClickRemoveButton(currentModel, index)
  }
}
