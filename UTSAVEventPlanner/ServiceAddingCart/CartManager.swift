// CartManager.swift – defensive mapping to tolerate optional CartItemRecord fields
import Foundation
import UIKit

// MARK: - MODEL
struct CartItem: Equatable {
    var id: String?
    var serviceId: String?
    var serviceName: String
    var subserviceId: String
    var subserviceName: String
    var rate: Double
    var unit: String
    var quantity: Int
    var sourceType: String

    var lineTotal: Double { rate * Double(quantity) }

    static func ==(lhs: CartItem, rhs: CartItem) -> Bool {
        return lhs.subserviceId == rhs.subserviceId
    }
}

protocol CartObserver: AnyObject {
    func cartDidChange()
}

extension Notification.Name {
    static let CartItemPersisted = Notification.Name("CartItemPersisted")
}

// MARK: - MANAGER
final class CartManager {

    static let shared = CartManager()
    private init() {}

    private(set) var items: [CartItem] = [] {
        didSet { notify() }
    }

    private var observers = NSHashTable<AnyObject>.weakObjects()

    func addObserver(_ o: CartObserver) { observers.add(o) }
    func removeObserver(_ o: CartObserver) { observers.remove(o) }

    private func notify() {
        DispatchQueue.main.async {
            for case let ob as CartObserver in self.observers.allObjects {
                ob.cartDidChange()
            }
        }
    }

    // MARK: - Load From Server
    func loadFromServer(eventId: String? = nil) {
        Task {
            do {
                let uid = try await SupabaseManager.shared.ensureUserId()
                let records = try await SupabaseManager.shared.fetchCartItems(userId: uid, eventId: eventId)

                // Defensive mapping -> use defaults when fields missing
                let mapped = records.map { (r: CartItemRecord) -> CartItem in
                    CartItem(
                        id: r.id,
                        serviceId: r.serviceId,
                        serviceName: r.serviceName ?? "",
                        subserviceId: r.subserviceId ?? UUID().uuidString,
                        subserviceName: r.subserviceName ?? "",
                        rate: r.rate ?? 0.0,
                        unit: r.unit ?? "",
                        quantity: r.quantity ?? 0,
                        sourceType: r.sourceType ?? "in_house"
                    )
                }

                DispatchQueue.main.async { self.items = mapped }
            } catch {
                print("❌ Cart load failed:", error)
            }
        }
    }

    // MARK: - ADD ITEM (attempt to attach eventId if available)
    func addItem(
        serviceId: String?,
        serviceName: String,
        subserviceId: String,
        subserviceName: String,
        rate: Double,
        unit: String,
        quantity: Int = 1,
        sourceType: String
    ) {
        print("🟢 addItem → \(subserviceName) x\(quantity)")

        // --- LOCAL MERGE (instant) ---
        if let idx = items.firstIndex(where: { $0.subserviceId == subserviceId }) {
            items[idx].quantity += quantity
        } else {
            let newItem = CartItem(
                id: nil,
                serviceId: serviceId,
                serviceName: serviceName,
                subserviceId: subserviceId,
                subserviceName: subserviceName,
                rate: rate,
                unit: unit,
                quantity: quantity,
                sourceType: sourceType
            )
            items.append(newItem)
        }
        notify()

        // --- REMOTE MERGE (background but robust) ---
        Task {
            do {
                let uid = try await SupabaseManager.shared.ensureUserId()

                // if you have an EventDataManager with currentEventId, replace the reflection below
                var currentEventId: String? = nil
                if let evManagerType = NSClassFromString("EventDataManager") as AnyObject?,
                   let shared = evManagerType.value(forKey: "shared") as? AnyObject {
                    if let eId = (shared.value(forKey: "currentEventId") as? String) {
                        currentEventId = eId
                    }
                }

                // fetch server items for the user (user-scoped)
                let serverItems = try await SupabaseManager.shared.fetchCartItems(userId: uid)

                // CASE 1 — exists on server → update quantity
                if let existing = serverItems.first(where: { ($0.subserviceId ?? "") == subserviceId }) {
                    let existingQty = existing.quantity ?? 0
                    let newQty = existingQty + quantity
                    let updated = try await SupabaseManager.shared.updateCartItemQuantity(
                        cartItemId: existing.id,
                        quantity: newQty
                    )

                    DispatchQueue.main.async {
                        if let i = self.items.firstIndex(where: { $0.subserviceId == subserviceId }) {
                            self.items[i].id = updated.id
                            self.items[i].quantity = updated.quantity ?? self.items[i].quantity
                            self.notify()
                        }
                        NotificationCenter.default.post(name: .CartItemPersisted, object: nil, userInfo: ["eventId": updated.eventId as Any, "cartItemId": updated.id])
                    }
                    return
                }

                // CASE 2 — insert new row; pass eventId if discovered
                let inserted = try await SupabaseManager.shared.insertCartItem(
                    userId: uid,
                    eventId: currentEventId,
                    serviceId: serviceId,
                    serviceName: serviceName,
                    subserviceId: subserviceId,
                    subserviceName: subserviceName,
                    rate: rate,
                    unit: unit,
                    quantity: quantity,
                    sourceType: sourceType
                )

                DispatchQueue.main.async {
                    if let i = self.items.firstIndex(where: { $0.subserviceId == subserviceId }) {
                        self.items[i].id = inserted.id
                        self.items[i].quantity = inserted.quantity ?? self.items[i].quantity
                        // if serviceName was missing server-side, keep local serviceName
                        if let srv = inserted.serviceName { self.items[i].serviceName = srv }
                        if let ssrv = inserted.subserviceName { self.items[i].subserviceName = ssrv }
                        self.notify()
                    }
                    NotificationCenter.default.post(name: .CartItemPersisted, object: nil, userInfo: ["eventId": inserted.eventId as Any, "cartItemId": inserted.id])
                }

            } catch {
                print("❌ addItem persist failed:", error)
                // rollback local change (safe)
                DispatchQueue.main.async {
                    if let i = self.items.firstIndex(where: { $0.subserviceId == subserviceId }) {
                        self.items[i].quantity -= quantity
                        if self.items[i].quantity <= 0 {
                            self.items.remove(at: i)
                        }
                        self.notify()
                    }
                }
            }
        }
    }

    // MARK: - Other methods (setQuantity, removeItem, clear) stay similar but use defensive mapping
    func setQuantity(serviceName: String, subserviceName: String, quantity: Int) {
        guard let idx = items.firstIndex(where: {
            $0.serviceName == serviceName && $0.subserviceName == subserviceName
        }) else { return }

        let subId = items[idx].subserviceId
        let oldQty = items[idx].quantity

        items[idx].quantity = quantity
        notify()

        Task {
            do {
                let uid = try await SupabaseManager.shared.ensureUserId()
                let serverItems = try await SupabaseManager.shared.fetchCartItems(userId: uid)

                if let server = serverItems.first(where: { ($0.subserviceId ?? "") == subId }) {

                    if quantity <= 0 {
                        try await SupabaseManager.shared.deleteCartItem(cartItemId: server.id)
                        DispatchQueue.main.async {
                            if let i = self.items.firstIndex(where: { $0.subserviceId == subId }) {
                                self.items.remove(at: i)
                                self.notify()
                            }
                        }
                    } else {
                        let updated = try await SupabaseManager.shared.updateCartItemQuantity(
                            cartItemId: server.id,
                            quantity: quantity
                        )
                        DispatchQueue.main.async {
                            if let i = self.items.firstIndex(where: { $0.subserviceId == subId }) {
                                self.items[i].quantity = updated.quantity ?? self.items[i].quantity
                                self.items[i].id = updated.id
                                if let srv = updated.serviceName { self.items[i].serviceName = srv }
                                if let ssrv = updated.subserviceName { self.items[i].subserviceName = ssrv }
                                self.notify()
                            }
                            NotificationCenter.default.post(name: .CartItemPersisted, object: nil, userInfo: ["eventId": updated.eventId as Any, "cartItemId": updated.id])
                        }
                    }

                } else if quantity > 0 {
                    let local = items[idx]
                    let inserted = try await SupabaseManager.shared.insertCartItem(
                        userId: uid,
                        eventId: nil,
                        serviceId: local.serviceId,
                        serviceName: local.serviceName,
                        subserviceId: local.subserviceId,
                        subserviceName: local.subserviceName,
                        rate: local.rate,
                        unit: local.unit,
                        quantity: quantity,
                        sourceType: local.sourceType
                    )
                    DispatchQueue.main.async {
                        if let i = self.items.firstIndex(where: { $0.subserviceId == subId }) {
                            self.items[i].id = inserted.id
                            self.items[i].quantity = inserted.quantity ?? self.items[i].quantity
                            if let srv = inserted.serviceName { self.items[i].serviceName = srv }
                            if let ssrv = inserted.subserviceName { self.items[i].subserviceName = ssrv }
                            self.notify()
                        }
                        NotificationCenter.default.post(name: .CartItemPersisted, object: nil, userInfo: ["eventId": inserted.eventId as Any, "cartItemId": inserted.id])
                    }
                }

            } catch {
                print("❌ setQuantity failed:", error)
                DispatchQueue.main.async {
                    self.items[idx].quantity = oldQty
                    self.notify()
                }
            }
        }
    }

    func removeItem(serviceName: String, subserviceName: String) {
        guard let idx = items.firstIndex(where: {
            $0.serviceName == serviceName && $0.subserviceName == subserviceName
        }) else { return }

        let subId = items[idx].subserviceId
        let backup = items

        items.remove(at: idx)
        notify()

        Task {
            do {
                let serverItems = try await SupabaseManager.shared.fetchCartItems()
                if let server = serverItems.first(where: { ($0.subserviceId ?? "") == subId }) {
                    try await SupabaseManager.shared.deleteCartItem(cartItemId: server.id)
                }
            } catch {
                print("❌ removeItem failed:", error)
                DispatchQueue.main.async {
                    self.items = backup
                    self.notify()
                }
            }
        }
    }

    func clear() {
        let backup = items
        items.removeAll()
        notify()

        Task {
            do {
                let serverItems = try await SupabaseManager.shared.fetchCartItems()
                for s in serverItems {
                    try await SupabaseManager.shared.deleteCartItem(cartItemId: s.id)
                }
            } catch {
                print("❌ clear failed:", error)
                DispatchQueue.main.async {
                    self.items = backup
                    self.notify()
                }
            }
        }
    }

    // MARK: - TOTALS
    func totalItems() -> Int { items.reduce(0) { $0 + $1.quantity } }
    func totalAmount() -> Double { items.reduce(0) { $0 + $1.lineTotal } }
}


