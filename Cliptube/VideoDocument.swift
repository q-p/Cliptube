//
//  VideoDocument.swift
//  Cliptube
//
//  Created by Daniel Vollmer on 04.10.20.
//

import AppKit
import AVKit
import XCDYouTubeKit

var cascadeOffset: Int = 0

class VideoDocument : NSWindowController, NSWindowDelegate {

  let video: XCDYouTubeVideo
  let asset: AVAsset
  weak var parent: AppDelegate?

  @IBOutlet var playerView: AVPlayerView!

  init(video: XCDYouTubeVideo, asset: AVAsset, parent: AppDelegate) {
    self.video = video
    self.asset = asset
    self.parent = parent
    super.init(window: nil)
    self.shouldCascadeWindows = false
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var windowNibName: NSNib.Name? {
    return "VideoWindow"
  }

  override func windowDidLoad() {
    guard let window = self.window else { return }

    if let naturalSize = asset.tracks(withMediaType: .video).first?.naturalSize {
      window.setContentSize(naturalSize)
      window.contentAspectRatio = naturalSize
    }

    // set the origin to top-left ish with an offset
    if let screenRect = window.screen?.visibleFrame {
      let cascadeFactor = window.frame.height - window.contentLayoutRect.height
      let offsetFromLeftOfScreen: CGFloat = 100 + CGFloat(cascadeOffset) * cascadeFactor
      let offsetFromTopOfScreen: CGFloat = 100 + CGFloat(cascadeOffset) * cascadeFactor
      let newOriginY = screenRect.maxY - window.frame.height - offsetFromTopOfScreen
      window.setFrameOrigin(NSPoint(x: screenRect.minX + offsetFromLeftOfScreen, y: newOriginY))
      cascadeOffset += 1
    }

    let player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
    player.volume = 0.5
    player.automaticallyWaitsToMinimizeStalling = true
    self.playerView.player = player
    window.title = self.video.title
  }

  func windowWillClose(_ notification: Notification) {
    guard let parent = parent else { return }
    self.playerView.player?.pause()
    parent.videos.remove(self)
    if parent.videos.count == 0 {
      cascadeOffset = 0 // let's start over
    }
  }

}
