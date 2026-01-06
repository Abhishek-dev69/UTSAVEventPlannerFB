//
// SupabaseManager.swift
// UTSAV
//
// Corrected for supabase-swift v2.37.0
//

import Foundation
import Supabase
import AuthenticationServices

// NOTE: This file assumes you have the following app models defined in Service.swift:
// - ServiceCreatePayload
// - ServiceRecord
// - Subservice
// - SubserviceRecord
// (Do NOT redeclare them here; keep only one definition in Service.swift). :contentReference[oaicite:2]{index=2}

// MARK: - Small helper payloads used for inserts (Encodable)
private struct ServiceInsertPayload: Encodable {
    let name: String
    let user_id: String
}

private struct SubserviceInsertPayload: Encodable {
    let service_id: String
    let name: String
    let rate: Double
    let unit: String
    let image_url: String?
    let is_fixed: Bool
    let user_id: String
}

// Minimal Cart models kept local (you already have these in your codebase; keep if needed)
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
    let cartSessionId: String?
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

// MARK: - Auth errors
enum AuthError: LocalizedError {
    case notSignedIn
    case sdk(String)
    case http(Int, String)
    case noUser

    var errorDescription: String? {
        switch self {
        case .notSignedIn: return "User is not signed in."
        case .sdk(let s): return s
        case .http(let c, let m): return "HTTP \(c): \(m)"
        case .noUser: return "No user/session returned from auth."
        }
    }
}

// MARK: - SupabaseManager
final class SupabaseManager {
    static let shared = SupabaseManager()
    let client: SupabaseClient
    let supabaseBaseURL: URL
    private let supabaseKey: String

    private init() {
        let base = URL(string: "https://denikpjyrblzbomzamyu.supabase.co")!
        self.supabaseBaseURL = base

        // Use only anon/public key in client apps (don't embed service_role).
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRlbmlrcGp5cmJsemJvbXphbXl1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMwNTExMzIsImV4cCI6MjA3ODYyNzEzMn0.k6kqcjIu-G0_YV9H1VjHfWaPahvl1RhMo9gBODYqUbo"
        self.supabaseKey = supabaseKey

        self.client = SupabaseClient(supabaseURL: base, supabaseKey: supabaseKey)
        NSLog("SupabaseManager initialized with base: %@", base.absoluteString)
    }

    // MARK: - User id helpers
    /// Returns the current signed-in user's id (UUID string) or throws if not signed in.
    func ensureUserId() async throws -> String {
        if let user = client.auth.currentUser {
            let uid = user.id.uuidString
            NSLog("ensureUserId -> returning currentUser id: %@", uid)
            return uid
        }

        NSLog("ensureUserId -> no signed-in user found")
        throw AuthError.notSignedIn
    }
    
    // MARK: - Session check (IMPORTANT)
    func isLoggedIn() -> Bool {
        return client.auth.currentUser != nil
    }

    func getCurrentUserId() async -> String? {
        return client.auth.currentUser?.id.uuidString
    }

    func currentUserIdSync() -> String? {
        return client.auth.currentUser?.id.uuidString
    }

    // MARK: - Auth (email/password + reset)
    func signUp(email: String, password: String, fullName: String? = nil) async throws -> String {
        do {
            try await client.auth.signUp(email: email, password: password)
            if let user = client.auth.currentUser {
                let uid = user.id.uuidString
                NSLog("signUp -> created user id: %@", uid)
                if let name = fullName, !name.isEmpty {
                    Task.detached { @MainActor in
                        // optional profile creation - do not block signup
                    }
                }
                return uid
            }
            throw AuthError.noUser
        } catch {
            NSLog("signUp failed: %@", String(describing: error))
            throw error
        }
    }

    func signIn(email: String, password: String) async throws -> String {
        do {
            try await client.auth.signIn(email: email, password: password)
            if let user = client.auth.currentUser {
                let uid = user.id.uuidString
                NSLog("signIn -> success user id: %@", uid)
                return uid
            }
            throw AuthError.noUser
        } catch {
            NSLog("signIn failed: %@", String(describing: error))
            throw error
        }
    }

    func signOutAuth() async throws {
        do {
            try await client.auth.signOut()
            NSLog("signOut -> success")
        } catch {
            NSLog("signOut failed: %@", String(describing: error))
            throw error
        }
    }

    func sendPasswordResetEmail(email: String, redirectTo: String? = nil) async throws {
        let url = supabaseBaseURL.appendingPathComponent("/auth/v1/recover")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")

        var body: [String: Any] = ["email": email]
        if let r = redirectTo { body["redirect_to"] = r }
        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.sdk("Invalid response")
        }
        guard (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "no message"
            throw AuthError.http(http.statusCode, msg)
        }
        NSLog("sendPasswordResetEmail -> request accepted for %@", email)
    }

    // MARK: - OAuth helpers
    func getOAuthSignInURL(providerName: String) throws -> URL {
        var components = URLComponents(url: supabaseBaseURL.appendingPathComponent("/auth/v1/authorize"),
                                       resolvingAgainstBaseURL: false)

        let hostedCallback = supabaseBaseURL.appendingPathComponent("/auth/v1/callback").absoluteString

        components?.queryItems = [
            URLQueryItem(name: "provider", value: providerName),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "flow_type", value: "pkce"),
            URLQueryItem(name: "scope", value: "openid email profile"),
            URLQueryItem(name: "prompt", value: "consent"),
            URLQueryItem(name: "redirect_to", value: hostedCallback)
        ]

        guard let url = components?.url else { throw NSError(domain: "SupabaseManager", code: -1, userInfo: nil) }
        return url
    }

    func handleAuthCallback(_ callbackURL: URL) async throws {
        NSLog("SupabaseManager.handleAuthCallback - incoming raw URL: %@", callbackURL.absoluteString)
        let finalURL = convertFragmentToQueryIfNeeded(callbackURL)
        NSLog("SupabaseManager.handleAuthCallback - final URL passed to SDK: %@", finalURL.absoluteString)

        let session = try await client.auth.session(from: finalURL)
        NSLog("Session created from callback - user id: %@", session.user.id.uuidString)
        try? await Task.sleep(nanoseconds: 200_000_000)
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

    // MARK: - Database helpers (Service/Subservice/Cart)
    /// Create service owned by current user and optional subservices owned by same user.
    func createService(_ payload: ServiceCreatePayload) async throws -> ServiceRecord {
        // Ensure we have a signed-in user id to set as owner
        let uid = try await ensureUserId()

        // Insert service with owner user_id using an Encodable struct
        let serviceInsert = ServiceInsertPayload(name: payload.name, user_id: uid)

        let response = try await client
            .from("services")
            .insert(serviceInsert)
            .select("*")
            .execute()

        if let raw = String(data: response.data, encoding: .utf8) {
            NSLog("createService - raw: %@", raw)
        }

        let createdServices = try JSONDecoder().decode([ServiceRecord].self, from: response.data)
        guard let created = createdServices.first else {
            throw NSError(domain: "SupabaseCreateService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service insert returned no rows"])
        }

        // Bulk-insert subservices with owner user_id (use Encodable payload structs)
        if !payload.subservices.isEmpty {
            let subPayloads: [SubserviceInsertPayload] = payload.subservices.map {
                SubserviceInsertPayload(
                    service_id: created.id,
                    name: $0.name,
                    rate: $0.rate,
                    unit: $0.unit,
                    image_url: nil, // adapt if you store images
                    is_fixed: $0.isFixed,
                    user_id: uid
                )
            }
            _ = try await client.from("subservices").insert(subPayloads).select("*").execute()
        }

        return created
    }

    /// Fetch only services that belong to the signed-in user.
    func fetchServices() async throws -> [ServiceRecord] {
        let uid = try await ensureUserId()

        let response = try await client
            .from("services")
            .select("""
                id, name, created_at,
                subservices(id, service_id, name, rate, unit, image_url, is_fixed, user_id)
            """)
            .eq("user_id", value: uid)
            .execute()

        if let raw = String(data: response.data, encoding: .utf8) {
            NSLog("fetchServices raw: %@", raw)
        }
        return try JSONDecoder().decode([ServiceRecord].self, from: response.data)
    }

    /// Add a subservice and set current user as its owner (user_id).
    func addSubservice(serviceId: String, sub: Subservice) async throws {
        let uid = try await ensureUserId()
        let payload = SubserviceInsertPayload(
            service_id: serviceId,
            name: sub.name,
            rate: sub.rate,
            unit: sub.unit,
            image_url: nil,
            is_fixed: sub.isFixed,
            user_id: uid
        )
        _ = try await client.from("subservices").insert(payload).select("*").execute()
    }

    func updateSubservice(subId: String, updated: Subservice) async throws {
        // Use a small struct to update
        struct UpdatePayload: Encodable {
            let name: String
            let rate: Double
            let unit: String
            let image_url: String?
            let is_fixed: Bool
        }
        let payload = UpdatePayload(name: updated.name, rate: updated.rate, unit: updated.unit, image_url: nil, is_fixed: updated.isFixed)
        _ = try await client.from("subservices").update(payload).eq("id", value: subId).select("*").execute()
    }

    func deleteSubservice(subId: String) async throws {
        _ = try await client.from("subservices").delete().eq("id", value: subId).execute()
    }

    // MARK: - Cart Operations
    func fetchCartItems(
        userId: String? = nil,
        eventId: String? = nil,
        cartSessionId: String? = nil
    ) async throws -> [CartItemRecord] {

        let uid = try await (userId == nil || userId!.isEmpty)
            ? ensureUserId()
            : userId!

        var query = client
            .from("cart_items")
            .select("*")
            .eq("user_id", value: uid)

        if let eId = eventId, !eId.isEmpty {
            query = query.eq("event_id", value: eId)
        }

        if let sId = cartSessionId {
            query = query.eq("cart_session_id", value: sId)
        }

        let response = try await query.execute()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([CartItemRecord].self, from: response.data)
    }


    func insertCartItem(
        userId: String?,
        eventId: String?,
        cartSessionId: String?,   // ✅ ADD
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

        let uid = try await (userId == nil || userId!.isEmpty)
            ? ensureUserId()
            : userId!

        let payload = CartInsert(
            userId: uid,
            eventId: eventId,
            cartSessionId: cartSessionId,   // ✅
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

