//
//  StorageManager.swift
//  Sift
//
//  Created by user1 on 3/6/19.
//  Copyright © 2019 Artem Kedrov. All rights reserved.
//

import Foundation

public typealias StorageRule = Codable & StorageKeys

// One of the required protocols to store data
public protocol StorageKeys {
  static var storageKey: String { get }
}

/// Storage errors
public enum StorageError: Error {
  case SaveObjectError
  case DuplicateError
  case GetObjectError
  case InsertKeyError
}

public extension StorageError {
  var message: String {
    switch self {
    case .SaveObjectError:
      return "Save object error"
    case .DuplicateError:
      return "Duplicate error"
    case .GetObjectError:
      return "Get object error"
    case .InsertKeyError:
      return "Insert key error"
    }
  }
}

/// A manager who can help you process the object in different repositories.
public struct StorageManager {
  
  static let shared = StorageManager()
  
  private let storageKeys = "keys"
  
  /**
   * Trying to save object to specified storage
   * Params:
   *                       - obj: T - object to save
   *                       - reSave - you can specify whether to rewrite the object with a similar key (default value == false)
   * Possible errors:
   *                       - StorageError.DuplicateError
   *                       - StorageError.SaveObjectError
   *                       - StorageError.InsertKeyError
   */
  public func save<T>(_ obj: T, to storage: UserDefaults = UserDefaults.standard, reSave: Bool = false) throws where T: StorageRule {
    guard allKeys().contains(type(of: obj).storageKey) == false || reSave == true else { throw StorageError.DuplicateError }
    guard let data = try? JSONEncoder().encode(obj) else { throw StorageError.SaveObjectError }
    storage.set(data, forKey: type(of: obj).storageKey)
    guard let _ = try? get(type(of: obj)) else { throw StorageError.SaveObjectError }
    try addKey( type(of: obj).storageKey)

    
    storage.synchronize()
  }
  
  
  /**
   * Trying to get object from specified storage
   * Return stored obj or StorageError:
   *                       - StorageError.GetObjectError
   */
  @discardableResult
  public func get<T>(_ obj: T.Type, from storage: UserDefaults = UserDefaults.standard) throws -> T where T: StorageRule {
    
    guard let data = storage.data(forKey: T.storageKey),
      let decodedObj = try? JSONDecoder().decode(T.self, from: data)
      else { throw StorageError.GetObjectError }
    return decodedObj
  }
  
  
  /**
   * Return all keys from the specified storage
   * Possible errors:
   *                       - StorageError.GetKeysError
   */
  public func allKeys(from storage: UserDefaults = UserDefaults.standard) -> Array<String> {
    guard let data = storage.data(forKey: storageKeys),
      let keys = try? JSONDecoder().decode(Array<String>.self, from: data)
      else { return Array<String>() }
    return keys
  }
  
  private func addKey(_ key: String, to storage: UserDefaults = UserDefaults.standard) throws {
    var keys = allKeys()
    keys.append(key)
    let keysData = try JSONEncoder().encode(keys)
    UserDefaults.standard.set(keysData, forKey: storageKeys)
  }
  
}

