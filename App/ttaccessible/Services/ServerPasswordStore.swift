//
//  ServerPasswordStore.swift
//  ttaccessible
//
//  Created by Mathieu Martin on 17/03/2026.
//

import Foundation
import Security

final class ServerPasswordStore {
    private struct Credentials: Codable {
        var server: String?
        var channel: String?

        var isEmpty: Bool {
            (server?.isEmpty ?? true) && (channel?.isEmpty ?? true)
        }
    }

    enum PasswordStoreError: LocalizedError {
        case unexpectedStatus(OSStatus)
        case invalidPasswordData

        var errorDescription: String? {
            switch self {
            case .unexpectedStatus(let status):
                if let message = SecCopyErrorMessageString(status, nil) as String? {
                    return message
                }
                return L10n.format("keychain.error.unexpectedStatus", status)
            case .invalidPasswordData:
                return L10n.text("keychain.error.invalidPasswordData")
            }
        }
    }

    private let combinedServiceName: String
    private let legacyServerServiceName: String
    private let legacyChannelServiceName: String
    private var cache: [UUID: Credentials] = [:]

    init(serviceName: String = "com.math65.ttaccessible.saved-server-password") {
        self.combinedServiceName = serviceName + ".combined"
        self.legacyServerServiceName = serviceName
        self.legacyChannelServiceName = serviceName + ".channel"
    }

    func password(for id: UUID) throws -> String? {
        nonEmpty(try loadCredentials(for: id).server)
    }

    func channelPassword(for id: UUID) throws -> String? {
        nonEmpty(try loadCredentials(for: id).channel)
    }

    func setPassword(_ password: String?, for id: UUID) throws {
        var credentials = try loadCredentials(for: id)
        credentials.server = nonEmpty(password)
        try writeCredentials(credentials, for: id)
    }

    func setChannelPassword(_ password: String?, for id: UUID) throws {
        var credentials = try loadCredentials(for: id)
        credentials.channel = nonEmpty(password)
        try writeCredentials(credentials, for: id)
    }

    func deletePassword(for id: UUID) throws {
        var credentials = try loadCredentials(for: id)
        credentials.server = nil
        try writeCredentials(credentials, for: id)
    }

    func deleteChannelPassword(for id: UUID) throws {
        var credentials = try loadCredentials(for: id)
        credentials.channel = nil
        try writeCredentials(credentials, for: id)
    }

    private func loadCredentials(for id: UUID) throws -> Credentials {
        if let cached = cache[id] {
            return cached
        }

        if let data = try fetchData(service: combinedServiceName, account: id.uuidString) {
            guard let credentials = try? JSONDecoder().decode(Credentials.self, from: data) else {
                throw PasswordStoreError.invalidPasswordData
            }
            cache[id] = credentials
            return credentials
        }

        // Migrate legacy two-item format to the combined format. This still
        // costs two keychain prompts on the very first launch after the fix,
        // but every subsequent launch only touches the single combined item.
        let legacyServer = try fetchString(service: legacyServerServiceName, account: id.uuidString)
        let legacyChannel = try fetchString(service: legacyChannelServiceName, account: id.uuidString)
        let migrated = Credentials(server: nonEmpty(legacyServer), channel: nonEmpty(legacyChannel))

        if !migrated.isEmpty {
            try writeCredentials(migrated, for: id)
            try? deleteRawItem(service: legacyServerServiceName, account: id.uuidString)
            try? deleteRawItem(service: legacyChannelServiceName, account: id.uuidString)
        } else {
            cache[id] = migrated
        }

        return migrated
    }

    private func writeCredentials(_ credentials: Credentials, for id: UUID) throws {
        try deleteRawItem(service: combinedServiceName, account: id.uuidString)

        guard !credentials.isEmpty else {
            cache[id] = credentials
            return
        }

        let data = try JSONEncoder().encode(credentials)
        let attributes: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: combinedServiceName,
            kSecAttrAccount: id.uuidString,
            kSecValueData: data
        ]

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw PasswordStoreError.unexpectedStatus(status)
        }

        cache[id] = credentials
    }

    private func fetchData(service: String, account: String) throws -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            return item as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw PasswordStoreError.unexpectedStatus(status)
        }
    }

    private func fetchString(service: String, account: String) throws -> String? {
        guard let data = try fetchData(service: service, account: account) else {
            return nil
        }
        guard let string = String(data: data, encoding: .utf8) else {
            throw PasswordStoreError.invalidPasswordData
        }
        return string
    }

    private func deleteRawItem(service: String, account: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw PasswordStoreError.unexpectedStatus(status)
        }
    }

    private func nonEmpty(_ string: String?) -> String? {
        guard let string, !string.isEmpty else {
            return nil
        }
        return string
    }
}
