//
//  AppDelegate.swift
//  Cliptube
//
//  Created by Daniel Vollmer on 03.10.20.
//

import AppKit
import XCDYouTubeKit
import Combine

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  var pbWatcher: AnyCancellable?
  var videos = Set<VideoDocument>()

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    pbWatcher = PasteboardPublisher().sink { maybeUrls in
      for id in findVideoIDs(maybeUrls) {

        if let existingDocument = self.videos.first(where: { $0.video.identifier == id }) {
          existingDocument.window?.makeKeyAndOrderFront(self)
          continue
        }

        XCDYouTubeClient.default().getVideoWithIdentifier(id) { [weak self] (video, error) in
          guard let self = self else { return }
          if let video = video, let asset = getAVAsset(video: video) {
            let newVideo = VideoDocument(video: video, asset: asset, parent: self)
            self.videos.insert(newVideo)
            newVideo.showWindow(self)
          } else if let error = error {
            print(error.localizedDescription)
          }
        }
      }
    }
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    pbWatcher = nil
    videos.removeAll()
  }

}

