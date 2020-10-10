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


  // display the video name as title (as we have no fileURL)
  override func defaultDraftName() -> String {
    guard let video = video else { return super.defaultDraftName() }
    return video.title
  }
//  override var displayName: String! {
//    get { return video?.title ?? super.displayName }
//    set { }
//  }


  // make sure to use our window controller
  override func makeWindowControllers() {
    let controller = WindowController()
    controller.shouldCascadeWindows = true
    addWindowController(controller)
  }



  override func read(from url: URL, ofType typeName: String) throws {
    var nonFileURL : URL?
    if typeName != "public.url" {
      assert(url.isFileURL, "expected a file url")
      if let utf8String = String(bytes: try Data(contentsOf: url), encoding: .utf8) {
        nonFileURL = URL(string: utf8String)
      }
    }
    else {
      nonFileURL = url
    }
    guard let videoURL = nonFileURL else {
      throw NSError(domain: "de.maven.Cliptube", code: -40, userInfo: [
        NSLocalizedDescriptionKey: "Couldn't load YouTube URL from \(url)"])
    }

    guard let id = findVideoIDs(videoURL.absoluteString).first else {
      throw NSError(domain: "de.maven.Cliptube", code: -41, userInfo: [
        NSLocalizedDescriptionKey: "Couldn't find YouTube ID in URL"])
    }

    try self.video = XCDYouTubeClient.default().blockingGetVideoWithIdentifier(id)
    guard let asset = getAVAsset(video: video!) else {
      throw NSError(domain: "de.maven.Cliptube", code: -42, userInfo: [
        NSLocalizedDescriptionKey: "Couldn't obtain AVAsset for video"])
    }
    self.asset = asset
    self.ytURL = videoURL
  }

  override func data(ofType typeName: String) throws -> Data {
    Swift.print("Saving \(video!.title) as \(typeName)")
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
