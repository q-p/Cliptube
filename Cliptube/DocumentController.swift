//
//  DocumentController.swift
//  Cliptube
//
//  Created by Daniel Vollmer on 05.10.20.
//

import AppKit

class DocumentController: NSDocumentController {

  // opens an untitled document (unsaved) for a remote URL
  func openUntitledDocument(withContentsOf url: URL, display displayDocument: Bool) {
    // let's not block the main thread
    DispatchQueue.global(qos: .default).async {
      do {
        let document = try self.makeDocument(for: nil, withContentsOf: url, ofType: "public.url") as! Document
        DispatchQueue.main.async {
//          document.updateChangeCount(.changeCleared)
          self.addDocument(document)
          if displayDocument {
            DispatchQueue.main.async {
              document.makeWindowControllers()
              document.showWindows()
            }
          }
        }
      } catch let error as NSError {
        DispatchQueue.main.async {
          var userInfo:Dictionary<String, Any> = [NSLocalizedDescriptionKey: "The document “\(url)” could not be opened."]
          if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? Error {
            userInfo[NSLocalizedRecoverySuggestionErrorKey] = underlyingError.localizedDescription
          }
          userInfo.merge(error.userInfo) {(current, _) in current}
          self.presentError(NSError(domain: error.domain, code: error.code, userInfo: userInfo))
        }
      }
    }
  }

  // we identify the document by its youtube URL
  override func document(for url: URL) -> NSDocument? {
    return documents.first(where: { ($0 as! Document).ytURL == url })
  }

  func openAllVideos(maybeURLs: String, display: Bool) {
    for id in findVideoIDs(maybeURLs) {
      guard let url = URL(string: ytCanonicalURLPrefix + id) else { continue }
      openUntitledDocument(withContentsOf: url, display: true)
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
