//
//  Youtube.swift
//  Cliptube
//
//  Created by Daniel Vollmer on 04.10.20.
//

import XCDYouTubeKit
import AVKit


/// The canonical prefix for our YouTube document URL (completed by appending the ID).
let ytCanonicalURLPrefix = "https://www.youtube.com/watch?v="

// https://stackoverflow.com/questions/5830387/how-do-i-find-all-youtube-video-ids-in-a-string-using-a-regex/6901180#6901180
private let ytRegex = try! NSRegularExpression(pattern: #"""
(?xi)
(?:https?://)?     # Optional scheme. Either http or https.
(?:[0-9A-Z-]+\.)?  # Optional subdomain.
(?:                # Group host alternatives.
  youtu\.be/       # Either youtu.be,
| youtube          # or youtube.com or
  (?:-nocookie)?   # youtube-nocookie.com
  \.com            # followed by
  \S*?             # Allow anything up to VIDEO_ID,
  [^\w\s-]         # but char before ID is non-ID char.
)                  # End host alternatives.
(?<ID>[\w-]{11})   # $1: VIDEO_ID is exactly 11 chars.
(?=[^\w-]|$)       # Assert next char is non-ID or EOS.
(?!                # Assert URL is not pre-linked.
  [?=&+%\w.-]*     # Allow URL (query) remainder.
  (?:              # Group pre-linked alternatives.
    [\'"][^<>]*>   # Either inside a start tag,
  | </a>           # or inside <a> element text contents.
  )                # End recognized pre-linked alts.
)                  # End negative lookahead assertion.
[?=&+%\w.-]*       # Consume any URL (query) remainder.
"""#);

func findVideoIDs(_ maybeUrls: String) -> Set<String> {
  var result: Set<String> = []
  let range = NSRange(maybeUrls.startIndex..<maybeUrls.endIndex, in: maybeUrls)
  ytRegex.enumerateMatches(in: maybeUrls, options: [], range: range) { (match, _, _) in
    guard let match = match else { return }
    let nsrange = match.range(withName: "ID")
    if nsrange.location != NSNotFound, let range = Range(nsrange, in: maybeUrls) {
      result.insert(String(maybeUrls[range]))
    }
  }
  return result
}


let PreferredFormats: [AnyHashable] = [
  XCDYouTubeVideoQualityHTTPLiveStreaming,
  XCDYouTubeVideoQuality.HD720.rawValue as NSNumber,
  XCDYouTubeVideoQuality.medium360.rawValue as NSNumber,
  XCDYouTubeVideoQuality.small240.rawValue as NSNumber,
]
let SupportedFormats = Set(PreferredFormats)

func getAVAsset(streams: [AnyHashable: URL]) -> AVAsset? {
  for format in PreferredFormats {
    guard let bestURL = streams[format] else { continue }
    return AVURLAsset(url: bestURL)
  }
  return nil
}

func getPreferredStreams(streams: [AnyHashable: URL]) -> [AnyHashable: URL] {
  return streams.filter { PreferredFormats.contains($0.key) }
}

let PreferredFormatsVideo: [AnyHashable] = [
  138 as NSNumber, // MP4 4320p
  266 as NSNumber, // MP4 2160p
  264 as NSNumber, // MP4 1440p
  299 as NSNumber, // MP4 1080p HFR
  137 as NSNumber, // MP4 1080p
  298 as NSNumber, // MP4  720p HFR
  136 as NSNumber, // MP4  720p
  135 as NSNumber, // MP4  480p
  134 as NSNumber, // MP4  360p
  133 as NSNumber, // MP4  240p
  160 as NSNumber, // MP4  144p
]
let SupportedFormatsVideo = Set(PreferredFormatsVideo)

let PreferredFormatsAudio: [AnyHashable] = [
  140 as NSNumber, // M4A 128 kbit/s
  139 as NSNumber, // M4A  48 kbit/s
]
let SupportedFormatsAudio = Set(PreferredFormatsAudio)

func getAVAssetSplit(video: XCDYouTubeVideo) -> AVAsset? {
  if let liveURL = video.streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] {
    return AVURLAsset(url: liveURL)
  }

  var maybeVideoURL: URL?
  for format in PreferredFormatsVideo {
    if let bestURL = video.streamURLs[format] {
      maybeVideoURL = bestURL
      print("video format = \(format)")
      break;
    }
  }
  var maybeAudioURL: URL?
  for format in PreferredFormatsAudio {
    if let bestURL = video.streamURLs[format] {
      print("audio format = \(format)")
      maybeAudioURL = bestURL
      break;
    }
  }
  guard let srcVideoURL = maybeVideoURL, let srcAudioURL = maybeAudioURL else { return nil }

  let srcVideoAsset = AVURLAsset(url: srcVideoURL)
  // the following calls takes a lonst time
  guard let srcVideoTrack = srcVideoAsset.tracks(withMediaType: .video).first else { return nil }

  let srcAudioAsset = AVURLAsset(url: srcAudioURL)
  guard let srcAudioTrack = srcAudioAsset.tracks(withMediaType: .audio).first else { return nil }

  let composition = AVMutableComposition()

  guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: 1) else { return nil }
  guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: 2) else { return nil }

  try! videoTrack.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: CMTimeMakeWithSeconds(video.duration, preferredTimescale: srcVideoTrack.naturalTimeScale)), of: srcVideoTrack, at: CMTime.zero)
  try! audioTrack.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: CMTimeMakeWithSeconds(video.duration, preferredTimescale: srcAudioTrack.naturalTimeScale)), of: srcAudioTrack, at: CMTime.zero)

  return composition.copy() as! AVComposition
}


extension XCDYouTubeClient {

  func blockingGetVideoWithIdentifier(_ videoIdentifier: String) throws -> XCDYouTubeVideo {
    guard let queue = self.value(forKey: "queue") as? OperationQueue else {
      throw NSError(domain: "de.maven.Cliptube.ErrorDomain", code: -1, userInfo: nil)
    }
    let operation = XCDYouTubeVideoOperation(videoIdentifier: videoIdentifier, languageIdentifier: self.languageIdentifier)
    queue.addOperations([operation], waitUntilFinished: true)
    if let video = operation.video {
      return video
    }
    throw operation.error ?? NSError(domain: "de.maven.Cliptube.ErrorDomain", code: -2, userInfo: [
        NSLocalizedDescriptionKey: "XCDYouTubeClient: Neither video nor error"])
  }

  func blockingVerifyStreams(video: XCDYouTubeVideo, streams: [AnyHashable: URL]) throws -> [AnyHashable: URL] {
    guard let queue = self.value(forKey: "queue") as? OperationQueue else {
      throw NSError(domain: "de.maven.Cliptube.ErrorDomain", code: -1, userInfo: nil)
    }
    let operation = XCDYouTubeVideoQueryOperation(video: video, streamURLsToQuery:streams, options: nil, cookies: nil)
    queue.addOperations([operation], waitUntilFinished: true)
    if let verifiedURLs = operation.streamURLs {
      return verifiedURLs
    }
    throw operation.error ?? NSError(domain: "de.maven.Cliptube.ErrorDomain", code: -3, userInfo: [
        NSLocalizedDescriptionKey: "XCDYouTubeClient: Neither streamURLs nor error"])
  }

}
