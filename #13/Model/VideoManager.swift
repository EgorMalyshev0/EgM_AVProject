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
        
        let layerInstruction1 = layerInstructionForTrack(track: videoTrack1, asset: video1, atTime: .zero)
        layerInstruction1.setTransformRamp(fromStart: assetTrack1.preferredTransform, toEnd: CGAffineTransform(translationX: outputSize.width, y: 0), timeRange: CMTimeRange(start: video2InsertTime, duration: transitionDuration))
        layerInstructions.append(layerInstruction1)
        
        let layerInstruction2 = layerInstructionForTrack(track: videoTrack2, asset: video2, atTime: video2InsertTime)
        layerInstruction2.setTransformRamp(fromStart: CGAffineTransform(translationX: -outputSize.width, y: 0), toEnd: assetTrack2.preferredTransform, timeRange: CMTimeRange(start: video2InsertTime, duration: transitionDuration))
        layerInstruction2.setOpacityRamp(fromStartOpacity: 1, toEndOpacity: 0, timeRange: CMTimeRange(start: video3InsertTime, duration: transitionDuration))
        layerInstructions.append(layerInstruction2)
        
        let layerInstruction3 = layerInstructionForTrack(track: videoTrack3, asset: video3, atTime: video3InsertTime)
        let startTransform = CGAffineTransform(translationX: outputSize.width / 2, y: outputSize.height / 2).scaledBy(x: 0.001, y: 0.001)
        layerInstruction3.setTransformRamp(fromStart: startTransform, toEnd: assetTrack3.preferredTransform, timeRange: CMTimeRange(start: video3InsertTime, duration: transitionDuration))
        layerInstructions.append(layerInstruction3)
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(start: .zero, duration: composition.duration)
        mainInstruction.layerInstructions = layerInstructions
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        videoComposition.renderSize = outputSize
        videoComposition.instructions = [mainInstruction]

        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: outputSize)
        let overlayLayer = CALayer()
        overlayLayer.frame = CGRect(origin: .zero, size: outputSize)
        addAnimation(toLayer: overlayLayer, duration: composition.duration)
        let outputLayer = CALayer()
        outputLayer.frame = CGRect(origin: .zero, size: outputSize)
        outputLayer.addSublayer(videoLayer)
        outputLayer.addSublayer(overlayLayer)

        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer,
                                                                             in: outputLayer)
        completion(composition, videoComposition)
    }
    
    func testMerge(completion: @escaping (URL?) -> Void) {
        DispatchQueue.global().async {
            self.doMerge { (composition, videoComposition) in
                guard let exporter = AVAssetExportSession(
                  asset: composition,
                  presetName: AVAssetExportPresetHighestQuality)
                  else {
                    print("Cannot create export session.")
                    completion(nil)
                    return
                }
                let videoName = "mergedVideo"
                let exportURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(videoName).appendingPathExtension("mov")
                
                exporter.videoComposition = videoComposition
                exporter.outputFileType = .mov
                exporter.outputURL = exportURL
                
                try? FileManager.default.removeItem(at: exportURL)

                exporter.exportAsynchronously {
                  DispatchQueue.main.async {
                    switch exporter.status {
                    case .completed:
                      completion(exportURL)
                    default:
                      print("Something went wrong during export.")
                      print(exporter.error ?? "unknown error")
                      completion(nil)
                      break
                    }
                  }
                }
            }
        }
    }
    
    fileprivate func layerInstructionForTrack(track: AVCompositionTrack, asset: AVAsset, atTime: CMTime) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
        
        let transform = assetTrack.preferredTransform
        instruction.setTransform(transform, at: atTime)
        return instruction
    }
    
    fileprivate func addAnimation(toLayer overlayLayer: CALayer, duration: CMTime){
        let size = CGSize(width: 100, height: 100)
        let origin = CGPoint(x: overlayLayer.frame.minX, y: overlayLayer.frame.maxY - size.height)
        let circle = UIImage(systemName: "circle.fill")?.withTintColor(.white)
        let circleLayer = CALayer()
        circleLayer.frame = CGRect(origin: origin, size: size)
        let maskLayer = CALayer()
        maskLayer.frame = circleLayer.bounds
        maskLayer.contents = circle?.cgImage
        circleLayer.mask = maskLayer
        circleLayer.backgroundColor = UIColor.white.cgColor
        circleLayer.opacity = 0.5
        overlayLayer.addSublayer(circleLayer)
        let startPosition = circleLayer.position
        let animation = CABasicAnimation(keyPath: "position")
        animation.fromValue = startPosition
        animation.toValue = CGPoint(x: overlayLayer.frame.maxX - size.width / 2, y: overlayLayer.frame.minY + size.height / 2)
        animation.duration = Double(CMTimeGetSeconds(duration))
        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.isRemovedOnCompletion = true
        circleLayer.add(animation, forKey: "position")
    }
}
