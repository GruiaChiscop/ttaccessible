//
//  SavedServerEditorWindowController.swift
//  ttaccessible
//
//  Created by Mathieu Martin on 17/03/2026.
//

import AppKit
import SwiftUI

final class SavedServerEditorWindowController: NSWindowController {
    private final class Coordinator: NSObject, NSWindowDelegate {
        var result: SavedServerDraft?
        var onClose: ((SavedServerDraft?) -> Void)?

        func windowShouldClose(_ sender: NSWindow) -> Bool {
            if let parent = sender.sheetParent {
                parent.endSheet(sender)
                return false
            }
            return true
        }

        func sheetDidEnd() {
            finish()
        }

        func windowWillClose(_ notification: Notification) {
            finish()
        }

        private func finish() {
            let completion = onClose
            onClose = nil
            completion?(result)
        }
    }

    private let coordinator = Coordinator()
    private weak var parentWindow: NSWindow?
    private var presentationRetainer: SavedServerEditorWindowController?

    init(mode: SavedServerEditorMode, draft: SavedServerDraft, parentWindow: NSWindow?) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 380),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = mode.title
        window.isReleasedWhenClosed = false
        window.center()

        self.parentWindow = parentWindow

        if let parentFrame = parentWindow?.frame {
            let origin = NSPoint(
                x: parentFrame.midX - (window.frame.width / 2),
                y: parentFrame.midY - (window.frame.height / 2)
            )
            window.setFrameOrigin(origin)
        }

        super.init(window: window)

        let rootView = SavedServerFormView(
            mode: mode,
            draft: draft,
            onCancel: { [weak self] in
                self?.closeWithResult(nil)
            },
            onSave: { [weak self] result in
                self?.closeWithResult(result)
            }
        )

        window.delegate = coordinator
        window.contentViewController = NSHostingController(rootView: rootView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func present(completion: @escaping (SavedServerDraft?) -> Void) {
        guard let window else {
            completion(nil)
            return
        }

        coordinator.result = nil
        presentationRetainer = self
        coordinator.onClose = { [weak self] result in
            self?.presentationRetainer = nil
            completion(result)
        }

        if let parentWindow {
            parentWindow.beginSheet(window) { [weak self] _ in
                self?.coordinator.sheetDidEnd()
            }
        } else {
            showWindow(nil)
            window.layoutIfNeeded()
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func closeWithResult(_ result: SavedServerDraft?) {
        coordinator.result = result
        guard let window else {
            coordinator.sheetDidEnd()
            return
        }

        if let parent = window.sheetParent {
            parent.endSheet(window)
        } else {
            close()
        }
    }
}
