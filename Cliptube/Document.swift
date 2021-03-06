//
//  Document.swift
//  Cliptube
//
//  Created by Daniel Vollmer on 04.10.20.
//

import AppKit
import AVKit
import XCDYouTubeKit

class Document: NSDocument
{

  var video: XCDYouTubeVideo?
  var asset: AVAsset?
  var ytURL: URL?


  // we don't want the new-style autosave / edited drop-down in the titlebar
  override class var autosavesInPlace: Bool { get { false } }
  // we can read/write on background threads
  override class func canConcurrentlyReadDocuments(ofType typeName: String) -> Bool { true }

  // display the video name as title (as we have no fileURL)
  override func defaultDraftName() -> String {
    guard let video = video else { return super.defaultDraftName() }
    return video.title
  }

  // make sure to use our window controller
  override func makeWindowControllers() {
    let controller = WindowController()
    controller.shouldCascadeWindows = true // this is unset otherwise (on the first load?)
    addWindowController(controller)
  }


  override func read(from url: URL, ofType typeName: String) throws {
    guard let id = findVideoIDs(url.absoluteString).first else {
      throw NSError(domain: "de.maven.Cliptube.ErrorDomain", code: -41, userInfo: [
        NSLocalizedDescriptionKey: "Couldn't find YouTube ID in URL"])
    }

    let ytClient = XCDYouTubeClient.default()
    let video = try ytClient.blockingGetVideoWithIdentifier(id)
    let preferredURLs = getPreferredStreams(streams: video.streamURLs)
    let verifiedURLs = try ytClient.blockingVerifyStreams(video: video, streams: preferredURLs)

    guard let asset = getAVAsset(video, streams: verifiedURLs) else {
      throw NSError(domain: "de.maven.Cliptube.ErrorDomain", code: -42, userInfo: [
        NSLocalizedDescriptionKey: "Couldn't obtain AVAsset for video from URLs = \(verifiedURLs)"])
    }
    self.video = video
    self.asset = asset
    self.ytURL = url
  }


  // copy the URL of the current document to the clipboard
  @IBAction func copy(_: Any) {
    let pb = NSPasteboard.general
    pb.clearContents()
    pb.setString(ytURL!.absoluteString, forType: .string)
    // our watcher will see this but we won't reopen it because it's already open
    // ...unless we've closed the doc before the watcher sees the clipboard change... ah well
  }

}
