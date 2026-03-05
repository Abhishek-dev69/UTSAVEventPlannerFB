//
//  InventoryCountsStore.swift
//  UTSAV
//
//  Created by Abhishek on 05/03/26.
//

import Foundation

final class InventoryCountsStore {

    static let shared = InventoryCountsStore()

    private(set) var cache: [String:(allocated:Int,received:Int,pending:Int,lost:Int)] = [:]

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("inventory_counts.json")
    }()

    private init() {
        load()
    }

    func set(
        eventId: String,
        allocated: Int,
        received: Int,
        pending: Int,
        lost: Int
    ) {

        cache[eventId] = (allocated,received,pending,lost)
        save()
    }

    func counts(for eventId: String) -> (Int,Int,Int,Int)? {
        cache[eventId]
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(
                cache.mapValues { [$0.0,$0.1,$0.2,$0.3] }
            )
            try data.write(to: fileURL)
        } catch {}
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }

        if let decoded = try? JSONDecoder().decode(
            [String:[Int]].self,
            from: data
        ) {
            for (k,v) in decoded {
                if v.count == 4 {
                    cache[k] = (v[0],v[1],v[2],v[3])
                }
            }
        }
    }
}
