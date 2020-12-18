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



enum YouTubeItag: Int, CaseIterable {
  init?(maybeNSNumber: AnyHashable) {
    guard let number = maybeNSNumber as? NSNumber,
          let tag = YouTubeItag(rawValue: number.intValue)
          else { return nil }
    self = tag
  }

  // non-DASH
  case Combined_3GP_Video_MPEG4Visual_144p_Audio_AAC_24kbit = 17
  case Combined_3GP_Video_MPEG4Visual_240p_Audio_AAC_32kbit = 36
  case Combined_MP4_Video_H264_360p_Audio_AAC_96kbit = 18
  case Combined_MP4_Video_H264_720p_Audio_AAC_192kbit = 22
  case Combined_WebM_Video_VP8_360p_Audio_Vorbis_128kbit = 43
  // DASH video MP4
  case Video_MP4_H264_144p = 160
  case Video_MP4_H264_240p = 133
  case Video_MP4_H264_360p = 134
  case Video_MP4_H264_480p = 135
  case Video_MP4_H264_720p = 136
  case Video_MP4_H264_720p_HFR = 298
  case Video_MP4_H264_1080p = 137
  case Video_MP4_H264_1080p_HFR = 299
  case Video_MP4_H264_1440p = 264
  case Video_MP4_H264_2160p = 266
  case Video_MP4_H264_4320p = 138
  // DASH video WebM
  case Video_WebM_VP9_144p = 278
  case Video_WebM_VP9_144p_HFR_HDR = 330
  case Video_WebM_VP9_240p = 242
  case Video_WebM_VP9_240p_HFR_HDR = 331
  case Video_WebM_VP9_360p = 243
  case Video_WebM_VP9_360p_HFR_HDR = 332
  case Video_WebM_VP9_480p = 244
  case Video_WebM_VP9_480p_HFR_HDR = 333
  case Video_WebM_VP9_720p = 247
  case Video_WebM_VP9_720p_HFR = 302
  case Video_WebM_VP9_720p_HFR_HDR = 334
  case Video_WebM_VP9_1080p = 248
  case Video_WebM_VP9_1080p_HFR = 303
  case Video_WebM_VP9_1080p_HFR_HDR = 335
  case Video_WebM_VP9_1440p = 271
  case Video_WebM_VP9_1440p_HFR = 308
  case Video_WebM_VP9_1440p_HFR_HDR = 336
  case Video_WebM_VP9_2160p = 313
  case Video_WebM_VP9_2160p_HFR = 315
  case Video_WebM_VP9_2160p_HFR_HDR = 337
  case Video_WebM_VP9_4320p = 272
  // DASH audio
  case Audio_M4A_AAC_48kbit = 139
  case Audio_M4A_AAC_128kbit = 140
  case Audio_WebM_Vorbis_128kbit = 171
  case Audio_WebM_Opus_48kbit = 249
  case Audio_WebM_Opus_64kbit = 250
  case Audio_WebM_Opus_160kbit = 251
  // Live streaming
  case Live_TS_Video_H264_144p_Audio_AAC_48kbit = 91
  case Live_TS_Video_H264_240p_Audio_AAC_48kbit = 92
  case Live_TS_Video_H264_360p_Audio_AAC_128kbit = 93
  case Live_TS_Video_H264_480p_Audio_AAC_128kbit = 94
  case Live_TS_Video_H264_720p_Audio_AAC_256kbit = 95
  case Live_TS_Video_H264_1080p_Audio_AAC_256kbit = 96
}


let PreferredFormats: [AnyHashable] = [
  XCDYouTubeVideoQuality.HD720.rawValue as NSNumber,
  XCDYouTubeVideoQuality.medium360.rawValue as NSNumber,
  XCDYouTubeVideoQualityHTTPLiveStreaming,
  XCDYouTubeVideoQuality.small240.rawValue as NSNumber,
]
let SupportedFormats = Set(PreferredFormats)

func getPreferredStreams(streams: [AnyHashable: URL]) -> [AnyHashable: URL] {
//  for key in streams {
//    guard let tag = YouTubeItag(maybeNSNumber: key.0) else { continue }
//    print("Found stream with \(tag)")
//  }
  return streams.filter { PreferredFormats.contains($0.key) }
}

func getAVAsset(_ video: XCDYouTubeVideo, streams: [AnyHashable: URL]) -> AVAsset? {
  for format in PreferredFormats {
    guard let bestURL = streams[format] else { continue }
    return AVURLAsset(url: bestURL)
  }
  return nil
}


// ---- split video & audio ----

let PreferredFormatsVideo: [AnyHashable] = [
  YouTubeItag.Video_MP4_H264_4320p.rawValue as NSNumber,
  YouTubeItag.Video_MP4_H264_2160p.rawValue as NSNumber,
  YouTubeItag.Video_MP4_H264_1440p.rawValue as NSNumber,
  YouTubeItag.Video_MP4_H264_1080p_HFR.rawValue as NSNumber,
  YouTubeItag.Video_MP4_H264_1080p.rawValue as NSNumber,
  YouTubeItag.Video_MP4_H264_720p_HFR.rawValue as NSNumber,
  YouTubeItag.Video_MP4_H264_720p.rawValue as NSNumber,
  YouTubeItag.Video_MP4_H264_480p.rawValue as NSNumber,
  YouTubeItag.Video_MP4_H264_360p.rawValue as NSNumber,
  YouTubeItag.Video_MP4_H264_240p.rawValue as NSNumber,
  YouTubeItag.Video_MP4_H264_144p.rawValue as NSNumber,
]
let SupportedFormatsVideo = Set(PreferredFormatsVideo)

let PreferredFormatsAudio: [AnyHashable] = [
  YouTubeItag.Audio_M4A_AAC_128kbit.rawValue as NSNumber,
  YouTubeItag.Audio_M4A_AAC_48kbit.rawValue as NSNumber,
]
let SupportedFormatsAudio = Set(PreferredFormatsAudio)

func getPreferredStreamsSplit(streams: [AnyHashable: URL]) -> [AnyHashable: URL] {
  return streams.filter { SupportedFormatsVideo.contains($0.key) || SupportedFormatsAudio.contains($0.key) }
}

func getAVAssetSplit(_ video: XCDYouTubeVideo, streams: [AnyHashable: URL]) -> AVAsset? {
  var maybeVideoURL: URL?
  for format in PreferredFormatsVideo {
    if let bestURL = streams[format] {
      maybeVideoURL = bestURL
      if let tag = YouTubeItag(maybeNSNumber: format) {
        print("video format = \(tag)")
      }
      break;
    }
  }
  var maybeAudioURL: URL?
  for format in PreferredFormatsAudio {
    if let bestURL = streams[format] {
      maybeAudioURL = bestURL
      if let tag = YouTubeItag(maybeNSNumber: format) {
        print("audio format = \(tag)")
      }
      break;
    }
  }
  guard let srcVideoURL = maybeVideoURL, let srcAudioURL = maybeAudioURL else {
    if let liveURL = video.streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] {
      return AVURLAsset(url: liveURL)
    }
    return nil
  }

  let srcVideoAsset = AVURLAsset(url: srcVideoURL)
  // the following calls takes a long time; they seem to load the complete resource
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
