//
//  CartItemsStore.swift
//  UTSAV
//
//  Created by Abhishek on 05/03/26.
//

import Foundation

final class CartItemsStore {

    static let shared = CartItemsStore()
    private init() {
        loadFromDisk()
    }

    private(set) var cachedItems: [CartItemRecord] = []

    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("cart_items_cache.json")
    }

    func set(_ items: [CartItemRecord]) {
        cachedItems = items
        saveToDisk()
    }

    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(cachedItems)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("❌ Failed to save cart cache:", error)
        }
    }

    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            cachedItems = try JSONDecoder().decode([CartItemRecord].self, from: data)
        } catch {
            print("❌ Failed to load cart cache:", error)
        }
    }
}
