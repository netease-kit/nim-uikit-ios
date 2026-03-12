//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objc
public protocol NEHistorySearchFileCellDelegate: NSObjectProtocol {
  func didClickMoreAction(_ cell: NEHistorySearchFileCell, _ model: MessageFileModel?)
}

@objcMembers
open class NEHistorySearchFileCell: NEChatBaseCell {
  public let avatarImageView = NEUserHeaderView(frame: .zero)
  public let nameLabel = UILabel()
  public let timeLabel = UILabel()
  public let fileBackView = UIView()
  public let fileIconImageView = UIImageView()
  public let fileNameLabel = UILabel()
  public let fileSizeLabel = UILabel()
  public let moreButton = ExpandButton()
  public let lineBottom = UIView()
  public let stateView = FileStateView()
  public weak var currentModel: MessageFileModel?
  public weak var delegate: NEHistorySearchFileCellDelegate?

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupUI()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  public func setupUI() {
    selectionStyle = .none
    backgroundColor = .white

    // 头像
    contentView.addSubview(avatarImageView)
    avatarImageView.translatesAutoresizingMaskIntoConstraints = false
    avatarImageView.layer.cornerRadius = 12
    avatarImageView.clipsToBounds = true

    // 发送者姓名
    contentView.addSubview(nameLabel)
    nameLabel.translatesAutoresizingMaskIntoConstraints = false
    nameLabel.font = .systemFont(ofSize: 14)
    nameLabel.textColor = .ne_darkText

    // 发送时间
    contentView.addSubview(timeLabel)
    timeLabel.translatesAutoresizingMaskIntoConstraints = false
    timeLabel.font = .systemFont(ofSize: 12)
    timeLabel.textColor = .ne_greyText

    contentView.addSubview(fileBackView)
    fileBackView.translatesAutoresizingMaskIntoConstraints = false
    fileBackView.backgroundColor = UIColor(hexString: "#F4F4F4")
    fileBackView.layer.cornerRadius = 4

    // 文件图标
    contentView.addSubview(fileIconImageView)
    fileIconImageView.translatesAutoresizingMaskIntoConstraints = false
    fileIconImageView.contentMode = .scaleAspectFit

    contentView.addSubview(stateView)
    stateView.translatesAutoresizingMaskIntoConstraints = false
    stateView.backgroundColor = .clear

    // 文件名
    contentView.addSubview(fileNameLabel)
    fileNameLabel.translatesAutoresizingMaskIntoConstraints = false
    fileNameLabel.textColor = .ne_greyText
    fileNameLabel.numberOfLines = 1
    fileNameLabel.lineBreakMode = .byTruncatingMiddle

    // 文件大小
    contentView.addSubview(fileSizeLabel)
    fileSizeLabel.translatesAutoresizingMaskIntoConstraints = false
    fileSizeLabel.font = .systemFont(ofSize: 12)
    fileSizeLabel.textColor = .ne_greyText

    // 更多按钮
    contentView.addSubview(moreButton)
    moreButton.translatesAutoresizingMaskIntoConstraints = false
    moreButton.setImage(UIImage.ne_imageNamed(name: "history_file_more"), for: .normal)
    moreButton.addTarget(self, action: #selector(moreButtonAction), for: .touchUpInside)

    contentView.addSubview(lineBottom)
    lineBottom.translatesAutoresizingMaskIntoConstraints = false
    lineBottom.backgroundColor = .funChatLineBorderColor.withAlphaComponent(0.5)

    NSLayoutConstraint.activate([
      // 头像
      avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
      avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      avatarImageView.widthAnchor.constraint(equalToConstant: 24),
      avatarImageView.heightAnchor.constraint(equalToConstant: 24),

      // 发送者姓名
      nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
      nameLabel.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
      nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8),

      // 发送时间
      timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
      timeLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),

      fileBackView.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor, constant: 0),
      fileBackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
      fileBackView.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 16),
      fileBackView.heightAnchor.constraint(equalToConstant: 60),

      // 文件图标
      fileIconImageView.leadingAnchor.constraint(equalTo: fileBackView.leadingAnchor, constant: 10),
      fileIconImageView.centerYAnchor.constraint(equalTo: fileBackView.centerYAnchor, constant: 0),
      fileIconImageView.widthAnchor.constraint(equalToConstant: 48),
      fileIconImageView.heightAnchor.constraint(equalToConstant: 48),

      stateView.centerXAnchor.constraint(equalTo: fileIconImageView.centerXAnchor, constant: 0),
      stateView.centerYAnchor.constraint(equalTo: fileIconImageView.centerYAnchor, constant: 0),
      stateView.widthAnchor.constraint(equalToConstant: 32),
      stateView.heightAnchor.constraint(equalToConstant: 32),

      // 文件名
      fileNameLabel.leadingAnchor.constraint(equalTo: fileIconImageView.trailingAnchor, constant: 12),
      fileNameLabel.topAnchor.constraint(equalTo: fileIconImageView.topAnchor, constant: 2),
      fileNameLabel.trailingAnchor.constraint(equalTo: moreButton.leadingAnchor, constant: -12),

      // 文件大小
      fileSizeLabel.leadingAnchor.constraint(equalTo: fileNameLabel.leadingAnchor),
      fileSizeLabel.bottomAnchor.constraint(equalTo: fileIconImageView.bottomAnchor, constant: -2),
      fileSizeLabel.trailingAnchor.constraint(equalTo: fileNameLabel.trailingAnchor),

      // 更多按钮
      moreButton.trailingAnchor.constraint(equalTo: fileBackView.trailingAnchor, constant: -8),
      moreButton.centerYAnchor.constraint(equalTo: fileIconImageView.centerYAnchor),
      moreButton.widthAnchor.constraint(equalToConstant: 24),
      moreButton.heightAnchor.constraint(equalToConstant: 24),

      lineBottom.leadingAnchor.constraint(equalTo: fileBackView.leadingAnchor, constant: 0),
      lineBottom.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
      lineBottom.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
      lineBottom.heightAnchor.constraint(equalToConstant: 1),
    ])
  }

  public func configure(with model: MessageFileModel) {
    guard let message = model.message,
          let attachment = message.attachment as? V2NIMMessageFileAttachment else {
      return
    }

    currentModel = model
    currentModel?.cell = self

    // 配置发送者信息
    nameLabel.text = model.fullName
    avatarImageView.configHeadData(headUrl: model.avatar,
                                   name: model.shortName ?? "",
                                   uid: ChatMessageHelper.getSenderId(model.message) ?? "")

    // 配置发送时间
    timeLabel.text = formatMessageTime(UInt64(message.createTime))

    // 配置文件信息
    fileNameLabel.text = attachment.name
    fileSizeLabel.text = formatFileSize(attachment.size)

    // 配置文件图标
    fileIconImageView.image = getFileIcon(for: attachment)
  }

  public func formatMessageTime(_ timestamp: UInt64) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
    let formatter = DateFormatter()
    formatter.dateFormat = "M月d日"
    return formatter.string(from: date)
  }

  public func formatFileSize(_ bytes: UInt) -> String {
    let size_B = Double(bytes)
    var size_str = String(format: "%.2f B", size_B)
    if size_B > 1e3 {
      let size_KB = size_B / 1e3
      size_str = String(format: "%.2f KB", size_KB)
      if size_KB > 1e3 {
        let size_MB = size_KB / 1e3
        size_str = String(format: "%.2f MB", size_MB)
        if size_MB > 1e3 {
          let size_GB = size_KB / 1e6
          size_str = String(format: "%.2f GB", size_GB)
        }
      }
    }
    return size_str
  }

  public func getFileIcon(for fileObject: V2NIMMessageFileAttachment) -> UIImage? {
    var imageName = "file_unknown"
    var suffix = (fileObject.name as NSString).pathExtension.lowercased()
    if suffix.isEmpty, let ext = fileObject.ext {
      suffix = ext[(ext.index(after: ext.startIndex)) ..< ext.endIndex].lowercased()
    }
    switch suffix {
    case file_doc_support:
      imageName = "file_doc"
    case file_xls_support:
      imageName = "file_xls"
    case file_img_support:
      imageName = "file_img"
    case file_ppt_support:
      imageName = "file_ppt"
    case file_txt_support:
      imageName = "file_txt"
    case file_audio_support:
      imageName = "file_audio"
    case file_video_support:
      imageName = "file_vedio"
    case file_zip_support:
      imageName = "file_zip"
    case file_pdf_support:
      imageName = "file_pdf"
    case file_html_support:
      imageName = "file_html"
    case "key", "keynote":
      imageName = "file_keynote"
    default:
      imageName = "file_unknown"
    }

    return UIImage.ne_imageNamed(name: imageName)
  }

  override open func uploadProgress(_ progress: UInt) {
    guard let model = currentModel else { return }

    if model.state == .Success {
      stateView.state = .FileOpen
      stateView.isHidden = true
    } else {
      stateView.state = .FileDownload
      stateView.isHidden = false
      stateView.setProgress(Float(model.progress) / 100.0)
    }
  }

  func moreButtonAction() {
    delegate?.didClickMoreAction(self, currentModel)
  }
}
