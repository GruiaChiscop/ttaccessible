//
//  ProfilesViewController.swift
//  ttaccessible
//
//  Dedicated window to manage launch profiles (list / launch / create / rename /
//  delete), replacing the previous stack of NSAlert modals. Mirrors the
//  accessible table pattern of UserAccountsViewController.
//

import AppKit

// MARK: - Custom table to capture Enter / Delete and expose VoiceOver actions

private final class ProfilesTableView: NSTableView {
    var onEnter: (() -> Void)?
    var onDelete: (() -> Void)?
    var contextMenuProvider: ((Int) -> NSMenu?)?
    var accessibilityActionsProvider: (() -> [NSAccessibilityCustomAction])?
    var accessibilityMenuHandler: (() -> Bool)?

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 36, 76: // Return, numpad Enter
            onEnter?()
        case 51: // Delete
            onDelete?()
        default:
            super.keyDown(with: event)
        }
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        let point = convert(event.locationInWindow, from: nil)
        let row = row(at: point)
        guard row >= 0 else { return nil }
        selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        return contextMenuProvider?(row)
    }

    override func accessibilityCustomActions() -> [NSAccessibilityCustomAction]? {
        let actions = accessibilityActionsProvider?() ?? []
        return actions.isEmpty ? nil : actions
    }

    override func accessibilityPerformShowMenu() -> Bool {
        accessibilityMenuHandler?() ?? false
    }
}

private final class ProfilesRowView: NSTableRowView {
    var accessibilityActionsProvider: (() -> [NSAccessibilityCustomAction])?
    var accessibilityMenuHandler: (() -> Bool)?

    override func accessibilityCustomActions() -> [NSAccessibilityCustomAction]? {
        let actions = accessibilityActionsProvider?() ?? []
        return actions.isEmpty ? nil : actions
    }

    override func accessibilityPerformShowMenu() -> Bool {
        accessibilityMenuHandler?() ?? false
    }
}

private final class ProfilesCellView: NSTableCellView {
    var accessibilityMenuHandler: (() -> Bool)?

    override func accessibilityPerformShowMenu() -> Bool {
        accessibilityMenuHandler?() ?? false
    }
}

private final class ProfilesTextField: NSTextField {
    var accessibilityMenuHandler: (() -> Bool)?

    init() {
        super.init(frame: .zero)
        isEditable = false
        isSelectable = false
        isBordered = false
        drawsBackground = false
        backgroundColor = .clear
        lineBreakMode = .byTruncatingTail
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func accessibilityPerformShowMenu() -> Bool {
        accessibilityMenuHandler?() ?? false
    }
}

// MARK: - Row model

private struct ProfileRow {
    let entry: ProfileRegistry.Entry
    let isCurrent: Bool
    let isDefault: Bool
    let isRunning: Bool

    var canRename: Bool { !isDefault }
    var canDelete: Bool { !isDefault && !isCurrent && !isRunning }
}

// MARK: - View controller

final class ProfilesViewController: NSViewController {

    private var rows: [ProfileRow] = []
    private weak var appDelegate: AppDelegate?
    private var tableView: ProfilesTableView!
    private var launchButton: NSButton!
    private var newButton: NSButton!
    private var renameButton: NSButton!
    private var deleteButton: NSButton!
    private var refreshButton: NSButton!

    init(appDelegate: AppDelegate?) {
        self.appDelegate = appDelegate
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 560, height: 380))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
        setupButtons()
        setupLayout()
        reload()
    }

    // MARK: - Setup

    private func setupTable() {
        tableView = ProfilesTableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.setAccessibilityLabel(L10n.text("profiles.table.accessibilityLabel"))
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsMultipleSelection = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.onEnter = { [weak self] in self?.launchSelected() }
        tableView.onDelete = { [weak self] in self?.deleteSelected() }
        tableView.contextMenuProvider = { [weak self] row in self?.makeContextMenu(for: row) }
        tableView.accessibilityActionsProvider = { [weak self] in
            self?.accessibilityActionsForSelectedRow() ?? []
        }
        tableView.accessibilityMenuHandler = { [weak self, weak tableView] in
            guard let self, let tableView else { return false }
            return self.showAccessibilityMenuForSelectedRow(from: tableView)
        }

        let nameCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        nameCol.title = L10n.text("profiles.column.name")
        nameCol.width = 300
        nameCol.minWidth = 120

        let statusCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("status"))
        statusCol.title = L10n.text("profiles.column.status")
        statusCol.width = 160
        statusCol.minWidth = 80

        tableView.addTableColumn(nameCol)
        tableView.addTableColumn(statusCol)
    }

    private func setupButtons() {
        launchButton = NSButton(title: L10n.text("profiles.button.launch"), target: self, action: #selector(launchSelected))
        newButton = NSButton(title: L10n.text("profiles.button.new"), target: self, action: #selector(createProfile))
        renameButton = NSButton(title: L10n.text("profiles.button.rename"), target: self, action: #selector(renameSelected))
        deleteButton = NSButton(title: L10n.text("profiles.button.delete"), target: self, action: #selector(deleteSelected))
        refreshButton = NSButton(title: L10n.text("profiles.button.refresh"), target: self, action: #selector(refresh))
        for button in [launchButton, newButton, renameButton, deleteButton, refreshButton] {
            button?.bezelStyle = .rounded
            button?.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    private func setupLayout() {
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let buttonStack = NSStackView(views: [refreshButton, spacer, launchButton, newButton, renameButton, deleteButton])
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 8

        view.addSubview(scrollView)
        view.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            buttonStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
            buttonStack.heightAnchor.constraint(equalToConstant: 32),

            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            scrollView.bottomAnchor.constraint(equalTo: buttonStack.topAnchor, constant: -8)
        ])
    }

    // MARK: - Data

    func reload() {
        let previousSlug = selectedRow?.entry.slug
        let currentSlug = ProfileContext.current.slug
        rows = ProfileRegistry.shared.listAll().map { entry in
            let isCurrent = entry.slug == currentSlug
            return ProfileRow(
                entry: entry,
                isCurrent: isCurrent,
                isDefault: entry.slug == ProfileContext.defaultSlug,
                isRunning: !isCurrent && ProfileInstanceLock.isAnotherInstanceRunning(forSlug: entry.slug)
            )
        }
        tableView.reloadData()
        if let previousSlug, let index = rows.firstIndex(where: { $0.entry.slug == previousSlug }) {
            tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        }
        updateButtonStates()
    }

    private var selectedRow: ProfileRow? {
        let row = tableView.selectedRow
        guard row >= 0, row < rows.count else { return nil }
        return rows[row]
    }

    @discardableResult
    private func selectRow(slug: String) -> ProfileRow? {
        guard let index = rows.firstIndex(where: { $0.entry.slug == slug }) else { return nil }
        tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        return rows[index]
    }

    private func updateButtonStates() {
        let row = selectedRow
        launchButton.isEnabled = row != nil
        renameButton.isEnabled = row?.canRename ?? false
        deleteButton.isEnabled = row?.canDelete ?? false
    }

    private var hostWindow: NSWindow? { view.window }

    // MARK: - Actions

    @objc private func refresh() {
        reload()
    }

    @objc private func launchSelected() {
        guard let row = selectedRow else { return }
        appDelegate?.launchProfile(slug: row.entry.slug)
    }

    @objc private func createProfile() {
        presentNameSheet(
            title: L10n.text("profile.create.title"),
            message: L10n.text("profile.create.message"),
            initial: "",
            confirmTitle: L10n.text("profile.create.launch")
        ) { [weak self] rawName in
            guard let self else { return }
            let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                self.presentError(L10n.text("profile.create.error.empty"))
                return
            }
            let slug = ProfileContext.normalizeSlug(trimmed)
            guard !slug.isEmpty else {
                self.presentError(L10n.text("profile.create.error.invalid"))
                return
            }
            guard slug != ProfileContext.defaultSlug else {
                self.presentError(L10n.text("profile.create.error.reservedDefault"))
                return
            }
            guard let entry = ProfileRegistry.shared.register(displayName: trimmed) else {
                self.presentError(L10n.text("profile.create.error.invalid"))
                return
            }
            self.reload()
            self.selectRow(slug: entry.slug)
            // A brand-new profile is empty, so there's nothing to auto-connect to.
            self.appDelegate?.launchProfile(slug: entry.slug)
        }
    }

    @objc private func renameSelected() {
        guard let row = selectedRow, row.canRename else { return }
        let entry = row.entry
        presentNameSheet(
            title: L10n.text("profile.rename.title"),
            message: L10n.format("profile.rename.message", entry.displayName),
            initial: entry.displayName,
            confirmTitle: L10n.text("profile.rename.confirm")
        ) { [weak self] rawName in
            guard let self else { return }
            let newName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !newName.isEmpty else {
                self.presentError(L10n.text("profile.create.error.empty"))
                return
            }
            if newName == entry.displayName { return }
            guard ProfileRegistry.shared.rename(slug: entry.slug, to: newName) != nil else {
                self.presentError(L10n.text("profile.rename.error.failed"))
                return
            }
            self.reload()
            self.announce(L10n.format("profile.rename.success", newName))
        }
    }

    @objc private func deleteSelected() {
        guard let row = selectedRow else { return }
        let entry = row.entry
        if row.isCurrent {
            presentError(L10n.format("profile.delete.error.currentRunning", entry.displayName))
            return
        }
        if row.isDefault {
            return
        }
        if ProfileInstanceLock.isAnotherInstanceRunning(forSlug: entry.slug) {
            presentError(L10n.format("profile.delete.error.otherInstanceRunning", entry.displayName))
            return
        }

        guard let window = hostWindow else { return }
        let confirm = NSAlert()
        confirm.alertStyle = .warning
        confirm.messageText = L10n.format("profile.delete.confirm.title", entry.displayName)
        confirm.informativeText = L10n.text("profile.delete.confirm.message")
        confirm.addButton(withTitle: L10n.text("profile.delete.confirm.button"))
        confirm.addButton(withTitle: L10n.text("common.cancel"))
        // Make Cancel the default Return action so an accidental Enter doesn't wipe the profile.
        confirm.buttons.first?.keyEquivalent = ""
        confirm.buttons.last?.keyEquivalent = "\r"
        confirm.beginSheetModal(for: window) { [weak self] response in
            guard response == .alertFirstButtonReturn, let self else { return }
            _ = ProfileContext.purgeStorage(forSlug: entry.slug)
            _ = ProfileRegistry.shared.remove(slug: entry.slug)
            self.reload()
            self.announce(L10n.format("profile.delete.success", entry.displayName))
        }
    }

    // MARK: - Sheets

    private func presentNameSheet(
        title: String,
        message: String,
        initial: String,
        confirmTitle: String,
        completion: @escaping (String) -> Void
    ) {
        guard let window = hostWindow else { return }
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: confirmTitle)
        alert.addButton(withTitle: L10n.text("common.cancel"))

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 320, height: 24))
        field.stringValue = initial
        field.placeholderString = L10n.text("profile.create.placeholder")
        field.setAccessibilityLabel(L10n.text("profile.create.field.accessibilityLabel"))
        alert.accessoryView = field
        alert.window.initialFirstResponder = field

        alert.beginSheetModal(for: window) { response in
            guard response == .alertFirstButtonReturn else { return }
            completion(field.stringValue)
        }
    }

    private func presentError(_ message: String) {
        guard let window = hostWindow else { return }
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = L10n.text("profile.newInstance.error.title")
        alert.informativeText = message
        alert.beginSheetModal(for: window, completionHandler: nil)
    }

    // MARK: - Accessibility actions / context menu

    private func accessibilityActionsForSelectedRow() -> [NSAccessibilityCustomAction] {
        guard let row = selectedRow else { return [] }
        return accessibilityActions(for: row)
    }

    private func accessibilityActions(for row: ProfileRow) -> [NSAccessibilityCustomAction] {
        var actions: [NSAccessibilityCustomAction] = [
            NSAccessibilityCustomAction(name: L10n.text("profiles.button.launch")) { [weak self] in
                self?.perform(row) { $0.appDelegate?.launchProfile(slug: $1.entry.slug) }
                return true
            }
        ]
        if row.canRename {
            actions.append(NSAccessibilityCustomAction(name: L10n.text("profiles.button.rename")) { [weak self] in
                self?.perform(row) { ctrl, _ in ctrl.renameSelected() }
                return true
            })
        }
        if row.canDelete {
            actions.append(NSAccessibilityCustomAction(name: L10n.text("profiles.button.delete")) { [weak self] in
                self?.perform(row) { ctrl, _ in ctrl.deleteSelected() }
                return true
            })
        }
        return actions
    }

    private func perform(_ row: ProfileRow, _ action: (ProfilesViewController, ProfileRow) -> Void) {
        let current = selectRow(slug: row.entry.slug) ?? row
        action(self, current)
    }

    private func makeContextMenu(for tableRow: Int) -> NSMenu? {
        guard tableRow >= 0, tableRow < rows.count else { return nil }
        return makeContextMenu(for: rows[tableRow])
    }

    private func makeContextMenu(for row: ProfileRow) -> NSMenu {
        let menu = NSMenu(title: row.entry.displayName)

        let launchItem = NSMenuItem(title: L10n.text("profiles.button.launch"), action: #selector(launchSelected), keyEquivalent: "")
        launchItem.target = self
        menu.addItem(launchItem)

        if row.canRename {
            menu.addItem(.separator())
            let renameItem = NSMenuItem(title: L10n.text("profiles.button.rename"), action: #selector(renameSelected), keyEquivalent: "")
            renameItem.target = self
            menu.addItem(renameItem)
        }
        if row.canDelete {
            let deleteItem = NSMenuItem(title: L10n.text("profiles.button.delete"), action: #selector(deleteSelected), keyEquivalent: "")
            deleteItem.target = self
            menu.addItem(deleteItem)
        }
        return menu
    }

    private func showAccessibilityMenuForSelectedRow(from sourceView: NSView) -> Bool {
        guard let row = selectedRow else { return false }
        return showAccessibilityMenu(for: row, from: sourceView)
    }

    private func showAccessibilityMenu(for row: ProfileRow, from sourceView: NSView) -> Bool {
        let current = selectRow(slug: row.entry.slug) ?? row
        let menu = makeContextMenu(for: current)
        let point = NSPoint(x: sourceView.bounds.midX, y: sourceView.bounds.midY)
        menu.popUp(positioning: nil, at: point, in: sourceView)
        return true
    }

    // MARK: - Cell content

    private func statusText(for row: ProfileRow) -> String {
        if row.isCurrent { return L10n.text("profiles.status.current") }
        if row.isRunning { return L10n.text("profiles.status.running") }
        if row.isDefault { return L10n.text("profiles.status.default") }
        return ""
    }

    private func announce(_ message: String) {
        let element = NSApp.accessibilityWindow() ?? view.window ?? (view as Any)
        NSAccessibility.post(
            element: element,
            notification: .announcementRequested,
            userInfo: [
                NSAccessibility.NotificationUserInfoKey.announcement: message,
                NSAccessibility.NotificationUserInfoKey.priority: NSAccessibilityPriorityLevel.high.rawValue
            ]
        )
    }
}

// MARK: - NSTableViewDataSource

extension ProfilesViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        rows.count
    }
}

// MARK: - NSTableViewDelegate

extension ProfilesViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = ProfilesRowView()
        rowView.accessibilityActionsProvider = { [weak self, weak rowView] in
            guard let self, let rowView else { return [] }
            let currentRow = self.tableView.row(for: rowView)
            guard currentRow >= 0, currentRow < self.rows.count else { return [] }
            return self.accessibilityActions(for: self.rows[currentRow])
        }
        rowView.accessibilityMenuHandler = { [weak self, weak rowView] in
            guard let self, let rowView else { return false }
            let currentRow = self.tableView.row(for: rowView)
            guard currentRow >= 0, currentRow < self.rows.count else { return false }
            return self.showAccessibilityMenu(for: self.rows[currentRow], from: rowView)
        }
        return rowView
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < rows.count else { return nil }
        let profileRow = rows[row]

        let identifier = tableColumn?.identifier ?? NSUserInterfaceItemIdentifier("")
        let cellID = NSUserInterfaceItemIdentifier("cell-\(identifier.rawValue)")

        let cell: ProfilesCellView
        if let existing = tableView.makeView(withIdentifier: cellID, owner: nil) as? ProfilesCellView {
            cell = existing
        } else {
            cell = ProfilesCellView()
            cell.identifier = cellID
            let textField = ProfilesTextField()
            textField.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(textField)
            cell.textField = textField
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
                textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -2),
                textField.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
            ])
        }

        switch identifier.rawValue {
        case "name":
            cell.textField?.stringValue = profileRow.entry.displayName
        case "status":
            cell.textField?.stringValue = statusText(for: profileRow)
        default:
            break
        }

        let actions = accessibilityActions(for: profileRow)
        cell.setAccessibilityCustomActions(actions)
        cell.textField?.setAccessibilityCustomActions(actions)
        cell.accessibilityMenuHandler = { [weak self, weak cell] in
            guard let self, let cell else { return false }
            return self.showAccessibilityMenu(for: profileRow, from: cell)
        }
        if let textField = cell.textField as? ProfilesTextField {
            textField.accessibilityMenuHandler = { [weak self, weak textField] in
                guard let self, let textField else { return false }
                return self.showAccessibilityMenu(for: profileRow, from: textField)
            }
        }
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        updateButtonStates()
    }
}
