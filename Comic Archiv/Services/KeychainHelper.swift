//
//  KeychainHelper.swift
//  Comic Archiv
//

import Foundation
import Security

enum KeychainHelper {
    static func save(_ value: String, service: String, account: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData] = data
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    static func load(service: String, account: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      service,
            kSecAttrAccount:      account,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(service: String, account: String) {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// Namespaced keys
extension KeychainHelper {
    static let metronService = "comic-archiv.metron"

    static var metronUsername: String? {
        get { load(service: metronService, account: "username") }
        set {
            if let v = newValue, !v.isEmpty { save(v, service: metronService, account: "username") }
            else { delete(service: metronService, account: "username") }
        }
    }

    static var metronPassword: String? {
        get { load(service: metronService, account: "password") }
        set {
            if let v = newValue, !v.isEmpty { save(v, service: metronService, account: "password") }
            else { delete(service: metronService, account: "password") }
        }
    }
}
