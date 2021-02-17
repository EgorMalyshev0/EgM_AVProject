//
//  ViewController.swift
//  #13
//
//  Created by Egor Malyshev on 17.02.2021.
//

import UIKit
import AVFoundation
import AVKit

class AssetStore {
    
    var video1: AVAsset
    var video2: AVAsset
    var video3: AVAsset
    var audio1: AVAsset
    var audio2: AVAsset
    
    init(video1: AVAsset, video2: AVAsset, video3: AVAsset, audio1: AVAsset, audio2: AVAsset) {
        self.video1 = video1
        self.video2 = video2
        self.video3 = video3
        self.audio1 = audio1
        self.audio2 = audio2
    }
    
    static func asset(resource: String, type: String) -> AVAsset {
        guard let path = Bundle.main.path(forResource: resource, ofType: type) else { fatalError("Couldn't load asset") }
        let url = URL(fileURLWithPath: path)
        return AVAsset(url: url)
    }
    
    static func testStore() -> AssetStore {
        return AssetStore(video1: asset(resource: "video1", type: "mp4"),
                          video2: asset(resource: "video2", type: "mp4"),
                          video3: asset(resource: "video3", type: "mp4"),
                          audio1: asset(resource: "audio1", type: "mp3"),
                          audio2: asset(resource: "audio2", type: "mp3"))
    }
    
    func compose() -> AVAsset {
        let composition = AVMutableComposition()
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { fatalError() }
        guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { fatalError() }
        
        func insertVideo(asset: AVAsset, at: CMTime) {
            try? videoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: asset.tracks(withMediaType: .video)[0], at: at)
        }
        
        func insertAudio(asset: AVAsset, at: CMTime) {
            
        }
                
        insertVideo(asset: video1, at: .zero)
        insertVideo(asset: video2, at: video1.duration)
        insertVideo(asset: video3, at: video1.duration + video2.duration)
        try? audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: video1.duration + video2.duration), of: audio1.tracks(withMediaType: .audio)[0], at: .zero)
        try? audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: video3.duration), of: audio2.tracks(withMediaType: .audio)[0], at: video1.duration + video2.duration)
        
        return composition
    }
}

class ViewController: UIViewController {
    
    let store = AssetStore.testStore()
    
    var asset: AVAsset { return store.compose() }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
        
    @IBAction func startPlaying(_ sender: Any) {
        let vc = AVPlayerViewController()
        let playerItem = AVPlayerItem(asset: self.asset)
        let player = AVPlayer(playerItem: playerItem)
        vc.player = player
        present(vc, animated: true, completion: nil)
    }

}

