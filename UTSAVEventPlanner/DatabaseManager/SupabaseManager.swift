// SupabaseManager.swift
import Foundation
import Supabase

// MARK: - Codable Models
struct ServiceInsert: Codable {
    let name: String
}

struct SubserviceInsert: Codable {
    let service_id: String
    let name: String
    let rate: Double
    let unit: String
    let image_url: String?
}

// Make all potentially-missing DB fields optional so decoding never fails if backend omits a column.
struct CartItemRecord: Codable {
    let id: String
    let userId: String?
    let eventId: String?
    let serviceId: String?
    let serviceName: String?
    let subserviceId: String?
    let subserviceName: String?
    let rate: Double?
    let unit: String?
    let quantity: Int?
    let lineTotal: Double?
    let metadata: [String: String]?
    let createdAt: String?
    let updatedAt: String?
    let sourceType: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case eventId = "event_id"
        case serviceId = "service_id"
        case serviceName = "service_name"
        case subserviceId = "subservice_id"
        case subserviceName = "subservice_name"
        case rate, unit, quantity
        case lineTotal = "line_total"
        case metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case sourceType = "source_type"
    }
}

// CartInsert used when inserting to cart_items table
struct CartInsert: Encodable {
    let userId: String
    let eventId: String?
    let serviceId: String?
    let serviceName: String
    let subserviceId: String
    let subserviceName: String
    let rate: Double
    let unit: String?
    let quantity: Int
    let metadata: [String: String]?
    let sourceType: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case eventId = "event_id"
        case serviceId = "service_id"
        case serviceName = "service_name"
        case subserviceId = "subservice_id"
        case subserviceName = "subservice_name"
        case rate
        case unit
        case quantity
        case metadata
        case sourceType = "source_type"
    }
}

private struct QuantityUpdate: Codable {
    let quantity: Int
}

// MARK: - Supabase manager
final class SupabaseManager {
    static let shared = SupabaseManager()
    let client: SupabaseClient

    private init() {
        let supabaseURL = URL(string: "https://denikpjyrblzbomzamyu.supabase.co")!
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRlbmlrcGp5cmJsemJvbXphbXl1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMwNTExMzIsImV4cCI6MjA3ODYyNzEzMn0.k6kqcjIu-G0_YV9H1VjHfWaPahvl1RhMo9gBODYqUbo"
        client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }

    // Ensure we have a user session (anonymous sign-in fallback)
    func ensureUserId() async throws -> String {
        if let session = try? await client.auth.session {
            let user = session.user
            return user.id.uuidString
        }

        do {
            try await client.auth.signInAnonymously()
            if let session = try? await client.auth.session {
                let user = session.user
                return user.id.uuidString
            } else {
                throw NSError(domain: "SupabaseAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sign-in succeeded but session missing"])
            }
        } catch {
            print("ensureUserId: anonymous sign-in failed:", error)
            throw error
        }
    }

    // MARK: - Services & Subservices

    func createService(_ payload: ServiceCreatePayload) async throws -> ServiceRecord {
        let response = try await client
            .from("services")
            .insert(["name": payload.name])
            .select("*")
            .execute()

        if let raw = String(data: response.data, encoding: .utf8) {
            print("createService - service insert raw:", raw)
        }

        let createdServices = try JSONDecoder().decode([ServiceRecord].self, from: response.data)
        guard let created = createdServices.first else {
            throw NSError(domain: "SupabaseCreateService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service insert returned no rows"])
        }

        if !payload.subservices.isEmpty {
            let subPayloads: [SubserviceInsert] = payload.subservices.map { s in
                SubserviceInsert(
                    service_id: created.id,
                    name: s.name,
                    rate: s.rate,
                    unit: s.unit,
                    image_url: nil
                )
            }

            let subsResponse = try await client
                .from("subservices")
                .insert(subPayloads)
                .select("*")
                .execute()

            if let raw = String(data: subsResponse.data, encoding: .utf8) {
                print("createService - subservices insert raw:", raw)
            }
        }

        return created
    }

    func fetchServices() async throws -> [ServiceRecord] {
        let response = try await client
            .from("services")
            .select("id, name, created_at, subservices(id, service_id, name, rate, unit, image_url)")
            .execute()

        if let raw = String(data: response.data, encoding: .utf8) {
            print("fetchServices raw:", raw)
        }

        return try JSONDecoder().decode([ServiceRecord].self, from: response.data)
    }

    // MARK: - Cart Operations

    /// Fetch cart items for the current user and optionally filter by eventId.
    func fetchCartItems(userId: String? = nil, eventId: String? = nil) async throws -> [CartItemRecord] {
        let uid = try await (userId == nil || userId?.trimmingCharacters(in: .whitespacesAndNewlines) == "") ?
            ensureUserId() : userId!

        var query = client.from("cart_items").select("*").eq("user_id", value: uid)

        if let eId = eventId, !eId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            query = query.eq("event_id", value: eId)
        }

        let response = try await query.execute()

        if let raw = String(data: response.data, encoding: .utf8) {
            print("fetchCartItems raw:", raw)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([CartItemRecord].self, from: response.data)
    }

    /// Insert a cart item. Accepts optional eventId so it can be linked immediately.
    func insertCartItem(
        userId: String?,
        eventId: String?,
        serviceId: String?,
        serviceName: String,
        subserviceId: String,
        subserviceName: String,
        rate: Double,
        unit: String?,
        quantity: Int,
        metadata: [String: String]? = nil,
        sourceType: String
    ) async throws -> CartItemRecord {

        let uid = try await (userId == nil || userId?.trimmingCharacters(in: .whitespacesAndNewlines) == "") ?
            ensureUserId() : userId!

        let payload = CartInsert(
            userId: uid,
            eventId: eventId,
            serviceId: serviceId,
            serviceName: serviceName,
            subserviceId: subserviceId,
            subserviceName: subserviceName,
            rate: rate,
            unit: unit,
            quantity: quantity,
            metadata: metadata,
            sourceType: sourceType
        )

        let response = try await client
            .from("cart_items")
            .insert(payload)
            .select()
            .execute()

        if let raw = String(data: response.data, encoding: .utf8) {
            print("insertCartItem raw:", raw) // helpful to debug missing fields
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([CartItemRecord].self, from: response.data).first!
    }

    func updateCartItemQuantity(cartItemId: String, quantity: Int) async throws -> CartItemRecord {
        let payload = QuantityUpdate(quantity: quantity)
        let response = try await client
            .from("cart_items")
            .update(payload)
            .eq("id", value: cartItemId)
            .select("*")
            .execute()

        if let raw = String(data: response.data, encoding: .utf8) {
            print("updateCartItemQuantity raw:", raw)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([CartItemRecord].self, from: response.data).first!
    }

    func deleteCartItem(cartItemId: String) async throws {
        let response = try await client
            .from("cart_items")
            .delete()
            .eq("id", value: cartItemId)
            .execute()

        if let raw = String(data: response.data, encoding: .utf8) {
            print("deleteCartItem raw:", raw)
        }
    }
}

