import Foundation

final class InventoryManager {

    static let shared = InventoryManager()
    private init() {}

    // caches: store summed quantities (default to 0)
    private var sentQuantityCache: [String: Int] = [:]      // planner quantities
    private var receivedQuantityCache: [String: Int] = [:]  // vendor quantities

    // in-progress loads
    private var inProgressLoads: Set<String> = []

    // concurrent queue + barrier for writes
    private let queue = DispatchQueue(label: "inventory.manager.queue", attributes: .concurrent)

    // MARK: - Cached accessors (return 0 if not present)
    func cachedSentQuantity(forEventId id: String) -> Int {
        return queue.sync { sentQuantityCache[id] ?? 0 }
    }

    func cachedReceivedQuantity(forEventId id: String) -> Int {
        return queue.sync { receivedQuantityCache[id] ?? 0 }
    }

    // MARK: - Public async getter that ensures fresh load when needed
    /// Returns a tuple (sent, received). If not cached, triggers loadCounts and awaits completion.
    func getCounts(forEventId id: String) async -> (sent: Int, received: Int) {
        // If we already have cached values return immediately
        let sent = queue.sync { sentQuantityCache[id] }
        let received = queue.sync { receivedQuantityCache[id] }
        if sent != nil || received != nil {
            return (sent ?? 0, received ?? 0)
        }

        // otherwise trigger load and wait for it
        await loadCounts(forEventId: id)
        let s = queue.sync { sentQuantityCache[id] ?? 0 }
        let r = queue.sync { receivedQuantityCache[id] ?? 0 }
        return (s, r)
    }

    // MARK: - Load counts (sums quantities by source_type)
    /// Asynchronously loads and caches summed quantities for the event.
    /// Multiple simultaneous callers will coalesce into one network call.
    @MainActor
    func loadCounts(forEventId id: String) async {
        var shouldLoad = false
        queue.sync(flags: .barrier) {
            if !inProgressLoads.contains(id) {
                inProgressLoads.insert(id)
                shouldLoad = true
            }
        }
        guard shouldLoad else {
            // another load already in progress; wait until it finishes by polling the cache (small backoff).
            // This keeps API simpler than trying to manage continuations.
            for _ in 0..<20 {
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
                let s = queue.sync { sentQuantityCache[id] }
                let r = queue.sync { receivedQuantityCache[id] }
                if s != nil || r != nil { return }
            }
            return
        }

        do {
            // uses your InventoryDataManager
            let items = try await InventoryDataManager.shared.fetchInventory(eventId: id)

            // Sum quantities per sourceType
            var sentSum = 0
            var receivedSum = 0
            for it in items {
                let src = (it.sourceType ?? "").lowercased()
                if src == "vendor" {
                    receivedSum += it.quantity
                } else {
                    // treat anything else as planner/sent
                    sentSum += it.quantity
                }
            }

            queue.async(flags: .barrier) {
                self.sentQuantityCache[id] = sentSum
                self.receivedQuantityCache[id] = receivedSum
                self.inProgressLoads.remove(id)
            }

            // Post update on main thread (UI consumers can listen)
            NotificationCenter.default.post(
                name: .inventoryCountsUpdated,
                object: nil,
                userInfo: ["eventId": id, "sent": sentSum, "received": receivedSum]
            )
        } catch {
            queue.async(flags: .barrier) { self.inProgressLoads.remove(id) }
            print("InventoryManager.loadCounts error for \(id):", error)
        }
    }

    // allow clearing caches
    func clearCache(forEventId id: String? = nil) {
        queue.async(flags: .barrier) {
            if let id = id {
                self.sentQuantityCache.removeValue(forKey: id)
                self.receivedQuantityCache.removeValue(forKey: id)
            } else {
                self.sentQuantityCache.removeAll()
                self.receivedQuantityCache.removeAll()
            }
        }
    }
}

extension Notification.Name {
    static let inventoryCountsUpdated = Notification.Name("InventoryManager.inventoryCountsUpdated")
}

