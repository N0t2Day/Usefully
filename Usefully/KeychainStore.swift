//
//  KeychainStore.swift
//  CabinCrewPad
//
//  Created by Artem Kedrov on 17.09.2019.
//  Copyright © 2019 Artem Kedrov. All rights reserved.
//

import UIKit

import Security

// You might want to update this to be something descriptive for your app.
private let service = Bundle.main.bundleIdentifier ?? ""

fileprivate let wipeErrorDescription = "Can't wipe data at KeychainStore"
fileprivate let deleteErrorDescription = "Can't delete"
fileprivate let notFoundErrorDescription = "Not found"
fileprivate let unknownErrorDescription = "Unknown error"
fileprivate let updateErrorDescription = "Can't update"
fileprivate let insertErrorDescription = "Can't insert"

enum KeychainStore {
  
  /// Does a certain item exist?
  static func exists(dataFor key: String) -> Bool {
    let status = SecItemCopyMatching([
      kSecClass: kSecClassGenericPassword,
      kSecAttrAccount: key,
      kSecAttrService: service,
      kSecReturnData: false,
      ] as NSDictionary, nil)
    
    return status == errSecSuccess
  }
  
  /// Adds an item to the keychain.
  private static func add<T: Codable>(object: T, account: String) throws {
    let data = try JSONEncoder().encode(object)
    let status = SecItemAdd([
      kSecClass: kSecClassGenericPassword,
      kSecAttrAccount: account,
      kSecAttrService: service,
      // Allow background access:
      kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
      kSecValueData: data,
      ] as NSDictionary, nil)
    guard status == errSecSuccess else { throw KeychainErrors.insertError("type: \(T.self) key: \(account)") }
  }
  
  /// Updates a keychain item.
  private static func update<T: Codable>(object: T, account: String) throws {
    let data = try JSONEncoder().encode(object)
    let status = SecItemUpdate([
      kSecClass: kSecClassGenericPassword,
      kSecAttrAccount: account,
      kSecAttrService: service,
      ] as NSDictionary, [
        kSecValueData: data,
        ] as NSDictionary)
    guard status == errSecSuccess else { throw KeychainErrors.updateError("type: \(T.self) key: \(account)") }
  }
  
  /// Stores a keychain item.
  static func set<T: Codable>(object: T, account: String) throws {
    if exists(dataFor: account) {
      try update(object: object, account: account)
    } else {
      try add(object: object, account: account)
    }
  }
  
  // If not present, returns nil. Only throws on error.
    static func get<T: Codable>(account: String, type: T.Type) throws -> T {
    var result: AnyObject?
    let status = SecItemCopyMatching([
      kSecClass: kSecClassGenericPassword,
      kSecAttrAccount: account,
      kSecAttrService: service,
      kSecReturnData: true,
      ] as NSDictionary, &result)
    if status == errSecSuccess, let data = result as? Data {
      return try JSONDecoder().decode(type, from: data)
    }

    throw status == errSecItemNotFound ? KeychainErrors.notFoundError(account) : .unknownError
  }
  
  /// Delete a single item.
  static func delete(account: String) throws {
    let status = SecItemDelete([
      kSecClass: kSecClassGenericPassword,
      kSecAttrAccount: account,
      kSecAttrService: service,
      ] as NSDictionary)
    guard status == errSecSuccess else { throw KeychainErrors.deleteError(account) }
  }
  
  /// Delete all items for my app. Useful on eg logout.
  static func deleteAll() throws {
    let status = SecItemDelete([
      kSecClass: kSecClassGenericPassword,
      ] as NSDictionary)
    guard status == errSecSuccess else { throw KeychainErrors.wipeError }
  }
  
}

enum KeychainErrors: Error {
  case wipeError
  case unknownError
  case deleteError(String)
  case notFoundError(String)
  case updateError(String)
  case insertError(String)
}

extension KeychainErrors: CustomStringConvertible {
  var description: String {
    switch self {
    case .wipeError:
      return wipeErrorDescription
    case .unknownError:
      return unknownErrorDescription
    case .deleteError(let msg):
      return "\(deleteErrorDescription) \(msg)"
    case .notFoundError(let msg):
      return "\(notFoundErrorDescription) \(msg)"
    case .updateError(let msg):
      return "\(updateErrorDescription) \(msg)"
    case .insertError(let msg):
      return "\(insertErrorDescription) \(msg)"
    }
  }
}

