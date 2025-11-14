//
// CartManager.swift
//

import Foundation
import UIKit
import Supabase

struct CartItem: Equatable {
    var id: String?              // cart_items.id from Supabase
    var serviceName: String
    var subserviceId: String?    // may be "local-xxxx" locally or server uuid after sync
    var subserviceName: String
    var rate: Double
    var unit: String
    var quantity: Int

    var lineTotal: Double { return Double(quantity) * rate }

    static func == (lhs: CartItem, rhs: CartItem) -> Bool {
        if let lId = lhs.subserviceId, let rId = rhs.subserviceId {
            return lId == rId
        }
        return lhs.serviceName == rhs.serviceName &&
               lhs.subserviceName == rhs.subserviceName
    }
}

protocol CartObserver: AnyObject {
    func cartDidChange()
}

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
        for case let o as CartObserver in observers.allObjects {
            DispatchQueue.main.async { o.cartDidChange() }
        }
    }

    // Load server-synced items
    func loadFromServer() {
        Task {
            do {
                _ = try await SupabaseManager.shared.ensureUserId()
                let records = try await SupabaseManager.shared.fetchCartItems()

                let mapped = records.map {
                    CartItem(
                        id: $0.id,
                        serviceName: $0.service_name,
                        subserviceId: $0.subservice_id,
                        subserviceName: $0.subservice_name,
                        rate: $0.rate,
                        unit: $0.unit ?? "",
                        quantity: $0.quantity
                    )
                }

                DispatchQueue.main.async {
                    self.items = mapped
                }
            } catch {
                print("❌ Cart load failed:", error)
            }
        }
    }

    // Add item (optimistic + merge)
    func addItem(serviceName: String, subserviceId: String?, subserviceName: String, rate: Double, unit: String, quantity: Int = 1) {
        print("🟢 CartManager.addItem CALLED for \(subserviceName) qty:\(quantity)")

        // optimistic update
        if let idx = items.firstIndex(where: { $0.serviceName == serviceName && $0.subserviceName == subserviceName }) {
            items[idx].quantity += quantity
        } else {
            let tempId = subserviceId ?? "local-\(UUID().uuidString)"
            items.append(CartItem(id: nil, serviceName: serviceName, subserviceId: tempId, subserviceName: subserviceName, rate: rate, unit: unit, quantity: quantity))
        }
        notify()

        // persist remote
        Task {
            do {
                let uid = try await SupabaseManager.shared.ensureUserId()
                let serverItems = try await SupabaseManager.shared.fetchCartItems()

                // 1) merge by provided subservice id (server uuid)
                if let sid = subserviceId, let existing = serverItems.first(where: { $0.subservice_id == sid }) {
                    let newQty = existing.quantity + quantity
                    let updated = try await SupabaseManager.shared.updateCartItemQuantity(cartItemId: existing.id, quantity: newQty)
                    DispatchQueue.main.async {
                        if let i = self.items.firstIndex(where: { $0.serviceName == updated.service_name && $0.subserviceName == updated.subservice_name }) {
                            self.items[i].id = updated.id
                            self.items[i].subserviceId = updated.subservice_id
                            self.items[i].quantity = updated.quantity
                            self.notify()
                        }
                    }
                    return
                }

                // 2) fallback merge by name
                if let existing = serverItems.first(where: { $0.subservice_name == subserviceName && $0.service_name == serviceName }) {
                    let newQty = existing.quantity + quantity
                    let updated = try await SupabaseManager.shared.updateCartItemQuantity(cartItemId: existing.id, quantity: newQty)
                    DispatchQueue.main.async {
                        if let i = self.items.firstIndex(where: { $0.serviceName == updated.service_name && $0.subserviceName == updated.subservice_name }) {
                            self.items[i].id = updated.id
                            self.items[i].subserviceId = updated.subservice_id
                            self.items[i].quantity = updated.quantity
                            self.notify()
                        }
                    }
                    return
                }

                // 3) insert new
                let backendSubId: String
                if let sid = subserviceId {
                    backendSubId = sid.starts(with: "local-") ? String(sid.dropFirst("local-".count)) : sid
                } else {
                    backendSubId = UUID().uuidString
                }

                let inserted = try await SupabaseManager.shared.insertCartItem(
                    userId: uid,
                    serviceId: nil,
                    serviceName: serviceName,
                    subserviceId: backendSubId,
                    subserviceName: subserviceName,
                    rate: rate,
                    unit: unit,
                    quantity: quantity
                )

                DispatchQueue.main.async {
                    if let i = self.items.firstIndex(where: { $0.serviceName == inserted.service_name && $0.subserviceName == inserted.subservice_name }) {
                        self.items[i].id = inserted.id
                        self.items[i].subserviceId = inserted.subservice_id
                        self.items[i].quantity = inserted.quantity
                        self.notify()
                    } else {
                        self.items.append(CartItem(id: inserted.id, serviceName: inserted.service_name, subserviceId: inserted.subservice_id, subserviceName: inserted.subservice_name, rate: inserted.rate, unit: inserted.unit ?? "", quantity: inserted.quantity))
                        self.notify()
                    }
                }
            } catch {
                print("Failed to persist add:", error)
                // rollback optimistic update
                DispatchQueue.main.async {
                    if let idx = self.items.firstIndex(where: { $0.serviceName == serviceName && $0.subserviceName == subserviceName }) {
                        self.items[idx].quantity = max(0, self.items[idx].quantity - quantity)
                        if self.items[idx].quantity == 0 {
                            self.items.remove(at: idx)
                        }
                        self.notify()
                    }
                }
            }
        }
    }

    // set quantity
    func setQuantity(serviceName: String, subserviceName: String, quantity: Int) {
        guard let idx = items.firstIndex(where: { $0.serviceName == serviceName && $0.subserviceName == subserviceName }) else { return }
        let oldQty = items[idx].quantity
        items[idx].quantity = quantity
        notify()

        Task {
            do {
                _ = try await SupabaseManager.shared.ensureUserId()
                let serverItems = try await SupabaseManager.shared.fetchCartItems()
                if let server = serverItems.first(where: { $0.subservice_name == subserviceName && $0.service_name == serviceName }) {
                    if quantity <= 0 {
                        try await SupabaseManager.shared.deleteCartItem(cartItemId: server.id)
                    } else {
                        _ = try await SupabaseManager.shared.updateCartItemQuantity(cartItemId: server.id, quantity: quantity)
                    }
                } else if quantity > 0 {
                    let backendSubId = items[idx].subserviceId?.replacingOccurrences(of: "local-", with: "") ?? UUID().uuidString
                    _ = try await SupabaseManager.shared.insertCartItem(userId: try await SupabaseManager.shared.ensureUserId(), serviceId: nil, serviceName: serviceName, subserviceId: backendSubId, subserviceName: subserviceName, rate: items[idx].rate, unit: items[idx].unit, quantity: quantity)
                }
            } catch {
                print("Failed setQuantity:", error)
                DispatchQueue.main.async {
                    if let i = self.items.firstIndex(where: { $0.serviceName == serviceName && $0.subserviceName == subserviceName }) {
                        self.items[i].quantity = oldQty
                        self.notify()
                    }
                }
            }
        }
    }

    func removeItem(serviceName: String, subserviceName: String) {
        let old = items
        items.removeAll { $0.serviceName == serviceName && $0.subserviceName == subserviceName }
        notify()

        Task {
            do {
                let serverItems = try await SupabaseManager.shared.fetchCartItems()
                if let server = serverItems.first(where: { $0.subservice_name == subserviceName && $0.service_name == serviceName }) {
                    try await SupabaseManager.shared.deleteCartItem(cartItemId: server.id)
                }
            } catch {
                print("removeItem failed:", error)
                DispatchQueue.main.async {
                    self.items = old
                    self.notify()
                }
            }
        }
    }

    func totalItems() -> Int { items.reduce(0) { $0 + $1.quantity } }
    func totalAmount() -> Double { items.reduce(0) { $0 + $1.lineTotal } }

    func clear() {
        let old = items
        items.removeAll()
        notify()

        Task {
            do {
                let serverItems = try await SupabaseManager.shared.fetchCartItems()
                for s in serverItems {
                    try await SupabaseManager.shared.deleteCartItem(cartItemId: s.id)
                }
            } catch {
                print("clear failed:", error)
                DispatchQueue.main.async {
                    self.items = old
                    self.notify()
                }
            }
        }
    }
}

