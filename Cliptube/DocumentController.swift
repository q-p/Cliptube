//
//  DocumentController.swift
//  Cliptube
//
//  Created by Daniel Vollmer on 05.10.20.
//

import AppKit

class DocumentController: NSDocumentController
{
  // storage for the ordered document history
  var history: History

  override init() {
    history = History(maxSize: UserDefaults.standard.historySize)
    for (key, value) in UserDefaults.standard.history.reversed() {
      history.add(key: key, value: value)
    }
    // no need to store history: we just read it
    super.init()
  }

  required init?(coder: NSCoder) {
    fatalError()
  }

  // we identify the document by its youtube URL (but because we open them as new drafts, the controller cannot check fileURL)
  override func document(for url: URL) -> NSDocument? {
    return documents.first(where: { ($0 as! Document).ytURL == url })
  }

  override func typeForContents(of url: URL) throws -> String {
    return "public.url"
  }

  // opens an untitled document (unsaved) for a remote URL
  func openUntitledDocument(withContentsOf url: URL, display displayDocument: Bool) {
    reopenDocument(for: nil, withContentsOf: url, display: true) { (document, wasAlreadyOpen, error) in
      if let document = document {
        let document = document as! Document
        if !wasAlreadyOpen {
          document.updateChangeCount(.changeCleared)
        }
        else {
          document.showWindows() // make front
        }
        self.history.add(key: document.video!.identifier, value: document.video!.title)
        UserDefaults.standard.history = self.history.items // store updated history
      }

      if let error = error {
        let error = error as NSError
        var userInfo:Dictionary<String, Any> = [NSLocalizedDescriptionKey: "The document “\(url)” could not be opened."]
        if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
          userInfo[NSLocalizedRecoverySuggestionErrorKey] = underlyingError.localizedDescription
          userInfo.merge(underlyingError.userInfo) {(current, _) in current}
        }
        userInfo.merge(error.userInfo) {(current, _) in current}
        self.presentError(NSError(domain: error.domain, code: error.code, userInfo: userInfo))
      }
    }
  }

  func openAllVideos(maybeURLs: String, display: Bool) {
    for id in findVideoIDs(maybeURLs) {
      guard let url = URL(string: ytCanonicalURLPrefix + id) else { continue }
      openUntitledDocument(withContentsOf: url, display: true)
    }
  }


  override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    switch menuItem.action {
    case #selector(paste):
      guard let string = getPasteboardStringData(NSPasteboard.general) else { return false }
      return !findVideoIDs(string).isEmpty
    case #selector(clearHistory):
      return history.count > documents.count
    default:
      return super.validateMenuItem(menuItem)
    }
  }

  @IBAction func paste(_: Any) {
    guard let string = getPasteboardStringData(NSPasteboard.general) else { return }
    openAllVideos(maybeURLs: string, display: true)
  }


  @IBAction func openHistoryItem(_ menuItem: NSMenuItem) {
    guard let id = menuItem.representedObject as? String,
          let url = URL(string: ytCanonicalURLPrefix + id) else { return }
    openUntitledDocument(withContentsOf: url, display: true)
  }

  @IBAction func clearHistory(_ menuItem: NSMenuItem) {
    let openIDs: Set<String> = Set(documents.map { ($0 as! Document).video!.identifier })
    history.clear(keeping:openIDs)
    UserDefaults.standard.history = history.items // store cleared history
  }

}
