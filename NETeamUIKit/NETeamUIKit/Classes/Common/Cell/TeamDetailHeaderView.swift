
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NECommonUIKit
import NECoreIM2Kit
import NIMSDK
import UIKit

@objcMembers
open class TeamDetailHeaderView: UIView {
  public var labelConstraints = [NSLayoutConstraint]()

  public lazy var teamHeaderView: NEUserHeaderView = {
    let imageView = NEUserHeaderView(frame: .zero)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.clipsToBounds = true
    imageView.titleLabel.font = NEConstant.defaultTextFont(14.0)
    imageView.isUserInteractionEnabled = true
    return imageView
  }()

  public lazy var teamNameLabel: CopyableLabel = {
    let titleLabel = CopyableLabel()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
    titleLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    titleLabel.accessibilityIdentifier = "id.teamName"
    return titleLabel
  }()

  public lazy var teamIdLabel: CopyableLabel = {
    let detailLabel = CopyableLabel()
    detailLabel.translatesAutoresizingMaskIntoConstraints = false
    detailLabel.font = UIFont.systemFont(ofSize: 16)
    detailLabel.textColor = .ne_greyText
    detailLabel.accessibilityIdentifier = "id.teamId"
    return detailLabel
  }()

  public lazy var teamOwnerLabel: CopyableLabel = {
    let detailLabel = CopyableLabel()
    detailLabel.translatesAutoresizingMaskIntoConstraints = false
    detailLabel.font = UIFont.systemFont(ofSize: 16)
    detailLabel.textColor = .ne_greyText
    detailLabel.accessibilityIdentifier = "id.teamOwner"
    return detailLabel
  }()

  lazy var lineView: UIView = {
    let view = UIView()
    view.backgroundColor = .ne_greyLine
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  public var avatarWH: CGFloat = 60

  init(avatarWH: CGFloat = 60) {
    super.init(frame: .zero)
    self.avatarWH = avatarWH
    commonUI()
  }

  override public init(frame: CGRect) {
    super.init(frame: frame)
    commonUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  open func commonUI() {
    backgroundColor = .white
    addSubview(teamHeaderView)
    addSubview(teamNameLabel)
    addSubview(teamIdLabel)
    addSubview(lineView)

    NSLayoutConstraint.activate([
      teamHeaderView.leftAnchor.constraint(equalTo: leftAnchor, constant: 0),
      teamHeaderView.widthAnchor.constraint(equalToConstant: avatarWH),
      teamHeaderView.heightAnchor.constraint(equalToConstant: avatarWH),
      teamHeaderView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0),
    ])

    NSLayoutConstraint.activate([
      lineView.leftAnchor.constraint(equalTo: leftAnchor, constant: 0),
      lineView.rightAnchor.constraint(equalTo: rightAnchor, constant: 0),
      lineView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
      lineView.heightAnchor.constraint(equalToConstant: 1),
    ])

    commonUI(showOwner: false)
  }

  open func commonUI(showOwner: Bool) {
    NSLayoutConstraint.deactivate(labelConstraints)
    var titleConstraint = [NSLayoutConstraint]()
    var detailConstraint = [NSLayoutConstraint]()
    var detail2Constraint = [NSLayoutConstraint]()
    if showOwner {
      titleConstraint = [
        teamNameLabel.leftAnchor.constraint(equalTo: teamHeaderView.rightAnchor, constant: 20),
        teamNameLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -0),
        teamNameLabel.topAnchor.constraint(equalTo: teamHeaderView.topAnchor, constant: -2),
        teamNameLabel.heightAnchor.constraint(equalToConstant: 22),
      ]

      detailConstraint = [
        teamIdLabel.leftAnchor.constraint(equalTo: teamNameLabel.leftAnchor),
        teamIdLabel.rightAnchor.constraint(equalTo: teamNameLabel.rightAnchor),
        teamIdLabel.topAnchor.constraint(equalTo: teamNameLabel.bottomAnchor, constant: 6),
        teamIdLabel.heightAnchor.constraint(equalToConstant: 16),
      ]

      addSubview(teamOwnerLabel)
      detail2Constraint = [
        teamOwnerLabel.leftAnchor.constraint(equalTo: teamNameLabel.leftAnchor),
        teamOwnerLabel.rightAnchor.constraint(equalTo: teamNameLabel.rightAnchor),
        teamOwnerLabel.topAnchor.constraint(equalTo: teamIdLabel.bottomAnchor),
        teamIdLabel.heightAnchor.constraint(equalToConstant: 16),
      ]
    } else {
      titleConstraint = [
        teamNameLabel.leftAnchor.constraint(equalTo: teamHeaderView.rightAnchor, constant: 16),
        teamNameLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -20),
        teamNameLabel.topAnchor.constraint(equalTo: teamHeaderView.topAnchor, constant: 0),
        teamNameLabel.heightAnchor.constraint(equalToConstant: 22),
      ]

      detailConstraint = [
        teamIdLabel.leftAnchor.constraint(equalTo: teamNameLabel.leftAnchor),
        teamIdLabel.rightAnchor.constraint(equalTo: teamNameLabel.rightAnchor),
        teamIdLabel.bottomAnchor.constraint(equalTo: teamHeaderView.bottomAnchor, constant: -2),
        teamIdLabel.heightAnchor.constraint(equalToConstant: 16),
      ]

      teamOwnerLabel.removeFromSuperview()
      detail2Constraint = []
    }
    labelConstraints = titleConstraint + detailConstraint + detail2Constraint
    NSLayoutConstraint.activate(labelConstraints)
    updateConstraintsIfNeeded()
  }

  open func resetAvatarWH(_ wh: CGFloat) {
    teamHeaderView.updateLayoutConstraint(firstItem: teamHeaderView, secondItem: teamHeaderView, attribute: .width, constant: wh)
    teamHeaderView.updateLayoutConstraint(firstItem: teamHeaderView, secondItem: teamHeaderView, attribute: .height, constant: wh)
  }

  open func setData(_ team: V2NIMTeam?, _ showOwner: Bool = true) {
    // avatar
    let url = team?.avatar
    let name = team?.name ?? ""
    let teamId = team?.teamId ?? ""
    teamHeaderView.configHeadData(headUrl: url, name: name, uid: teamId)

    // title
    commonUI(showOwner: showOwner)
    teamNameLabel.text = name
    teamIdLabel.text = "\(localizable("team_id")): \(teamId)"
    teamIdLabel.copyString = teamId

    if showOwner {
      getOwnerName(team) { [weak self] ownerName in
        self?.teamOwnerLabel.text = "\(localizable("team_owner")): \(ownerName)"
        self?.teamOwnerLabel.copyString = ownerName
      }
    }
  }

  open func getOwnerName(_ team: V2NIMTeam?, _ completion: @escaping (String) -> Void) {
    if let teamId = team?.teamId,
       let ownerAccountId = team?.ownerAccountId {
      var ownerName = ownerAccountId
      TeamRepo.shared.getTeamMember(teamId, .TEAM_TYPE_NORMAL, ownerAccountId) { [weak self] member, error in
        if let err = error {
          NEALog.errorLog(self?.className() ?? "", desc: #function + "getTeamMember \(ownerAccountId) error: \(err.localizedDescription)")
          ownerName = ownerAccountId
          completion(ownerName)
        } else {
          // 备注
          if let friend = NEFriendUserCache.shared.getFriendInfo(ownerAccountId) {
            ownerName = friend.showName() ?? ownerAccountId
            completion(ownerName)
            return
          }

          // 群昵称
          if let teamNick = member?.teamNick, !teamNick.isEmpty {
            ownerName = teamNick
            completion(ownerName)
            return
          }

          // 个人昵称
          ContactRepo.shared.getUserListFromCloud(accountIds: [ownerAccountId]) { users, error in
            if let user = users?.first {
              ownerName = user.showName() ?? ownerAccountId
            }
            completion(ownerName)
          }
        }
      }
    }
  }
}
