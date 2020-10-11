//
//  History.swift
//  Cliptube
//
//  Created by Daniel Vollmer on 10.10.20.
//

import Foundation

/// Keeps an ordered history of values (identified by unique keys) up to a given size in order from newest to oldest.
class History
{
  var maxSize: Int {
    didSet {
      guard maxSize < key2CounterAndValue.count else { return }
      // need to adjust so obtain our items, clear the dict, and re-add how many we want to keep
      let remainingItems = items.prefix(maxSize)
      clear()
      for (key, value) in remainingItems {
        add(key: key, value: value)
      }
    }
  }

  var count: Int { key2CounterAndValue.count }

  private typealias SeqDict = Dictionary<String, (sequence: Int, value: String)>
  private var key2CounterAndValue: SeqDict
  private var sequenceID = 0

  init(maxSize: Int) {
    self.maxSize = maxSize
    self.key2CounterAndValue = Dictionary(minimumCapacity: maxSize)
  }

  func add(key: String, value: String) {
    precondition(key2CounterAndValue.count <= maxSize)
    guard maxSize > 0 else { return } // nothing to keep

    if key2CounterAndValue.updateValue((sequenceID, value), forKey: key) == nil && key2CounterAndValue.count > maxSize {
      // need to remove the oldest item (smallest sequenceID)
      let minItem = key2CounterAndValue.min { $0.value.sequence < $1.value.sequence }!
      key2CounterAndValue[minItem.key] = nil
    }
    sequenceID += 1
    assert(key2CounterAndValue.count <= maxSize)
  }

  func clear(keeping idsToKeep: Set<String> = Set()) {
    if idsToKeep.isEmpty {
      key2CounterAndValue.removeAll(keepingCapacity: true)
    } else {
      key2CounterAndValue = key2CounterAndValue.filter { idsToKeep.contains($0.key) }
    }
  }


  var items: [(key: String, value: String)] {
    let indices = key2CounterAndValue.indices.sorted {
      // newest first
      key2CounterAndValue[$1].value.sequence < key2CounterAndValue[$0].value.sequence
    }
    return indices.map {
      let (key, (_, value)) = key2CounterAndValue[$0]
      return (key, value)
    }
  }

}
