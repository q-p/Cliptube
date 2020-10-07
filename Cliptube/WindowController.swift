//
//  WindowController.swift
//  Cliptube
//
//  Created by Daniel Vollmer on 05.10.20.
//

import AppKit
import AVKit

var shouldUseAutoPlacement = false

class WindowController: NSWindowController {

  @IBOutlet var playerView: AVPlayerView!


  override var windowNibName: NSNib.Name? {
    return NSNib.Name("DocumentView")
  }

  override func windowDidLoad() {
    guard let window = self.window else { return }

    // set the origin to top-left ish with an offset because it doesn't seem to work for the first window
    if !shouldUseAutoPlacement, let screenRect = window.screen?.visibleFrame {
      let offsetFromLeftOfScreen: CGFloat = 100
      let offsetFromTopOfScreen: CGFloat = 100
      let newOriginY = screenRect.maxY - window.frame.height - offsetFromTopOfScreen
      window.setFrameOrigin(NSPoint(x: screenRect.minX + offsetFromLeftOfScreen, y: newOriginY))
      shouldUseAutoPlacement = true
    }

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
