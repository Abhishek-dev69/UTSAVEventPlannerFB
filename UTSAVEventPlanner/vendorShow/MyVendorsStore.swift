//
//  MyVendorsStore.swift
//  UTSAV
//
//  Created by Abhishek on 12/12/25.
//

import Foundation

final class MyVendorsStore {
    static let shared = MyVendorsStore()
    private init() {}

    private let key = "my_vendors_ids_v1" // versioned key

    func allVendorIds() -> [String] {
        return UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    func add(vendorId: String) {
        var ids = allVendorIds()
        // avoid duplicates
        if !ids.contains(vendorId) {
            ids.append(vendorId)
            UserDefaults.standard.setValue(ids, forKey: key)
        }
    }

    func remove(vendorId: String) {
        var ids = allVendorIds()
        ids.removeAll { $0 == vendorId }
        UserDefaults.standard.setValue(ids, forKey: key)
    }

    func clearAll() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
