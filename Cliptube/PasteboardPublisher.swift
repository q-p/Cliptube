//
//  PasteboardWatcher.swift
//  Cliptube
//
//  Created by Daniel Vollmer on 03.10.20.
//

import Foundation
import Combine
import AppKit

let pbTypes: [NSPasteboard.PasteboardType] = [.string]

func getPasteboardStringData(_ pasteboard: NSPasteboard) -> String? {
  guard let bestType = pasteboard.availableType(from: pbTypes) else { return nil }
  return pasteboard.string(forType: bestType)
}


/// String-Publisher for changes to NSPasteboard (published on the main-thread).
class PasteboardPublisher: Publisher
{
  typealias Output = String
  typealias Failure = Never

  init(seconds: TimeInterval = 1.0, tolerance: TimeInterval = 0.5) {
    self.timerPublisher = Timer.publish(every: seconds, tolerance: tolerance, on: .main, in: .default)
  }

  private var timerPublisher: Timer.TimerPublisher

  func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
    subscriber.receive(subscription: Inner(self, subscriber))
  }

  private typealias Parent = PasteboardPublisher
  private final class Inner<Downstream: Subscriber>: Subscription
    where Downstream.Input == Output, Downstream.Failure == Failure
  {
    typealias Input = Downstream.Input
    typealias Failure = Downstream.Failure

    private let pasteboard = NSPasteboard.general
    private var parent: Parent?
    private var downstream: Downstream?
    private var timer: AnyCancellable?
    private var changeCount: Int = -1

    init(_ parent: Parent, _ downstream: Downstream) {
      self.parent = parent
      self.downstream = downstream
    }

    func request(_ d: Subscribers.Demand) {
      precondition(d > 0, "Invalid request of zero demand")

      guard let parent = parent else { return }

      if self.timer == nil {
        self.changeCount = pasteboard.changeCount
        self.timer = parent.timerPublisher.autoconnect().sink { [weak self] _ in
          guard let self = self else { return }
          self.pollAndMaybeSend()
        }
      }
    }

    func cancel() {
      guard parent != nil else { return }
      timer?.cancel()
      timer = nil
      downstream = nil
      parent = nil
    }

    func pollAndMaybeSend() {
      guard parent != nil, let downstream = downstream else { return }

      let actualChange = pasteboard.changeCount
      guard actualChange != changeCount else { return }
      changeCount = actualChange

      guard let string = getPasteboardStringData(pasteboard) else { return }
      _ = downstream.receive(string)
    }
  }
}
