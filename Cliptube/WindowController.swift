//
//  WindowController.swift
//  Cliptube
//
//  Created by Daniel Vollmer on 05.10.20.
//

import AppKit
import AVKit

class WindowController: NSWindowController {

  @IBOutlet var playerView: AVPlayerView!

  override var windowNibName: NSNib.Name? {
    return NSNib.Name("DocumentWindow")
  }

  // let our main area work as drag handle
  override func mouseDown(with mouseDownEvent: NSEvent) {
    let window = self.window!
    window.performDrag(with: mouseDownEvent)
  }


  override func windowDidLoad() {
    guard let window = self.window else { return }
    guard let document = document as? Document, let asset = document.asset else { return }

    if let naturalSize = asset.tracks(withMediaType: .video).first?.naturalSize {
      window.setContentSize(naturalSize)
      window.contentAspectRatio = naturalSize
    }

    let player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
    player.volume = 0.5
    player.automaticallyWaitsToMinimizeStalling = true
    self.playerView.player = player
  }

  deinit {
    self.playerView?.player?.pause()
  }

}
