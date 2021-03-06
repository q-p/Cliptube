//
//  SleepAsserter.swift
//  Cliptube
//
//  Created by Daniel Vollmer on 27.11.20.
//

import IOKit.pwr_mgt

class SleepAsserter
{
  var blockCount: Int { get { numAssertions } }

  func addBlock(reason: String = "Video playback") {
    if numAssertions == 0 {
      let noSleepReturn = IOPMAssertionCreateWithName(
        kIOPMAssertPreventUserIdleDisplaySleep as CFString,
        IOPMAssertionLevel(kIOPMAssertionLevelOn),
        reason as CFString,
        &noSleepAssertionID)
      guard noSleepReturn == kIOReturnSuccess else { return }
    }
    numAssertions += 1
  }

  func releaseBlock() {
    precondition(numAssertions > 0, "No existing blocks")
    numAssertions -= 1
    if numAssertions == 0 {
      _ = IOPMAssertionRelease(noSleepAssertionID) == kIOReturnSuccess
    }
  }

  private var numAssertions: Int = 0
  private var noSleepAssertionID: IOPMAssertionID = 0

}
