// CartManager.swift – UPDATED with addOutsource(item:) helper
import Foundation
import UIKit
import Supabase

// MARK: - MODEL
struct CartItem: Codable, Equatable {

    var id: String?
    var serviceId: String?
    var serviceName: String
    var subserviceId: String
    var subserviceName: String
    var rate: Double
    var unit: String
    var quantity: Int
    var cartSessionId: String?   // ✅ ADD
    var eventId: String?         // ✅ ADD
    var userId: String?          // ✅ ADD

    var lineTotal: Double { rate * Double(quantity) }

    enum CodingKeys: String, CodingKey {
        case id
        case serviceId = "service_id"
        case serviceName = "service_name"
        case subserviceId = "subservice_id"
        case subserviceName = "subservice_name"
        case rate
        case unit
        case quantity
        case cartSessionId = "cart_session_id"
        case eventId = "event_id"
        case userId = "user_id"
    }

    static func ==(lhs: CartItem, rhs: CartItem) -> Bool {
        return lhs.subserviceId == rhs.subserviceId
    }
}
struct QuotationPDFData {
    let eventName: String
    let clientName: String
    let location: String
    let eventDate: String

    let items: [CartItem]
    let subtotal: Double
    let tax: Double
    let discount: Double
    let grandTotal: Double
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

    // changing items triggers notify() via didSet
    private(set) var items: [CartItem] = [] {
        didSet { notify() }
    }

    private var observers = NSHashTable<AnyObject>.weakObjects()

    func addObserver(_ o: CartObserver) { observers.add(o) }
    func removeObserver(_ o: CartObserver) { observers.remove(o) }
    private func currentSessionId() -> String? {
        return CartSession.shared.currentSessionId
    }

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
                    eventId: eId,
                    cartSessionId: nil   // ✅ always load by event_id
                )

                let mapped = records.map { r -> CartItem in

                    // ✅ RAW VALUES FROM DB
                    let rawServiceName = (r.serviceName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    let rawSubserviceName = (r.subserviceName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

                    // ✅ SMART FALLBACK LOGIC (CRITICAL 🔥)
                    let finalServiceName: String
                    if !rawServiceName.isEmpty {
                        finalServiceName = rawServiceName
                    } else if !rawSubserviceName.isEmpty {
                        finalServiceName = rawSubserviceName   // fallback to subservice name
                    } else {
                        finalServiceName = "Service"
                    }

                    let finalSubserviceName: String
                    if !rawSubserviceName.isEmpty {
                        finalSubserviceName = rawSubserviceName
                    } else {
                        finalSubserviceName = finalServiceName
                    }

                    print("🟢 LOAD CART ITEM → service:", finalServiceName, "sub:", finalSubserviceName)

                    return CartItem(
                        id: r.id,
                        serviceId: r.serviceId,
                        serviceName: finalServiceName,
                        subserviceId: r.subserviceId ?? UUID().uuidString,
                        subserviceName: finalSubserviceName,
                        rate: r.rate ?? 0,
                        unit: r.unit ?? "",
                        quantity: r.quantity ?? 0
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

    // MARK: - Convenience: add outsource item safely (prevents swapped args)
    /// Call this when you receive an OutsourceItem from OutsourceFormView.
    /// This guarantees serviceName/subserviceName are wired correctly
    // MARK: - ADD ITEM (canonical: uses subserviceId as unique key)
    func addItem(
        serviceId: String?,
        serviceName: String,
        subserviceId: String,
        subserviceName: String,
        rate: Double,
        unit: String,
        quantity: Int = 1,
        metadata: [String: String]? = nil
    ) {

        // ✅ NORMALIZE NAMES (CRITICAL FIX 🔥)
        let safeServiceName = serviceName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty ? "Service" : serviceName.trimmingCharacters(in: .whitespacesAndNewlines)

        let safeSubserviceName = subserviceName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty ? safeServiceName : subserviceName.trimmingCharacters(in: .whitespacesAndNewlines)

        print("🟢 addItem → \(safeSubserviceName) [subserviceId: \(subserviceId)]")

        // ✅ Local merge
        if let idx = items.firstIndex(where: {
            $0.subserviceId == subserviceId ||
            ($0.serviceName == safeServiceName && $0.subserviceName == safeSubserviceName)
        }) {
            items[idx].quantity += quantity
            notify()
        } else {
            let newItem = CartItem(
                id: nil,
                serviceId: serviceId,
                serviceName: safeServiceName,
                subserviceId: subserviceId,
                subserviceName: safeSubserviceName,
                rate: rate,
                unit: unit,
                quantity: quantity
            )
            items.append(newItem)
        }

        // ✅ Server merge
        Task {
            do {
                let uid = try await SupabaseManager.shared.ensureUserId()
                let eId = currentEventId()

                let serverItems = try await SupabaseManager.shared.fetchCartItems(
                    userId: uid,
                    eventId: eId,
                    cartSessionId: nil   // ✅ IMPORTANT FIX (don’t filter by session)
                )

                // ✅ CASE 1 — update existing item
                if let existing = serverItems.first(where: {
                    ($0.subserviceId ?? "") == subserviceId ||
                    (
                        ($0.serviceName ?? "").trimmingCharacters(in: .whitespacesAndNewlines) == safeServiceName &&
                        ($0.subserviceName ?? "").trimmingCharacters(in: .whitespacesAndNewlines) == safeSubserviceName
                    )
                }) {

                    let newQty = (existing.quantity ?? 0) + quantity

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
                    }
                    return
                }

                // ✅ CASE 2 — insert new row
                let inserted = try await SupabaseManager.shared.insertCartItem(
                    userId: uid,
                    eventId: eId,
                    cartSessionId: self.currentSessionId(),
                    serviceId: serviceId,
                    serviceName: safeServiceName,        // ✅ FIXED
                    subserviceId: subserviceId,
                    subserviceName: safeSubserviceName,  // ✅ FIXED
                    rate: rate,
                    unit: unit,
                    quantity: quantity
                )

                DispatchQueue.main.async {
                    if let index = self.items.firstIndex(where: { $0.subserviceId == subserviceId }) {
                        self.items[index].id = inserted.id
                        self.items[index].quantity = inserted.quantity ?? self.items[index].quantity
                        self.notify()
                    }
                }

            } catch {
                print("❌ addItem failed:", error)
            }
        }
    }

    // MARK: - SET QUANTITY (canonical by subserviceId)
    func setQuantity(subserviceId: String, quantity: Int) {
        guard let idx = items.firstIndex(where: { $0.subserviceId == subserviceId }) else { return }

        let oldQty = items[idx].quantity
        items[idx].quantity = quantity
        notify()

        Task {
            do {
                let uid = try await SupabaseManager.shared.ensureUserId()
                let eId = currentEventId()

                let serverItems = try await SupabaseManager.shared.fetchCartItems(userId: uid, eventId: eId)

                if let server = serverItems.first(where: { ($0.subserviceId ?? "") == subserviceId }) {

                    if quantity <= 0 {
                        try await SupabaseManager.shared.deleteCartItem(cartItemId: server.id)

                        DispatchQueue.main.async {
                            if let i = self.items.firstIndex(where: { $0.subserviceId == subserviceId }) {
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
                            if let i = self.items.firstIndex(where: { $0.subserviceId == subserviceId }) {
                                self.items[i].quantity = updated.quantity ?? quantity
                                self.items[i].id = updated.id
                                self.notify()
                            }
                        }
                    }

                } else if quantity > 0 {
                    // server did not have this item — insert
                    let local = items[idx]

                    let inserted = try await SupabaseManager.shared.insertCartItem(
                        userId: uid,
                        eventId: eId,
                        cartSessionId: currentSessionId(),   // ✅ ADD
                        serviceId: local.serviceId,
                        serviceName: local.serviceName,
                        subserviceId: local.subserviceId,
                        subserviceName: local.subserviceName,
                        rate: local.rate,
                        unit: local.unit,
                        quantity: quantity
                    )
                    DispatchQueue.main.async {
                        if let i = self.items.firstIndex(where: { $0.subserviceId == subserviceId }) {
                            self.items[i].id = inserted.id
                            self.items[i].quantity = inserted.quantity ?? quantity
                            self.notify()
                        }
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

    // Backwards-compatible helper: setQuantity by serviceName+subserviceName — looks up subserviceId
    func setQuantity(serviceName: String, subserviceName: String, quantity: Int) {
        guard let idx = items.firstIndex(where: { $0.serviceName == serviceName && $0.subserviceName == subserviceName }) else { return }
        let subId = items[idx].subserviceId
        setQuantity(subserviceId: subId, quantity: quantity)
    }

    // MARK: - REMOVE ITEM (canonical by subserviceId)
    func removeItem(subserviceId: String) {
        guard let idx = items.firstIndex(where: { $0.subserviceId == subserviceId }) else { return }

        let backup = items
        items.remove(at: idx)
        // items.remove triggers didSet -> notify()

        Task {
            do {
                let uid = try await SupabaseManager.shared.ensureUserId()
                let eId = currentEventId()

                let serverItems = try await SupabaseManager.shared.fetchCartItems(
                    userId: uid,
                    eventId: eId,
                    cartSessionId: nil
                )

                if let server = serverItems.first(where: { ($0.subserviceId ?? "") == subserviceId }) {
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

    // Backwards-compatible helper: removeItem by names
    func removeItem(serviceName: String, subserviceName: String) {
        guard let idx = items.firstIndex(where: {
            $0.serviceName == serviceName && $0.subserviceName == subserviceName
        }) else { return }
        let subId = items[idx].subserviceId
        removeItem(subserviceId: subId)
    }
    // ✅ UI-only reset (use ONLY on logout)
    func resetLocalCart() {
        items.removeAll()
    }
    // MARK: - Vendor Payments Support
    func fetchAssignedVendorItemsForPlanner(plannerId: String) async throws -> [CartItemRecord] {

        let response = try await SupabaseManager.shared.client
            .from("cart_items")
            .select("*")
            .eq("assignment_status", value: "accepted")
            .eq("user_id", value: plannerId)
            .not("assigned_vendor_id", operator: .is, value: "null")
            .execute()

        return try JSONDecoder().decode([CartItemRecord].self, from: response.data)
    }


    // MARK: - CLEAR CART
    func clear() {
        let backup = items
        items.removeAll() // didSet -> notify()

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
    func setItems(_ items: [CartItem]) {
        self.items = items
        notify()
    }


    // MARK: - TOTALS
    func totalItems() -> Int { items.reduce(0) { $0 + $1.quantity } }
    func totalAmount() -> Double { items.reduce(0) { $0 + $1.lineTotal } }
}
