import Foundation

final class InventoryManager {

    static let shared = InventoryManager()
    private init() {}

    // caches: store summed quantities
    private var sentQuantityCache: [String: Int] = [:]      // planner quantities
    private var receivedQuantityCache: [String: Int] = [:]  // vendor quantities

    // in-progress loads
    private var inProgressLoads: Set<String> = []

    private let queue = DispatchQueue(label: "inventory.manager.queue", attributes: .concurrent)

    // MARK: - Cached accessors
    func cachedSentQuantity(forEventId id: String) -> Int? {
        queue.sync { sentQuantityCache[id] }
    }

    func cachedReceivedQuantity(forEventId id: String) -> Int? {
        queue.sync { receivedQuantityCache[id] }
    }

    // MARK: - Load counts (sums quantities by source_type)
    func loadCounts(forEventId id: String) async {
        var shouldLoad = false
        queue.sync(flags: .barrier) {
            if !inProgressLoads.contains(id) {
                inProgressLoads.insert(id)
                shouldLoad = true
            }
        }
        guard shouldLoad else { return }

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

            await MainActor.run {
                NotificationCenter.default.post(
                    name: .inventoryCountsUpdated,
                    object: nil,
                    userInfo: ["eventId": id, "sent": sentSum, "received": receivedSum]
                )
            }
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

