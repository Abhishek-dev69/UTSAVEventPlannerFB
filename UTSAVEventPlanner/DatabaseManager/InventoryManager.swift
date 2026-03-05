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
        
        // 1️⃣ USE CACHE FIRST
        if let cached = InventoryCountsStore.shared.counts(for: eventId) {
            
            queue.async(flags:.barrier) {
                self.allocatedCache[eventId] = cached.0
                self.receivedCache[eventId] = cached.1
                self.pendingCache[eventId] = cached.2
                self.lostCache[eventId] = cached.3
            }
            
            NotificationCenter.default.post(
                name: .inventoryCountsUpdated,
                object: nil,
                userInfo:["eventId":eventId]
            )
        }
        
        var shouldLoad = false
        queue.sync(flags:.barrier) {
            if !inProgress.contains(eventId) {
                inProgress.insert(eventId)
                shouldLoad = true
            }
        }
        
        guard shouldLoad else { return }
        
        do {
            
            async let itemsTask =
            InventoryDataManager.shared.fetchInventory(eventId: eventId)
            
            async let lostTask =
            InventoryDataManager.shared.fetchLostPostEventRows(eventId: eventId)
            
            async let pendingTask =
            InventoryDataManager.shared.fetchPendingPostEventRows(eventId: eventId)
            
            let items = try await itemsTask
            let lostRows = try await lostTask
            let pendingRows = try await pendingTask
            
            let allocated = items.reduce(0){ $0 + $1.quantity }
            let lost = lostRows.reduce(0){ $0 + $1.postQty }
            let pending = pendingRows.reduce(0){ $0 + $1.postQty }
            
            let received = max(allocated - pending - lost,0)
            
            queue.async(flags:.barrier){
                
                self.allocatedCache[eventId] = allocated
                self.receivedCache[eventId] = received
                self.pendingCache[eventId] = pending
                self.lostCache[eventId] = lost
                
                self.inProgress.remove(eventId)
            }
            
            // 2️⃣ SAVE TO DISK
            InventoryCountsStore.shared.set(
                eventId: eventId,
                allocated: allocated,
                received: received,
                pending: pending,
                lost: lost
            )
            
            NotificationCenter.default.post(
                name: .inventoryCountsUpdated,
                object: nil,
                userInfo:["eventId":eventId]
            )
            
        } catch {
            
            queue.async(flags:.barrier){
                self.inProgress.remove(eventId)
            }
            
            print("InventoryManager error:",error)
        }
    }
}

extension Notification.Name {
    static let inventoryCountsUpdated = Notification.Name("InventoryManager.inventoryCountsUpdated")
}


