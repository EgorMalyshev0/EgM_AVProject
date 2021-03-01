//
//  CameraController.swift
//  #13
//
//  Created by Egor Malyshev on 24.02.2021.
//

import AVFoundation

enum CameraControllerError: Swift.Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case unknown
}

enum Mode {
    case photo
    case video
}

class CameraController: NSObject {
    
    var captureSession: AVCaptureSession?
    
    var videoDeviceInput: AVCaptureDeviceInput?

    var photoOutput: AVCapturePhotoOutput?
    var movieFileOutput: AVCaptureMovieFileOutput?
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera], mediaType: .video, position: .unspecified)
    
    var flashMode = AVCaptureDevice.FlashMode.off
    
    var photoCaptureCompletionBlock: ((Data?, Error?) -> Void)?
    var videoCaptureCompletionBlock: ((URL?, Error?) -> Void)?
    
    var currentMode = Mode.photo
    
    func prepareCamera(completion: @escaping (Error?) -> Void) {
        func createCaptureSession() {
            self.captureSession = AVCaptureSession()
        }
        
        func configureCaptureDevices() throws {
            guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
            do {
                var defaultVideoDevice: AVCaptureDevice?
                                
                if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                    defaultVideoDevice = dualCameraDevice
                } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                    defaultVideoDevice = backCameraDevice
                } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                    defaultVideoDevice = frontCameraDevice
                }
                guard let videoDevice = defaultVideoDevice else {
                    print("Default video device is unavailable.")
                    throw CameraControllerError.noCamerasAvailable
                }
                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                
                if captureSession.canAddInput(videoDeviceInput) {
                    captureSession.addInput(videoDeviceInput)
                    self.videoDeviceInput = videoDeviceInput
                } else {
                    print("Couldn't add video device input to the session.")
                    throw CameraControllerError.noCamerasAvailable
                }
            } catch {
                print("Couldn't create video device input: \(error)")
                throw CameraControllerError.noCamerasAvailable
            }
            
            do {
                let audioDevice = AVCaptureDevice.default(for: .audio)
                let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)
                
                if captureSession.canAddInput(audioDeviceInput) {
                    captureSession.addInput(audioDeviceInput)
                } else {
                    print("Could not add audio device input to the session")
                }
            } catch {
                print("Could not create audio device input: \(error)")
            }
            
        }
        
        func configurePhotoOutput() throws {
            guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
            
            self.photoOutput = AVCapturePhotoOutput()
            self.photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)
            if captureSession.canAddOutput(self.photoOutput!) { captureSession.addOutput(self.photoOutput!) }
            
            captureSession.startRunning()
        }
        DispatchQueue(label: "prepareCamera").async {
            do {
                createCaptureSession()
                try configureCaptureDevices()
                try configurePhotoOutput()
            }
            catch {
                DispatchQueue.main.async {
                    completion(error)
                }
                return
            }
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
    
    func preparePreview() throws {
        guard let captureSession = self.captureSession, captureSession.isRunning else { throw CameraControllerError.captureSessionIsMissing }
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.previewLayer?.connection?.videoOrientation = .portrait
    }
    
    func switchCameras() throws {
        guard let videoDeviceInput = self.videoDeviceInput, let captureSession = self.captureSession, captureSession.isRunning else { throw CameraControllerError.captureSessionIsMissing }
        let currentVideoDevice = videoDeviceInput.device
        let currentPosition = currentVideoDevice.position
        let preferredPosition: AVCaptureDevice.Position
        
        func doSwitch(preferredPosition: AVCaptureDevice.Position){
            let devices = self.videoDeviceDiscoverySession.devices
            var newVideoDevice: AVCaptureDevice? = nil
            
            if let device = devices.first(where: { $0.position == preferredPosition }) {
                newVideoDevice = device
            }
            
            if let videoDevice = newVideoDevice {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                    
                    captureSession.beginConfiguration()
                    
                    if let currentVideoDeviceInput = self.videoDeviceInput {
                        captureSession.removeInput(currentVideoDeviceInput)
                    }
                    
                    if captureSession.canAddInput(videoDeviceInput) {
                        captureSession.addInput(videoDeviceInput)
                        self.videoDeviceInput = videoDeviceInput
                    } else {
                        print("error")
                    }
                    
                    captureSession.commitConfiguration()
                } catch {
                    print("Error occurred while creating video device input: \(error)")
                }
            }
        }
        
        switch currentPosition {
        case .back:
            preferredPosition = .front
        case .front, .unspecified:
            preferredPosition = .back
        @unknown default:
            print("Unknown capture position. Defaulting to back, dual-camera.")
            preferredPosition = .back
        }
        doSwitch(preferredPosition: preferredPosition)
    }
    
    func switchMode(toMode: Mode){
        switch toMode {
        case .photo:
            currentMode = .photo
            if let captureSesion = self.captureSession, let movieFileOutput = self.movieFileOutput{
                captureSesion.beginConfiguration()
                captureSesion.removeOutput(movieFileOutput)
                captureSesion.sessionPreset = .photo
                self.movieFileOutput = nil
                captureSesion.commitConfiguration()
            }
        case .video:
            currentMode = .video
            if let captureSesion = self.captureSession {
                self.movieFileOutput = AVCaptureMovieFileOutput()
                if captureSesion.canAddOutput(self.movieFileOutput!) {
                    captureSesion.beginConfiguration()
                    captureSesion.addOutput(self.movieFileOutput!)
                    captureSesion.sessionPreset = .high
                    captureSesion.commitConfiguration()
                }
            }
            
        }
        
    }
    
    func captureImage(completion: @escaping (Data?, Error?) -> Void) {
        guard let captureSession = captureSession, captureSession.isRunning else {
            completion(nil, CameraControllerError.captureSessionIsMissing)
            return
        }
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = self.flashMode

        self.photoOutput?.capturePhoto(with: settings, delegate: self)
        self.photoCaptureCompletionBlock = completion
    }
    
    func toggleMovieRecording(completion: @escaping (URL?, Error?) -> Void){
        guard let movieFileOutput = self.movieFileOutput else { return }
        if !movieFileOutput.isRecording {
            let outputFileName = NSUUID().uuidString
            let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
            movieFileOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
            self.videoCaptureCompletionBlock = completion
        } else {
            guard let captureSession = self.captureSession, captureSession.isRunning else {
                completion(nil, CameraControllerError.captureSessionIsMissing)
                return
            }
            movieFileOutput.stopRecording()
        }
    }
    
    func startRecording(completion: @escaping (URL?, Error?) -> Void) {
        guard let movieFileOutput = self.movieFileOutput else { return }
        if !movieFileOutput.isRecording {
            let outputFileName = NSUUID().uuidString
            let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
            movieFileOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
            self.videoCaptureCompletionBlock = completion
        }
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
//    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Swift.Error?) {
//        if let error = error { self.photoCaptureCompletionBlock?(nil, error) }
//        else if let buffer = photoSampleBuffer, let data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: buffer, previewPhotoSampleBuffer: nil){
//            self.photoCaptureCompletionBlock?(data, nil)
//        }
//        else {
//            self.photoCaptureCompletionBlock?(nil, CameraControllerError.unknown)
//        }
//    }
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error { self.photoCaptureCompletionBlock?(nil, error) }
        else if let data = photo.fileDataRepresentation() {
            self.photoCaptureCompletionBlock?(data, nil)
        }
        else {
            self.photoCaptureCompletionBlock?(nil, CameraControllerError.unknown)
        }
    }
}
extension CameraController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            self.videoCaptureCompletionBlock?(nil, error)
        } else {
            self.videoCaptureCompletionBlock?(outputFileURL, nil)
        }
    }
}
