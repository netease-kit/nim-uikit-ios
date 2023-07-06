
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NIMSDK

@objcMembers
public class TeamProvider: NSObject {
  public static let shared = TeamProvider()

  override private init() {}

  public func addDelegate(delegate: NIMTeamManagerDelegate) {
    NIMSDK.shared().teamManager.add(delegate)
  }

  public func removeDelegate(delegate: NIMTeamManagerDelegate) {
    NIMSDK.shared().teamManager.remove(delegate)
  }

  public func getTeamList() -> [Team] {
    var list: [Team] = []
    guard let teamList = NIMSDK.shared().teamManager.allMyTeams() else {
      return list
    }
    for team in teamList {
      list.append(Team(teamInfo: team))
    }
    return list
  }

  public func teamInfo(teamId: String?) -> Team? {
    if teamId == nil {
      return nil
    }
    let teamInfo = getTeam(teamId: teamId!)
    return teamInfo != nil ? Team(teamInfo: teamInfo) : nil
  }

  public func superTeamInfo(teamId: String?) -> Team? {
    if teamId == nil {
      return nil
    }
    return Team(teamInfo: NIMSDK.shared().superTeamManager.team(byId: teamId!))
  }

  /// 获取指定群ID的群信息
  /// - Parameters:
  ///   - teamIds: 群id列表
  ///   - completion: 回调
  public func fetchTeamInfoList(teamIds: [String],
                                _ completion: @escaping (NSError?, [NIMTeam]?) -> Void) {
    NIMSDK.shared().teamManager.fetchTeamInfoList(teamIds) { error, teams, failedTeamIds in
      completion(error as NSError?, teams)
    }
  }

  /// 获取群信息 from server
  /// - Parameters:
  ///   - teamId: 群组ID
  ///   - completion: 回调
  public func fetchTeamInfo(teamId: String,
                            _ completion: @escaping (NSError?, NIMTeam?) -> Void) {
    NIMSDK.shared().teamManager.fetchTeamInfo(teamId) { error, team in
      completion(error as NSError?, team)
    }
  }

  /// 获取群信息 from db
  /// - Parameters:
  ///   - teamId: 群组ID
  ///   - completion: 回调
  public func getTeam(teamId: String) -> NIMTeam? {
    NIMSDK.shared().teamManager.team(byId: teamId)
  }

  public func fetchTeamMember(_ teamId: String,
                              _ completion: @escaping (NSError?, [NIMTeamMember]?) -> Void) {
    NIMSDK.shared().teamManager.fetchTeamMembers(teamId) { error, members in
      completion(error as NSError?, members)
    }
  }

  public func teamMember(_ userId: String, _ teamId: String) -> NIMTeamMember? {
    NIMSDK.shared().teamManager.teamMember(userId, inTeam: teamId)
  }

  public func notifyStateForNewMsg(teamId: String?) -> NIMTeamNotifyState {
    if let tid = teamId {
      return NIMSDK.shared().teamManager.notifyState(forNewMsg: tid)
    }
    return NIMTeamNotifyState.all
  }

  public func createTeam(_ accids: [String], _ option: NIMCreateTeamOption,
                         _ completion: @escaping (NSError?, String?, [String]?) -> Void) {
    NIMSDK.shared().teamManager
      .createTeam(option, users: accids) { error, teamid, failedAccids in
        completion(error as NSError?, teamid, failedAccids)
      }
  }

  public func updateTeamAvatar(_ url: String, _ teamId: String,
                               _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().teamManager.updateTeamAvatar(url, teamId: teamId) { error in
      completion(error)
    }
  }

  public func updateTeamIntr(_ intr: String, _ teamId: String,
                             _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().teamManager.updateTeamIntro(intr, teamId: teamId) { error in
      completion(error)
    }
  }

  public func updateTeamName(_ name: String, _ teamId: String,
                             _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().teamManager.updateTeamName(name, teamId: teamId) { error in
      completion(error)
    }
  }

  public func updateTeamCustomInfo(_ info: String, _ teamId: String,
                                   _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().teamManager.updateTeamCustomInfo(info, teamId: teamId) { error in
      completion(error)
    }
  }

  public func dismissTeam(_ teamId: String, _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().teamManager.dismissTeam(teamId) { error in
      completion(error)
    }
  }

  public func quitTeam(_ teamId: String, _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().teamManager.quitTeam(teamId) { error in
      completion(error)
    }
  }

  public func updateTeamNick(_ uid: String, _ newNick: String, _ teamId: String,
                             _ completion: @escaping (Error?) -> Void) {
    print("update team nick : \(uid)  \(newNick)  \(teamId) ")
    NIMSDK.shared().teamManager.updateUserNick(uid, newNick: newNick, inTeam: teamId) { error in
      completion(error)
    }
  }

  public func updateMuteState(_ mute: Bool, _ teamId: String,
                              _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().teamManager.updateMuteState(mute, inTeam: teamId) { error in
      completion(error)
    }
  }

  public func updateNoti(_ state: NIMTeamNotifyState, _ teamId: String,
                         _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().teamManager.update(state, inTeam: teamId) { error in
      completion(error)
    }
  }

  public func updateBeInviteMode(_ mode: NIMTeamBeInviteMode, _ teamId: String,
                                 _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().teamManager.update(mode, teamId: teamId) { error in
      completion(error)
    }
  }

  public func updateInfoMode(_ mode: NIMTeamUpdateInfoMode, _ teamId: String,
                             _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().teamManager.update(mode, teamId: teamId) { error in
      completion(error)
    }
  }

  public func updateInviteMode(_ mode: NIMTeamInviteMode, _ teamId: String,
                               _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().teamManager.update(mode, teamId: teamId) { error in
      completion(error)
    }
  }

  public func addTeamUsers(_ uids: [String], _ teamId: String, _ postscript: String?,
                           _ attach: String?,
                           _ completion: @escaping (Error?, [NIMTeamMember]?) -> Void) {
    NIMSDK.shared().teamManager
      .addUsers(uids, toTeam: teamId, postscript: postscript,
                attach: attach) { error, teamMembers in
        completion(error, teamMembers)
      }
  }

  /// 接受群邀请
  /// - Parameters:
  ///   - teamId: 群组id
  ///   - invitorId: 邀请者ID
  ///   - completion: 邀请后回调
  public func acceptInviteWithTeam(_ teamId: String, _ invitorId: String,
                                   _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().teamManager.acceptInvite(withTeam: teamId, invitorId: invitorId) { error in
      completion(error)
    }
  }

  /// 拒绝群邀请
  /// - Parameters:
  ///   - teamId: 群组id
  ///   - invitorId: 邀请者ID
  ///   - completion: 完成后回调
  public func rejectInviteWithTeam(_ teamId: String, _ invitorId: String,
                                   _ completion: @escaping (Error?) -> Void) {
    NIMSDK.shared().teamManager
      .rejectInvite(withTeam: teamId, invitorId: invitorId, rejectReason: "") { error in
        completion(error)
      }
  }

  /// 查询选项
  /// - Parameters:
  ///   - option: 查询条件
  ///   - completion: 完成回调，本地缓存的群成员信息，如果没有返回nil
  public func searchTeam(option: NIMTeamSearchOption,
                         _ completion: @escaping (Error?, [NIMTeam]?) -> Void) {
    NIMSDK.shared().teamManager.searchTeam(with: option) { error, teams in
      completion(error, teams)
    }
  }
}
