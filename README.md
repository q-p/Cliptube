# Cliptube — watch the clipboard for YouTube links and preview them  
This macOS utility watches the clipboard for [YouTube](https://www.youtube.com) video links and opens them in a player window for quick access.

## Requirements
The application has been developed on macOS Catalina (10.15) and also requires at least that version.

## Notes
This app grew out of my frustration when trying to view any YouTube video in a private browsing window and being bombarded by sign-in and data sharing consent popups.

## Usage
Start the application and copy any link(s) to a YouTube video to your clipboard (pasteboard). A window containing a native macOS video player for that video should pop up.
You should also be able to manually paste YouTube video URLs.

The application menu contains a toggle for whether the clipboard should be watched for new links or not.

## Contact & Support
Please report any issues on [GitHub](https://github.com/q-p/Cliptube).

## Source Notes
- This is my first Swift project, but relies on classic Cocoa / AppKit for the "UI".
- Dabbling in *Combine.framework* just for the NSPasteboard publisher is probably overkill (or really half-hearted).
- Making an `NSDocument`-based application work for viewing non-local file URLs is a bit of a challenge (or *hack*).  

## Acknowledgements
This software is built on the experience of others:
- [XCDYouTubeKit](https://github.com/0xced/XCDYouTubeKit) by Cédric Luthi is used to look up the available media streams for a YouTube ID.
