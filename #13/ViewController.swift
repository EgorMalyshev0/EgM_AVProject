//
//  ViewController.swift
//  #13
//
//  Created by Egor Malyshev on 17.02.2021.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let manager = VideoManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
        
    @IBAction func startPlaying(_ sender: Any) {
        activityIndicator.startAnimating()
        stackView.isHidden = false
        manager.merge { (url) in
            self.stackView.isHidden = true
            self.activityIndicator.stopAnimating()
            if let url = url {
                self.showVideo(url)
            }
        }
    }
    
    @IBAction func exportVideo(_ sender: Any) {
        
    }
    
    func showVideo(_ url: URL) {
        let vc = AVPlayerViewController()
        let player = AVPlayer(url: url)
        vc.player = player
        present(vc, animated: true) {
            player.play()
        }
    }

}

