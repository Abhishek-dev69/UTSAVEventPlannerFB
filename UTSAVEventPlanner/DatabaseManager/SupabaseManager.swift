//
// SupabaseManager.swift
// UTSAV
//
// Updated SupabaseManager with robust OAuth callback handling.
// Converts callback fragments (utsav://callback#access_token=...) to query form
// so the Supabase SDK session(from:) can parse them.
//

import Foundation
import Supabase
import AuthenticationServices

// MARK: - Codable Models (these are kept minimal here; your real models should be defined in your project)
struct ServiceInsert: Codable { let name: String }

struct SubserviceInsert: Codable {
    let service_id: String
    let name: String
    let rate: Double
    let unit: String
    let image_url: String?
    let is_fixed: Bool        // NEW
}

struct SubserviceUpdate: Encodable {
    let name: String
    let rate: Double
    let unit: String
    let image_url: String?
    let is_fixed: Bool        // NEW
}
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

private struct QuantityUpdate: Codable { let quantity: Int }

// MARK: - SupabaseManager
final class SupabaseManager {
    static let shared = SupabaseManager()
    let client: SupabaseClient
    let supabaseBaseURL: URL

    private init() {
        // your project base url
        let base = URL(string: "https://denikpjyrblzbomzamyu.supabase.co")!
        self.supabaseBaseURL = base

        // your anon/public key (dev). Keep secure in production!
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRlbmlrcGp5cmJsemJvbXphbXl1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMwNTExMzIsImV4cCI6MjA3ODYyNzEzMn0.k6kqcjIu-G0_YV9H1VjHfWaPahvl1RhMo9gBODYqUbo"
        self.client = SupabaseClient(
            supabaseURL: base,
            supabaseKey: supabaseKey
        )
        NSLog("SupabaseManager initialized with base: %@", base.absoluteString)
    }

    // MARK: - User id helpers
    func ensureUserId() async throws -> String {
        let session = try await client.auth.session
        let uidString = String(describing: session.user.id)
        if !uidString.isEmpty {
            NSLog("ensureUserId -> returning session user id: %@", uidString)
            return uidString
        }
        NSLog("ensureUserId -> no session user id, returning fallback dev id")
        return "2b7e9f1d-4e2f-4a2f-9c11-9f7ea6b8a2f2"
    }

    func getCurrentUserId() async -> String? {
        guard let session = try? await client.auth.session else { return nil }
        let idString = String(describing: session.user.id)
        return idString.isEmpty ? nil : idString
    }

    // MARK: - OAuth URL builder
    /// Build authorize URL. Important: to force PKCE code flow we pass the *hosted*
    /// supabase callback as redirect_to. That prevents implicit-token fragments.
    func getOAuthSignInURL(providerName: String) throws -> URL {
        var components = URLComponents(url: supabaseBaseURL.appendingPathComponent("/auth/v1/authorize"),
                                       resolvingAgainstBaseURL: false)

        let hostedCallback = supabaseBaseURL.appendingPathComponent("/auth/v1/callback").absoluteString

        components?.queryItems = [
            URLQueryItem(name: "provider", value: providerName),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "flow_type", value: "pkce"),
            URLQueryItem(name: "redirect_to", value: hostedCallback)
        ]

        guard let url = components?.url else { throw NSError(domain: "SupabaseManager", code: -1, userInfo: nil) }
        return url
    }

    // MARK: - Handle callback
    /// Converts fragment (#...) to query (?...) so the SDK can parse token/code.
    func handleAuthCallback(_ callbackURL: URL) async throws {
        NSLog("SupabaseManager.handleAuthCallback - incoming raw URL: %@", callbackURL.absoluteString)
        let finalURL = convertFragmentToQueryIfNeeded(callbackURL)
        NSLog("SupabaseManager.handleAuthCallback - final URL passed to SDK: %@", finalURL.absoluteString)

        do {
            let session = try await client.auth.session(from: finalURL)
            NSLog("✅ Session created successfully from callback - User ID: %@", String(describing: session.user.id))
            
            try await Task.sleep(nanoseconds: 500_000_000)
            
            if let savedSession = try? await client.auth.session {
                NSLog("✅ Session verified and saved in client")
            } else {
                NSLog("⚠️ Could not verify saved session, but session(from:) succeeded")
            }
        } catch {
            NSLog("❌ Failed to create session from callback: %@", String(describing: error))
            throw error
        }
    }
    private func convertFragmentToQueryIfNeeded(_ url: URL) -> URL {
        guard let fragment = url.fragment, !fragment.isEmpty else { return url }
        guard var comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
        comps.fragment = nil
        if let existingQuery = comps.query, !existingQuery.isEmpty {
            comps.query = existingQuery + "&" + fragment
        } else {
            comps.query = fragment
        }
        if let newURL = comps.url { return newURL }
        var absolute = url.absoluteString
        if let hashRange = absolute.range(of: "#") {
            absolute.replaceSubrange(hashRange, with: "?")
        }
        return URL(string: absolute) ?? url
    }

    // MARK: - Services & Subservices (your DB helpers)
    // NOTE: These refer to types (ServiceCreatePayload, ServiceRecord, Subservice) which are assumed
    // to exist elsewhere in your project. If not, replace with your project types or simple DTOs.

    func createService(_ payload: ServiceCreatePayload) async throws -> ServiceRecord {
        let response = try await client
            .from("services")
            .insert(["name": payload.name])
            .select("*")
            .execute()

        if let raw = String(data: response.data, encoding: .utf8) {
            NSLog("createService - service insert raw: %@", raw)
        }

        let createdServices = try JSONDecoder().decode([ServiceRecord].self, from: response.data)
        guard let created = createdServices.first else {
            throw NSError(domain: "SupabaseCreateService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service insert returned no rows"])
        }

        if !payload.subservices.isEmpty {
            let subPayloads: [SubserviceInsert] = payload.subservices.map {
                SubserviceInsert(
                    service_id: created.id,
                    name: $0.name,
                    rate: $0.rate,
                    unit: $0.unit,
                    image_url: nil,
                    is_fixed: $0.isFixed
                )
            }
            _ = try await client.from("subservices").insert(subPayloads).select("*").execute()
        }

        return created
    }

    func fetchServices() async throws -> [ServiceRecord] {
        let response = try await client
            .from("services")
            .select("""
                id, name, created_at,
                subservices(id, service_id, name, rate, unit, image_url, is_fixed)
            """)
            .execute()

        if let raw = String(data: response.data, encoding: .utf8) {
            NSLog("fetchServices raw: %@", raw)
        }
        return try JSONDecoder().decode([ServiceRecord].self, from: response.data)
    }

    func addSubservice(serviceId: String, sub: Subservice) async throws {
        let payload = SubserviceInsert(
            service_id: serviceId,
            name: sub.name,
            rate: sub.rate,
            unit: sub.unit,
            image_url: nil,
            is_fixed: sub.isFixed
        )
        _ = try await client.from("subservices").insert(payload).select("*").execute()
    }

    func updateSubservice(subId: String, updated: Subservice) async throws {
        let payload = SubserviceUpdate(
            name: updated.name,
            rate: updated.rate,
            unit: updated.unit,
            image_url: nil,
            is_fixed: updated.isFixed
        )
        _ = try await client.from("subservices").update(payload).eq("id", value: subId).select("*").execute()
    }

    func deleteSubservice(subId: String) async throws {
        _ = try await client.from("subservices").delete().eq("id", value: subId).execute()
    }

    // MARK: - Cart Operations (unchanged)
    func fetchCartItems(userId: String? = nil, eventId: String? = nil) async throws -> [CartItemRecord] {
        let uid = try await (userId == nil || userId!.isEmpty) ? ensureUserId() : userId!
        var query = client.from("cart_items").select("*").eq("user_id", value: uid)
        if let eId = eventId, !eId.isEmpty { query = query.eq("event_id", value: eId) }
        let response = try await query.execute()
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([CartItemRecord].self, from: response.data)
    }

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

        let uid = try await (userId == nil || userId!.isEmpty) ? ensureUserId() : userId!
        let payload = CartInsert(userId: uid, eventId: eventId, serviceId: serviceId, serviceName: serviceName, subserviceId: subserviceId, subserviceName: subserviceName, rate: rate, unit: unit, quantity: quantity, metadata: metadata, sourceType: sourceType)
        let response = try await client.from("cart_items").insert(payload).select().execute()
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([CartItemRecord].self, from: response.data).first!
    }

    func updateCartItemQuantity(cartItemId: String, quantity: Int) async throws -> CartItemRecord {
        let payload = QuantityUpdate(quantity: quantity)
        let response = try await client.from("cart_items").update(payload).eq("id", value: cartItemId).select("*").execute()
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([CartItemRecord].self, from: response.data).first!
    }

    func deleteCartItem(cartItemId: String) async throws {
        _ = try await client.from("cart_items").delete().eq("id", value: cartItemId).execute()
    }
}

