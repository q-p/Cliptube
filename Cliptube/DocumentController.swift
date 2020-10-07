//
//  DocumentController.swift
//  Cliptube
//
//  Created by Daniel Vollmer on 05.10.20.
//

import AppKit

class DocumentController: NSDocumentController {

  // allows use of open with non-file URL
  override func typeForContents(of url: URL) throws -> String {
    return "public.mpeg-4"
  }


  override func openDocument(withContentsOf url: URL, display displayDocument: Bool, completionHandler: @escaping (NSDocument?, Bool, Error?) -> Void) {
    // see whether it's already open
    for otherDoc in documents {
      guard let otherDoc = otherDoc as? Document, let otherURL = otherDoc.ytURL else { continue }
      if url == otherURL {
        if displayDocument {
          otherDoc.showWindows()
        }
        return
      }
    }
    // otherwise let super deal with actually loading it :)
    super.openDocument(withContentsOf: url, display: displayDocument, completionHandler: completionHandler)
  }


  // similar behavior to openDocument(), but display any error on failure
  func openVideo(url: URL, display: Bool) {
    openDocument(withContentsOf: url, display: display, completionHandler: { (document, documentWasAlreadyOpen, error) in
      if document == nil, let error = error as NSError? {
        var userInfo:Dictionary<String, Any> = [NSLocalizedDescriptionKey: "The document “\(url)” could not be opened."]

        if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? Error {
          userInfo[NSLocalizedRecoverySuggestionErrorKey] = underlyingError.localizedDescription
        }
        userInfo.merge(error.userInfo) {(current, _) in current}
        self.presentError(NSError(domain: error.domain, code: error.code, userInfo: userInfo))
      }
    })
  }

  func openAllVideos(maybeURLs: String, display: Bool) {
    for id in findVideoIDs(maybeURLs) {
      guard let url = URL(string: ytCanonicalURLPrefix + id) else { continue }
      openVideo(url: url, display: true)
    }
  }

  // let's make paste work
  override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    switch menuItem.action {
    case #selector(paste):
      guard let string = getPasteboardStringData(NSPasteboard.general) else { return false }
      return !findVideoIDs(string).isEmpty
    default:
      return super.validateMenuItem(menuItem)
    }
  }

  @IBAction func paste(_: Any) {
    guard let string = getPasteboardStringData(NSPasteboard.general) else { return }
    openAllVideos(maybeURLs: string, display: true)
  }
}
