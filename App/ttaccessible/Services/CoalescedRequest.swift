//
//  CoalescedRequest.swift
//  ttaccessible
//

import Foundation

/// Thread-safe latest-value-wins box for high-frequency absolute-value requests
/// (key-repeat or slider-drag floods aimed at a serial work queue).
///
/// `submit` stores the newest value and returns true only when no apply pass is
/// currently queued — the caller schedules exactly one. Values submitted while
/// that pass is still waiting just overwrite the pending target, so a slow
/// consumer can never build a backlog that keeps applying stale steps after the
/// user stops adjusting.
final class CoalescedRequest<Value> {
    private let lock = NSLock()
    private var value: Value?
    private var applyScheduled = false

    /// Store `newValue` as the pending target. Returns true when the caller
    /// must schedule an apply pass (none is queued yet).
    func submit(_ newValue: Value) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
        if applyScheduled {
            return false
        }
        applyScheduled = true
        return true
    }

    /// Consume the newest pending value and allow the next submit to schedule
    /// again. The scheduled apply pass must always call this exactly once, even
    /// when it ends up not applying anything.
    func take() -> Value? {
        lock.lock()
        defer {
            value = nil
            applyScheduled = false
            lock.unlock()
        }
        return value
    }
}
