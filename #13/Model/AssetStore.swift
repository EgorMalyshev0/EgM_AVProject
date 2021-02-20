//
//  AssetStore.swift
//  #13
//
//  Created by Egor Malyshev on 18.02.2021.
//

import Foundation
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
    
    private static func asset(resource: String, type: String) -> AVAsset {
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
    
}
