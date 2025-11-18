// CartManager.swift – FINAL FIXED VERSION
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

    // MARK: - Correct eventId lookup
    private func currentEventId() -> String? {
        return EventSession.shared.currentEventId
    }

    // MARK: - Load From Server
    func loadFromServer(eventId: String? = nil) {
        Task {
            do {
                let uid = try await SupabaseManager.shared.ensureUserId()
                let eId = eventId ?? currentEventId()

                let records = try await SupabaseManager.shared.fetchCartItems(
                    userId: uid,
                    eventId: eId
                )

                let mapped = records.map { r in
                    CartItem(
                        id: r.id,
                        serviceId: r.serviceId,
                        serviceName: r.serviceName ?? "",
                        subserviceId: r.subserviceId ?? UUID().uuidString,
                        subserviceName: r.subserviceName ?? "",
                        rate: r.rate ?? 0,
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

    // MARK: - ADD ITEM
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
        print("🟢 addItem → \(subserviceName)")

        // Local merge
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

        // Server merge
        Task {
            do {
                let uid = try await SupabaseManager.shared.ensureUserId()
                let eId = currentEventId()

                let serverItems = try await SupabaseManager.shared.fetchCartItems(userId: uid, eventId: eId)

                // CASE 1 — update existing
                if let existing = serverItems.first(where: { ($0.subserviceId ?? "") == subserviceId }) {

                    let newQty = (existing.quantity ?? 0) + quantity

                    let updated = try await SupabaseManager.shared.updateCartItemQuantity(
                        cartItemId: existing.id,
                        quantity: newQty
                    )

                    DispatchQueue.main.async {
                        if let i = self.items.firstIndex(where: { $0.subserviceId == subserviceId }) {
                            self.items[i].id = updated.id
                            self.items[i].quantity = updated.quantity ?? self.items[i].quantity
                        }
                        self.notify()
                    }
                    return
                }

                // CASE 2 — insert new row
                let inserted = try await SupabaseManager.shared.insertCartItem(
                    userId: uid,
                    eventId: eId,
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
                    if let index = self.items.firstIndex(where: { $0.subserviceId == subserviceId }) {
                        self.items[index].id = inserted.id
                        self.items[index].quantity = inserted.quantity ?? self.items[index].quantity
                    }
                    self.notify()
                }

            } catch {
                print("❌ addItem failed:", error)
            }
        }
    }

    // MARK: - SET QUANTITY
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
                let eId = currentEventId()

                let serverItems = try await SupabaseManager.shared.fetchCartItems(userId: uid, eventId: eId)

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
                            self.items[idx].quantity = updated.quantity ?? quantity
                            self.items[idx].id = updated.id
                            self.notify()
                        }
                    }

                } else if quantity > 0 {

                    let local = items[idx]

                    let inserted = try await SupabaseManager.shared.insertCartItem(
                        userId: uid,
                        eventId: eId,
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
                        self.items[idx].id = inserted.id
                        self.items[idx].quantity = inserted.quantity ?? quantity
                        self.notify()
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

    // MARK: - REMOVE ITEM
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
                let uid = try await SupabaseManager.shared.ensureUserId()
                let eId = currentEventId()

                let serverItems = try await SupabaseManager.shared.fetchCartItems(
                    userId: uid,
                    eventId: eId
                )

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

    // MARK: - CLEAR CART
    func clear() {
        let backup = items
        items.removeAll()
        notify()

        Task {
            do {
                let uid = try await SupabaseManager.shared.ensureUserId()
                let eId = currentEventId()

                let serverItems = try await SupabaseManager.shared.fetchCartItems(
                    userId: uid,
                    eventId: eId
                )

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

