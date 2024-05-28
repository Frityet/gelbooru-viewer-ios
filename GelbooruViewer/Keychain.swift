//
//  Keychain.swift
//  GelbooruViewer
//
//  Created by Amrit Bhogal on 27/05/2024.
//

import Security
import Foundation

enum KeychainError: Error {
    case dataConversionError
    case unhandledError(status: OSStatus)
}


func saveToKeychain(service: String, account: String, data: String) throws
{
    guard let data = data.data(using: .utf8) else {
        throw KeychainError.dataConversionError
    }
    
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: account,
        kSecValueData as String: data
    ]
    
    SecItemDelete(query as CFDictionary) // Delete any existing item
    let status = SecItemAdd(query as CFDictionary, nil)
    
    guard status == errSecSuccess else {
        throw KeychainError.unhandledError(status: status)
    }
}

func readFromKeychain(service: String, account: String) -> String?
{
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: account,
        kSecReturnData as String: kCFBooleanTrue!,
        kSecMatchLimit as String: kSecMatchLimitOne
    ]
    
    var item: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    
    guard status == errSecSuccess else { return nil }
    guard let data = item as? Data else { return nil }
    return String(data: data, encoding: .utf8)
}
