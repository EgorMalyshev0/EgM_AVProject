//
//  ViewController.swift
//  #13
//
//  Created by Egor Malyshev on 17.02.2021.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var exportButton: UIButton!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let manager = VideoManager()
    var item: AVPlayerItem?
    var url: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
        
    @IBAction func startPlaying(_ sender: Any) {
        startExporting(helperFunc: showVideo)
    }
    
    @IBAction func exportVideo(_ sender: Any) {
        startExporting(helperFunc: saveVideo)
    }
    
    func startExporting(helperFunc: @escaping ()->()){
        activityIndicator.startAnimating()
        stackView.isHidden = false
        playButton.isEnabled = false
        exportButton.isEnabled = false
        manager.testMerge { (url) in
            self.stackView.isHidden = true
            self.activityIndicator.stopAnimating()
            self.url = url
            helperFunc()
        }
    }
    
    func showVideo() {
        guard let url = self.url else { return }
        let vc = AVPlayerViewController()
        let player = AVPlayer(url: url)
        vc.player = player
        present(vc, animated: true) {
            player.play()
            self.playButton.isEnabled = true
            self.exportButton.isEnabled = true
        }
    }
    
    func saveVideo(){
        guard let url = self.url else { return }
        let alert = UIAlertController(title: nil, message: "Video saved", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: {
            self.playButton.isEnabled = true
            self.exportButton.isEnabled = true
        })
        UISaveVideoAtPathToSavedPhotosAlbum(url.path, self, nil, nil)
        
    }

}

