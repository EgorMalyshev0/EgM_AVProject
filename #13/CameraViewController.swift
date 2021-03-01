//
//  CameraViewController.swift
//  #13
//
//  Created by Egor Malyshev on 24.02.2021.
//

import UIKit
import Photos

class CameraViewController: UIViewController {
    
    @IBOutlet weak var capturePreviewView: UIView!
    @IBOutlet weak var toggleFlashButton: UIButton!
    @IBOutlet weak var toggleCamerasButton: UIView!
    @IBOutlet weak var photoModeButton: UIButton!
    @IBOutlet weak var videoModeButton: UIButton!
    @IBOutlet weak var captureButton: UIButton!
    
    let cameraController = CameraController()
    
    var videoRecordingStarted = false
    
    override var prefersStatusBarHidden: Bool { return true }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureCameraController()
    }
    
    @IBAction func captureButtonTapped(_ sender: Any) {
        switch cameraController.currentMode {
        case .photo:
            cameraController.captureImage {(data, error) in
                guard let data = data, let image = UIImage(data: data) else {
                    print(error ?? "Image capture error")
                    return
                }
                UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
            }
        case .video:
            if videoRecordingStarted {
                videoRecordingStarted = false
                captureButton.setImage(UIImage(systemName: "circle.fill"), for: .normal)
                photoModeButton.isHidden = false
                videoModeButton.isHidden = false
                toggleFlashButton.isHidden = false
                toggleCamerasButton.isHidden = false
                cameraController.toggleMovieRecording { (url, error) in
                    print(error ?? "Video recording error")
                }
            } else if !videoRecordingStarted {
                videoRecordingStarted = true
                captureButton.setImage(UIImage(systemName: "square.fill"), for: .normal)
                photoModeButton.isHidden = true
                videoModeButton.isHidden = true
                toggleFlashButton.isHidden = true
                toggleCamerasButton.isHidden = true
                cameraController.toggleMovieRecording { (url, error) in
                    guard let url = url else {
                        print(error ?? "Video recording error")
                        return
                    }
                    let alert = UIAlertController(title: nil, message: "Video saved", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alert.addAction(ok)
                    self.present(alert, animated: true, completion: nil)
                    UISaveVideoAtPathToSavedPhotosAlbum(url.path, self, nil, nil)
                }
            }
        }
        
    }
    
    @IBAction func turnOnPhotoMode(_ sender: Any) {
        cameraController.switchMode(toMode: .photo)
        photoModeButton.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        photoModeButton.imageView?.tintColor = .systemYellow
        videoModeButton.setImage(UIImage(systemName: "video"), for: .normal)
        videoModeButton.imageView?.tintColor = .white
        captureButton.imageView?.tintColor = .white
    }
    
    @IBAction func turnOnVideoMode(_ sender: Any) {
        cameraController.switchMode(toMode: .video)
        videoModeButton.setImage(UIImage(systemName: "video.fill"), for: .normal)
        videoModeButton.imageView?.tintColor = .systemYellow
        photoModeButton.setImage(UIImage(systemName: "camera"), for: .normal)
        photoModeButton.imageView?.tintColor = .white
        captureButton.imageView?.tintColor = .red
    }
    
    @IBAction func toggleFlash(_ sender: Any) {
        if cameraController.flashMode == .on {
            cameraController.flashMode = .off
            toggleFlashButton.setImage(UIImage(named: "Flash Off Icon"), for: .normal)
            toggleFlashButton.imageView?.tintColor = .white
        }
        else {
            cameraController.flashMode = .on
            toggleFlashButton.setImage(UIImage(named: "Flash On Icon"), for: .normal)
            toggleFlashButton.imageView?.tintColor = .yellow
        }
    }
    
    @IBAction func toggleCamera(_ sender: Any) {
        do {
            try cameraController.switchCameras()
        }
        catch {
            print(error)
        }
    }
    
    func configureCameraController() {
        cameraController.prepareCamera {(error) in
            if let error = error {
                print(error)
            }
            self.displayPreview()
        }
    }
    
    func displayPreview() {
        do {
            try cameraController.preparePreview()
        } catch {
            print("Capture session is missing")
        }
        if let previewLayer = cameraController.previewLayer{
            capturePreviewView.layer.insertSublayer(previewLayer, at: 0)
            previewLayer.frame = capturePreviewView.frame
        }
        
    }

}
