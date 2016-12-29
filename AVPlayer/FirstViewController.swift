//
//  FirstViewController.swift
//  AVPlayer
//
//  Created by SW on 2016/12/1.
//  Copyright © 2016年 WY. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {

    var playerView:PlayerView!
    var myLabel:MyLabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        playerView = PlayerView.init(frame: CGRect(x: 0, y: 200, width: UIScreen.main.bounds.width, height: 300))
        playerView.url = URL.init(string: "http://wvideo.spriteapp.cn/video/2016/0215/56c1809735217_wpd.mp4")
        playerView.isLandscape = true
        playerView.autoFullScreen = true
        playerView.playVideo()
        playerView.endPlay = {
            print("播放结束")
        }
        playerView.back = {
            print("点击了返回按钮")
        }
        self.view.addSubview(playerView)
        myLabel = MyLabel(frame: CGRect(x: 100, y: 60, width: 100, height: 30))
        myLabel.text = "你好呀!"
        self.view.addSubview(myLabel)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playerView.stopPlay()
    }
    
    deinit {
        print("控制器被销毁")
    }
}
