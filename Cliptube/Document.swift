//
//  Document.swift
//  Cliptube
//
//  Created by Daniel Vollmer on 04.10.20.
//

import AppKit
import AVKit
import XCDYouTubeKit

class Document: NSDocument {

  var video: XCDYouTubeVideo?
  var asset: AVAsset?
  var ytURL: URL?

  // make sure to use our window controller
  override func makeWindowControllers() {
    addWindowController(WindowController())
  }

  // we can load on background threads
  override class func canConcurrentlyReadDocuments(ofType typeName: String) -> Bool {
    return true
  }

  // display the video (as we have no fileURL)
  override var displayName: String! {
    get { return video!.title }
    set { }
  }

  // disables the icon and path display in the titlebar (which doesn't work properly for non-file URLs)
  override var fileURL: URL? {
    get { return nil }
    set { ytURL = newValue }
  }


  override func read(from url: URL, ofType typeName: String) throws {
    guard let id = findVideoIDs(url.absoluteString).first else {
      throw NSError(domain: "de.maven.Cliptube", code: -41, userInfo: [
        NSLocalizedDescriptionKey: "Couldn't find YouTube ID in URL"])
    }

    try self.video = XCDYouTubeClient.default().blockingGetVideoWithIdentifier(id)
    guard let asset = getAVAsset(video: video!) else {
      throw NSError(domain: "de.maven.Cliptube", code: -42, userInfo: [
        NSLocalizedDescriptionKey: "Couldn't obtain AVAsset for video"])
    }
    self.asset = asset
  }

}
