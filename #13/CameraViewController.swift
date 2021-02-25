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
    
    let cameraController = CameraController()
    
    override var prefersStatusBarHidden: Bool { return true }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureCameraController()
    }
    
    @IBAction func captureButtonTapped(_ sender: Any) {
        cameraController.captureImage {(data, error) in
            guard let data = data, let image = UIImage(data: data) else {
                print(error ?? "Image capture error")
                return
            }
            try? PHPhotoLibrary.shared().performChangesAndWait {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
        }
    }
    
    @IBAction func turnOnPhotoMode(_ sender: Any) {
    }
    
    @IBAction func turnOnVideoMode(_ sender: Any) {
    }
    
    @IBAction func toggleFlash(_ sender: Any) {
        if cameraController.flashMode == .on {
            cameraController.flashMode = .off
            toggleFlashButton.setImage(UIImage(named: "Flash Off Icon"), for: .normal)
        }
        
        else {
            cameraController.flashMode = .on
            toggleFlashButton.setImage(UIImage(named: "Flash On Icon"), for: .normal)
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
