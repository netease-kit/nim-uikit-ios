
// Copyright (c) 2022 NetEase, Inc.  All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.


import UIKit
import NEKitCommon

protocol VideoToolBarDelegate: AnyObject {
    func didClickPause()
    func didClickPlay()
    func didSeek(_ progress: Float)
    func didStopRefreshProgress()
    func didStartRefreshProgress()
}

public class VideoToolBar: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    var total: Int = 0
    
    weak var delegate: VideoToolBarDelegate?
    
    public lazy var playBtn: ExpandButton = {
        let btn = ExpandButton()
        btn.setImage(coreLoader.loadImage("video_stop_icon"), for: .normal)
        btn.setImage(coreLoader.loadImage("video_play_icon"), for: .selected)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    public lazy var currentTime: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = NEConstant.defaultTextFont(12.0)
        label.text = "00:00"
        return label
    }()
    
    public lazy var totalTime: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = NEConstant.defaultTextFont(12.0)
        return label
    }()
    
    public lazy var progressSlider: UISlider = {
        let slider = UISlider()
        slider.tintColor = .white
        slider.thumbTintColor = .white
        slider.maximumValue = 1
        slider.minimumValue = 0
        slider.value = 0
        slider.minimumTrackTintColor = .white
        slider.isContinuous = true
        slider.maximumTrackTintColor = NEConstant.hexRGB(0x000000).withAlphaComponent(0.3)
        slider.setThumbImage(coreLoader.loadImage("thumb"), for: .normal)
        slider.setThumbImage(coreLoader.loadImage("thumb"), for: .highlighted)
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupUI(){
        addSubview(playBtn)
        NSLayoutConstraint.activate([
            playBtn.leftAnchor.constraint(equalTo: leftAnchor),
            playBtn.centerYAnchor.constraint(equalTo: centerYAnchor),
            playBtn.widthAnchor.constraint(equalToConstant: 60.0)
        ])
        playBtn.addTarget(self, action: #selector(playClick(_:)), for: .touchUpInside)
        
        addSubview(currentTime)
        NSLayoutConstraint.activate([
            currentTime.centerYAnchor.constraint(equalTo: centerYAnchor),
            currentTime.leftAnchor.constraint(equalTo: leftAnchor, constant: 48.0)
        ])
        
        addSubview(progressSlider)
        NSLayoutConstraint.activate([
            progressSlider.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressSlider.leftAnchor.constraint(equalTo: leftAnchor, constant: 90),
            progressSlider.rightAnchor.constraint(equalTo: rightAnchor, constant: -55)
        ])
        progressSlider.addTarget(self, action: #selector(sliderChange), for: .valueChanged)
        progressSlider.addTarget(self, action: #selector(sliderTouchUp), for: .touchUpInside)
        progressSlider.addTarget(self, action: #selector(sliderTouchUp), for: .touchUpOutside)
        progressSlider.addTarget(self, action: #selector(sliderTouchDown), for: .touchDown)
        
        addSubview(totalTime)
        NSLayoutConstraint.activate([
            totalTime.rightAnchor.constraint(equalTo: rightAnchor, constant: -15.0),
            totalTime.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
    }
    
    @objc func sliderChange(){
        delegate?.didSeek(progressSlider.value)
        if playBtn.isSelected == true {
            let current = Float(total) * progressSlider.value
            currentTime.text = Date.getFormatPlayTime((Double(current)/1000.0))
        }
    }
    
    @objc func sliderTouchUp(){
        delegate?.didStartRefreshProgress()
        delegate?.didSeek(progressSlider.value)
    }
    
    @objc func sliderTouchDown(){
        delegate?.didStopRefreshProgress()
    }
    
    @objc func playClick(_ btn: ExpandButton){
        btn.isSelected = !btn.isSelected
        if btn.isSelected == true {
            delegate?.didClickPause()
        }else {
            delegate?.didClickPlay()
        }
    }
    
    public func resetState(){
        playBtn.isSelected = true
        progressSlider.value = 0
        currentTime.text = "00:00"
    }

}
