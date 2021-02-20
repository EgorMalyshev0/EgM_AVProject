//
//  AssetCreator.swift
//  #13
//
//  Created by Egor Malyshev on 18.02.2021.
//

import Foundation
import AVFoundation
import UIKit

class VideoManager {
    
    let store = AssetStore.testStore()
    
    private var video1: AVAsset { return store.video1 }
    private var video2: AVAsset { return store.video2 }
    private var video3: AVAsset { return store.video3 }
    private var audio1: AVAsset { return store.audio1 }
    private var audio2: AVAsset { return store.audio2 }
    
    private let outputSize = CGSize(width: 1920, height: 1080)
    
    fileprivate func doMerge(completion: @escaping (AVMutableComposition, AVMutableVideoComposition) -> Void) {
        var layerInstructions:[AVMutableVideoCompositionLayerInstruction] = []
        let transitionDuration = CMTime(seconds: 1, preferredTimescale: 600)
        
        let composition = AVMutableComposition()
        
        let video2InsertTime = video1.duration - transitionDuration
        let video3InsertTime = video2InsertTime + video2.duration - transitionDuration
        
        let assetTrack1 = video1.tracks(withMediaType: .video)[0]
        let assetTrack2 = video2.tracks(withMediaType: .video)[0]
        let assetTrack3 = video3.tracks(withMediaType: .video)[0]
        let assetAudioTrack1 = audio1.tracks(withMediaType: .audio)[0]
        let assetAudioTrack2 = audio2.tracks(withMediaType: .audio)[0]
        
        guard let videoTrack1 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { fatalError() }
        guard let videoTrack2 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { fatalError() }
        guard let videoTrack3 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { fatalError() }
        guard let audioTrack1 = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { fatalError() }
        guard let audioTrack2 = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { fatalError() }
        
        try? videoTrack1.insertTimeRange(CMTimeRange(start: .zero, duration: video1.duration), of: assetTrack1, at: .zero)
        try? videoTrack2.insertTimeRange(CMTimeRange(start: .zero, duration: video2.duration), of: assetTrack2, at: video2InsertTime)
        try? videoTrack3.insertTimeRange(CMTimeRange(start: .zero, duration: video3.duration), of: assetTrack3, at: video3InsertTime)
        try? audioTrack1.insertTimeRange(CMTimeRange(start: .zero, duration: video1.duration + video2.duration - transitionDuration), of: assetAudioTrack1, at: .zero)
        try? audioTrack2.insertTimeRange(CMTimeRange(start: .zero, duration: video3.duration - transitionDuration), of: assetAudioTrack2, at: video3InsertTime + transitionDuration)
        
        let layerInstruction1 = layerInstructionForTrack(track: videoTrack1, asset: video1, standardSize: outputSize, atTime: .zero)
        layerInstruction1.setTransformRamp(fromStart: assetTrack1.preferredTransform, toEnd: CGAffineTransform(translationX: outputSize.width, y: 0), timeRange: CMTimeRange(start: video2InsertTime, duration: transitionDuration))
        layerInstructions.append(layerInstruction1)
        
        let layerInstruction2 = layerInstructionForTrack(track: videoTrack2, asset: video2, standardSize: outputSize, atTime: video2InsertTime)
        layerInstruction2.setTransformRamp(fromStart: CGAffineTransform(translationX: -outputSize.width, y: 0), toEnd: assetTrack2.preferredTransform, timeRange: CMTimeRange(start: video2InsertTime, duration: transitionDuration))
        layerInstruction2.setOpacityRamp(fromStartOpacity: 1, toEndOpacity: 0, timeRange: CMTimeRange(start: video3InsertTime, duration: transitionDuration))
        layerInstructions.append(layerInstruction2)
        
        let layerInstruction3 = layerInstructionForTrack(track: videoTrack3, asset: video3, standardSize: outputSize, atTime: video3InsertTime)
        let startTransform = CGAffineTransform(translationX: outputSize.width / 2, y: outputSize.height / 2).scaledBy(x: 0.001, y: 0.001)
        layerInstruction3.setTransformRamp(fromStart: startTransform, toEnd: assetTrack3.preferredTransform, timeRange: CMTimeRange(start: video3InsertTime, duration: transitionDuration))
        layerInstructions.append(layerInstruction3)
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.backgroundColor = UIColor.clear.cgColor
        mainInstruction.timeRange = CMTimeRangeMake(start: .zero, duration: video1.duration + video2.duration + video3.duration - transitionDuration - transitionDuration)
        mainInstruction.layerInstructions = layerInstructions
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [mainInstruction]
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        videoComposition.renderSize = outputSize
        
        completion(composition, videoComposition)
    }
    
    func merge(completion: @escaping (URL?) -> Void) {
        DispatchQueue.global().async {
            self.doMerge { (composition, videoComposition) in
                let exporter = AVAssetExportSession.init(asset: composition, presetName: AVAssetExportPresetHighestQuality)
                let path = NSTemporaryDirectory().appending("mergedVideo.mp4")
                let exportURL = URL.init(fileURLWithPath: path)
                
                try? FileManager.default.removeItem(at: exportURL)
                
                exporter?.outputURL = exportURL
                exporter?.outputFileType = AVFileType.mp4
                exporter?.shouldOptimizeForNetworkUse = true
                exporter?.videoComposition = videoComposition
                exporter?.exportAsynchronously(completionHandler: {
                    DispatchQueue.main.async {
                        self.exportDidFinish(exporter: exporter, videoURL: exportURL, completion: completion)
                    }
                })
            }
        }
    }
    
    fileprivate func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        return (assetOrientation, isPortrait)
    }
    
    fileprivate func layerInstructionForTrack(track: AVCompositionTrack, asset: AVAsset, standardSize:CGSize, atTime: CMTime) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
        
        let transform = assetTrack.preferredTransform
        instruction.setTransform(transform, at: atTime)
        return instruction
    }
    
    fileprivate func exportDidFinish(exporter:AVAssetExportSession?, videoURL: URL, completion: @escaping (URL?) -> Void) -> Void {
        if exporter?.status == AVAssetExportSession.Status.completed {
            completion(videoURL)
        }
        else if exporter?.status == AVAssetExportSession.Status.failed {
            completion(nil)
            print("Failed to export video")
        }
    }
}
