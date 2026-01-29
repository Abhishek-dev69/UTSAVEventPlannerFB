import Foundation

final class InventoryManager {

    static let shared = InventoryManager()
    private init() {}

    private let queue = DispatchQueue(label: "inventory.manager.queue", attributes: .concurrent)

    private var allocatedCache: [String: Int] = [:]
    private var receivedCache: [String: Int] = [:]
    private var lostCache: [String: Int] = [:]

    private var inProgress: Set<String> = []
    private var pendingCache: [String: Int] = [:]


    // MARK: - Cached getters
    func allocated(for eventId: String) -> Int {
        queue.sync { allocatedCache[eventId] ?? 0 }
    }

    func received(for eventId: String) -> Int {
        queue.sync { receivedCache[eventId] ?? 0 }
    }

    func lost(for eventId: String) -> Int {
        queue.sync { lostCache[eventId] ?? 0 }
    }
    func notReceived(for eventId: String) -> Int {
        queue.sync { pendingCache[eventId] ?? 0 }
    }


    // MARK: - Load counts
    @MainActor
    func loadCounts(forEventId eventId: String) async {
        var shouldLoad = false
        queue.sync(flags: .barrier) {
            if !inProgress.contains(eventId) {
                inProgress.insert(eventId)
                shouldLoad = true
            }
        }
        guard shouldLoad else { return }

        do {
            // 1️⃣ Allocated
            let items = try await InventoryDataManager.shared.fetchInventory(eventId: eventId)
            let allocated = items.reduce(0) { $0 + $1.quantity }

            // 2️⃣ Lost / Damaged
            let lostRows = try await InventoryDataManager.shared.fetchLostPostEventRows(eventId: eventId)
            let lost = lostRows.reduce(0) { $0 + $1.postQty }

            // 3️⃣ Received = Allocated - Pending - Lost
            let pendingRows = try await InventoryDataManager.shared.fetchPendingPostEventRows(eventId: eventId)
            let pending = pendingRows.reduce(0) { $0 + $1.postQty }

            let received = max(allocated - pending - lost, 0)
            let notReceived = pending

            queue.async(flags: .barrier) {
                self.allocatedCache[eventId] = allocated
                self.receivedCache[eventId] = received
                self.lostCache[eventId] = lost
                self.pendingCache[eventId] = notReceived   // ✅ NEW
                self.inProgress.remove(eventId)
            }

            NotificationCenter.default.post(
                name: .inventoryCountsUpdated,
                object: nil,
                userInfo: ["eventId": eventId]
            )

        } catch {
            queue.async(flags: .barrier) { self.inProgress.remove(eventId) }
            print("InventoryManager error:", error)
        }
    }
}

extension Notification.Name {
    static let inventoryCountsUpdated = Notification.Name("InventoryManager.inventoryCountsUpdated")
}


