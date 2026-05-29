//
//  ChatTableView.swift
//  ttaccessible
//
//  Created by Mathieu Martin on 29/05/2026.
//

import AppKit

final class ChatTableView: NSTableView {
    var onCopy: (() -> Void)?

    @objc func copy(_ sender: Any?) {
        onCopy?()
    }

    @objc func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(copy(_:)) {
            return clickedRow >= 0 || selectedRow >= 0
        }
        return true
    }

    override func keyDown(with event: NSEvent) {
        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if mods == .command,
           event.charactersIgnoringModifiers?.lowercased() == "c",
           selectedRow >= 0 {
            onCopy?()
            return
        }
        super.keyDown(with: event)
    }
}
