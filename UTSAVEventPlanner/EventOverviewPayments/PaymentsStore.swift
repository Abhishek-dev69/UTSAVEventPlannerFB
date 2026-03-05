//
//  PaymentsStore.swift
//  UTSAV
//
//  Created by Abhishek on 05/03/26.
//

import Foundation

final class PaymentsStore {

    static let shared = PaymentsStore()
    private init() {
        loadFromDisk()
    }

    private(set) var cachedPayments: [PaymentRecord] = []

    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("payments_cache.json")
    }

    func set(_ payments: [PaymentRecord]) {
        cachedPayments = payments
        saveToDisk()
    }

    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(cachedPayments)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("❌ Failed to save payments cache:", error)
        }
    }

    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            cachedPayments = try JSONDecoder().decode([PaymentRecord].self, from: data)
        } catch {
            print("❌ Failed to load payments cache:", error)
        }
    }
}
