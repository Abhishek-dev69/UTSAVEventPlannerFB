//
//  EventOverviewStore.swift
//  UTSAV
//
//  Created by Abhishek on 25/01/26.
//

import Foundation

struct EventOverviewCache: Codable {
    let eventId: String
    let cartItems: [CartItemRecord]
    let receivedAmount: Double
    let totalExpenses: Double
}

final class EventOverviewStore {

    static let shared = EventOverviewStore()
    private init() {}

    // In-memory cache (fast)
    private var cache: [String: EventOverviewCache] = [:]

    // MARK: - File URL per event
    private func fileURL(for eventId: String) -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("event_overview_\(eventId).json")
    }

    // MARK: - Get
    func load(eventId: String) -> EventOverviewCache? {
        // 1️⃣ Memory
        if let cached = cache[eventId] {
            return cached
        }

        // 2️⃣ Disk
        let url = fileURL(for: eventId)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(EventOverviewCache.self, from: data)
            cache[eventId] = decoded
            return decoded
        } catch {
            print("❌ Failed to load overview cache:", error)
            return nil
        }
    }

    // MARK: - Save
    func save(_ overview: EventOverviewCache) {
        cache[overview.eventId] = overview

        let url = fileURL(for: overview.eventId)
        do {
            let data = try JSONEncoder().encode(overview)
            try data.write(to: url, options: .atomic)
        } catch {
            print("❌ Failed to save overview cache:", error)
        }
    }

    // MARK: - Clear (logout / event delete)
    func clear(eventId: String) {
        cache.removeValue(forKey: eventId)
        let url = fileURL(for: eventId)
        try? FileManager.default.removeItem(at: url)
    }
}
