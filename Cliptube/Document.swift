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


  override class var autosavesInPlace: Bool { get { return true } }
  // we can read/write on background threads
  override class func canConcurrentlyReadDocuments(ofType typeName: String) -> Bool {
    return true
  }
  override func canAsynchronouslyWrite(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType) -> Bool {
    return true
  }


  // make sure to use our window controller
  override func makeWindowControllers() {
    let controller = WindowController()
    controller.shouldCascadeWindows = true
    addWindowController(controller)
  }

  // display the video (as we have no fileURL)
  override var displayName: String! {
    get { return video?.title ?? super.displayName }
    set { }
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
    self.ytURL = url
  }

  override func data(ofType typeName: String) throws -> Data {
    return Data(ytURL!.absoluteString.utf8)
  }


  // copy the URL of the current document to the clipboard
  @IBAction func copy(_: Any) {
    let pb = NSPasteboard.general
    pb.clearContents()
    pb.setString(ytURL!.absoluteString, forType: .string)
    // our watcher will see this but we won't reopen it because it's already open
    // ...unless we've closed the doc before the watcher sees the copy... ah well
  }

}
