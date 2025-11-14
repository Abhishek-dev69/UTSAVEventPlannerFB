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

struct CartItemRecord: Codable {
    let id: String
    let user_id: String
    let event_id: String?
    let service_id: String?
    let service_name: String
    let subservice_id: String
    let subservice_name: String
    let rate: Double
    let unit: String?
    let quantity: Int
    let line_total: Double?
    let metadata: [String: String]?
    let created_at: String?
    let updated_at: String?
}

struct CartInsert: Codable {
    let user_id: String
    let event_id: String?
    let service_id: String?
    let service_name: String
    let subservice_id: String
    let subservice_name: String
    let rate: Double
    let unit: String?
    let quantity: Int
    let metadata: [String: String]?
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
        // Some SDKs expose session as property or async; handle defensively
        do {
            // Try reading session (non-throwing path depending on SDK)
            let maybeSession = try? await client.auth.session
            if let s = maybeSession {
                return s.user.id.uuidString
            }
        } catch {
            // ignore: will attempt sign-in
            print("ensureUserId: session read threw:", error)
        }

        // If no session, try anonymous sign in
        do {
            try await client.auth.signInAnonymously()
            if let session = try? await client.auth.session {
                return session.user.id.uuidString
            } else {
                throw NSError(domain: "SupabaseAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sign-in succeeded but session missing"])
            }
        } catch {
            print("ensureUserId: anonymous sign-in failed:", error)
            throw error
        }
    }

    // MARK: - Services & Subservices

    /// Creates a service record and all provided subservices in DB.
    /// Returns the created ServiceRecord for the service row.
    func createService(_ payload: ServiceCreatePayload) async throws -> ServiceRecord {
        // 1) Insert service
        let response = try await client
            .from("services")
            .insert(["name": payload.name])
            .select("*")
            .execute()

        // debug
        if let raw = String(data: response.data, encoding: .utf8) {
            print("createService - service insert raw:", raw)
        }

        let createdServices = try JSONDecoder().decode([ServiceRecord].self, from: response.data)
        guard let created = createdServices.first else {
            throw NSError(domain: "SupabaseCreateService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service insert returned no rows"])
        }

        // 2) Insert subservices in bulk (if any)
        if !payload.subservices.isEmpty {
            // Map to Encodable payloads for Supabase insert
            let subPayloads: [SubserviceInsert] = payload.subservices.map { s in
                SubserviceInsert(
                    service_id: created.id,
                    name: s.name,
                    rate: s.rate,
                    unit: s.unit,
                    image_url: nil // if you want to support images, update later to upload and set URL
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
            // we don't strictly need to decode here; debug output is helpful
        }

        return created
    }

    /// Fetch services with their subservices relationship
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

    func fetchCartItems() async throws -> [CartItemRecord] {
        let uid = try await ensureUserId()

        let response = try await client
            .from("cart_items")
            .select("*")
            .eq("user_id", value: uid)
            .execute()

        if let raw = String(data: response.data, encoding: .utf8) {
            print("fetchCartItems raw:", raw)
        }

        return try JSONDecoder().decode([CartItemRecord].self, from: response.data)
    }

    func insertCartItem(
        userId: String,
        serviceId: String?,
        serviceName: String,
        subserviceId: String,
        subserviceName: String,
        rate: Double,
        unit: String?,
        quantity: Int,
        metadata: [String: String]? = nil
    ) async throws -> CartItemRecord {

        let payload = CartInsert(
            user_id: userId,
            event_id: nil,
            service_id: serviceId,
            service_name: serviceName,
            subservice_id: subserviceId,
            subservice_name: subserviceName,
            rate: rate,
            unit: unit,
            quantity: quantity,
            metadata: metadata
        )

        let response = try await client
            .from("cart_items")
            .insert(payload)
            .select("*")
            .execute()

        if let raw = String(data: response.data, encoding: .utf8) {
            print("insertCartItem raw:", raw)
        }

        // defensive decode
        do {
            let inserted = try JSONDecoder().decode([CartItemRecord].self, from: response.data)
            if let first = inserted.first {
                return first
            } else {
                throw NSError(domain: "SupabaseInsert", code: -1, userInfo: [NSLocalizedDescriptionKey: "Insert returned no rows"])
            }
        } catch {
            print("insertCartItem decode error:", error)
            print("insertCartItem raw data:", String(data: response.data, encoding: .utf8) ?? "<binary>")
            throw error
        }
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

        return try JSONDecoder().decode([CartItemRecord].self, from: response.data).first!
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

