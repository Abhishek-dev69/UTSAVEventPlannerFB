//
// EventSupabaseManager.swift
// FINAL FIXED VERSION FOR SUPABASE SWIFT v2.x
//

import Foundation
import Supabase

// MARK: - Insert Payload (Encodable → matches SQL)
struct EventInsert: Encodable {
    let user_id: String
    let event_name: String
    let client_name: String
    let location: String
    let guest_count: Int
    let budget_in_paise: Int64
    let start_date: String       // yyyy-mm-dd
    let end_date: String
    let metadata: [String: String]?
}

// MARK: - Returned Row From Database (Codable)
struct EventRecord: Codable {
    let id: String
    let userId: String
    let eventName: String
    let clientName: String
    let location: String
    let guestCount: Int
    let budgetInPaise: Int64
    let startDate: String
    let endDate: String
    let metadata: [String: String]?
    let createdAt: String?
    let updatedAt: String?
    let status: String?
}

// MARK: - MAIN MANAGER
final class EventSupabaseManager {
    
    static let shared = EventSupabaseManager()
    
    private let client = SupabaseManager.shared.client

    private init() {}
    // MARK: - Ensure User Session & Return User ID
    func ensureUserId() async throws -> String {
        
        // 1. Try existing session
        if let existing = try? await client.auth.session {
            return existing.user.id.uuidString
        }
        
        // 2. Otherwise login anonymously
        _ = try await client.auth.signInAnonymously()
        
        // 3. Read session again
        let session = try await client.auth.session
        return session.user.id.uuidString
    }
    
    // MARK: - INSERT EVENT
    /// Insert an event.
    /// - Parameters:
    ///   - details: EventDetails (your existing struct that holds event fields)
    ///   - metadata: optional metadata dictionary (use this to pass eventTypeImage / eventTypeTitle etc)
    /// - Returns: inserted EventRecord
    func insertEvent(details: EventDetails, metadata: [String: String]? = nil) async throws -> EventRecord {
        
        let uid = try await ensureUserId()
        
        // Convert Date → YYYY-MM-DD
        let start = isoDate(details.startDate)
        let end = isoDate(details.endDate)
        
        // Build object for Supabase. If caller provided metadata use it, otherwise insert empty dictionary.
        let insertObject = EventInsert(
            user_id: uid,
            event_name: details.eventName,
            client_name: details.clientName,
            location: details.location,
            guest_count: details.guestCount,
            budget_in_paise: Int64(details.budgetInPaise),
            start_date: start,
            end_date: end,
            metadata: metadata ?? [:]
        )
        
        // Insert into Supabase
        let response = try await client
            .from("events")
            .insert(insertObject)
            .select()
            .single()
            .execute()
        
        let data = response.data
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let record = try decoder.decode(EventRecord.self, from: data)
        
        if let raw = String(data: data, encoding: .utf8) {
            print("Inserted Event →", raw)
        }
        
        return record
    }
    
    func fetchCartSessionId(eventId: String) async throws -> String {

        let result = try await client
            .from("cart_items")
            .select("cart_session_id")
            .eq("event_id", value: eventId)
            .limit(1)
            .execute()

        struct Row: Decodable {
            let cart_session_id: String?   // ✅ MUST BE OPTIONAL
        }

        let rows = try JSONDecoder().decode([Row].self, from: result.data)

        // ✅ If null or not found → generate new session id
        if let sessionId = rows.first?.cart_session_id,
           !sessionId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return sessionId
        }

        let newId = UUID().uuidString
        print("🆕 Generated new cart_session_id:", newId)
        return newId
    }
    func loadCartItems(eventId: String) async throws {

        let result = try await client
            .from("cart_items")
            .select("*")
            .eq("event_id", value: eventId)
            .execute()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let items = try decoder.decode([CartItem].self, from: result.data)

        await MainActor.run {
            CartManager.shared.setItems(items)
        }

        print("✅ Draft cart loaded items:", items.count)
    }



    // MARK: - Fetch All Events for User
    // MARK: - Fetch All Events for User (Used in Payments + Inventory)
    func fetchUserEvents(userId: String) async throws -> [EventRecord] {

        let response = try await client
            .from("events")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode([EventRecord].self, from: response.data)
    }
    
    // MARK: - FETCH EVENT BY ID
    func fetchEvent(id: String) async throws -> EventRecord {
        
        let response = try await client
            .from("events")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
        
        let data = response.data
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode(EventRecord.self, from: data)
    }
    
    // MARK: - Helper
    private func isoDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone.current  // use local timezone (IST)
        return f.string(from: date)
    }

    // --------------------------------------------------------------------
    // --------------------------------------------------------------------
    // 🔥 NEW — FETCH ALL EVENTS FOR HOME SCREEN
    // --------------------------------------------------------------------
    func fetchAllEventsForUser() async throws -> [EventRecord] {
        
        let uid = try await ensureUserId()
        
        let response = try await client
            .from("events")
            .select()
            .eq("user_id", value: uid)
            .order("created_at", ascending: false)
            .execute()
        
        let data = response.data
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode([EventRecord].self, from: data)
    }
    
    // --------------------------------------------------------------------
    // --------------------------------------------------------------------
    // 🔥 NEW — LINK CART ITEMS → EVENT (Confirm Order)
    // --------------------------------------------------------------------
    // MARK: - Link cart items created recently (to avoid touching old rows)
    func linkCartItemsToEvent(eventId: String,cartSessionId: String) async throws {
        
        // Defensive: validate eventId
        let trimmed = eventId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, UUID(uuidString: trimmed) != nil else {
            throw NSError(
                domain: "EventSupabaseManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid event id"]
            )
        }
        
        let uid = try await ensureUserId()
        
        // We'll only link items that:
        //  - belong to this user
        //  - currently have no event_id (unlinked)
        //  - were created recently (within the last 1 hour) — this avoids accidentally linking old rows from previous events
        //
        // NOTE: This is a pragmatic safety improvement. For a fully robust solution
        // add a cart_session_id to inserted cart rows and filter by that session id.
        
        // Compute cutoff timestamp (ISO8601) — 1 hour ago
        let cutoffDate = Date().addingTimeInterval(-60 * 60) // 1 hour
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let cutoff = isoFormatter.string(from: cutoffDate)
        
        // 1) fetch candidate rows: user_id == uid, event_id IS NULL, created_at >= cutoff
        struct IdAndEventRow: Codable {
            let id: String
            let event_id: String?
            let created_at: String?
        }
        
        let fetchResp = try await client
            .from("cart_items")
            .select("id, event_id, created_at")
            .eq("user_id", value: uid)
            .is("event_id", value: nil)        // require event_id IS NULL
            .gte("created_at", value: cutoff) // only recent rows
            .execute()
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let candidateRows = try decoder.decode([IdAndEventRow].self, from: fetchResp.data)
        
        // 2) Build ids to update (if any)
        let idsToUpdate = candidateRows.map { $0.id }
        
        guard !idsToUpdate.isEmpty else {
            print("No recent unlinked cart items to link for user:", uid)
            return
        }
        
        // 3) update those rows with event_id = trimmed
        struct UpdateEventId: Encodable {
            let event_id: String
        }
        let updateBody = UpdateEventId(event_id: trimmed)
        
        let updResp = try await client
            .from("cart_items")
            .update(updateBody)
            .`in`("id", values: idsToUpdate)
            .select("id,event_id")
            .execute()
        
        if let raw = String(data: updResp.data, encoding: .utf8) {
            print("linkCartItemsToEvent update response:", raw)
        }
        
        print("Linked \(idsToUpdate.count) recent cart items to event:", trimmed)
    }
    
    // --------------------------------------------------------------------
    // 🔥 NEW — MARK EVENT AS SERVICES ADDED (REQUIRED FOR DASHBOARD LOGIC)
    // --------------------------------------------------------------------
    func markServicesAdded(eventId: String) async throws {

        // Fetch existing event to avoid overwriting metadata
        let event = try await fetchEvent(id: eventId)

        var updatedMetadata = event.metadata ?? [:]
        updatedMetadata["servicesAdded"] = "true"

        struct MetadataUpdate: Encodable {
            let metadata: [String: String]
        }

        try await client
            .from("events")
            .update(MetadataUpdate(metadata: updatedMetadata))
            .eq("id", value: eventId)
            .execute()

        print("✅ Event \(eventId) marked as servicesAdded = true")
    }
    
    // MARK: - DELETE EVENT
    func deleteEvent(eventId: String) async throws {

        let trimmed = eventId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard UUID(uuidString: trimmed) != nil else {
            throw NSError(
                domain: "EventSupabaseManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid event id"]
            )
        }

        try await client
            .from("events")
            .delete()
            .eq("id", value: trimmed)
            .execute()

        print("🗑️ Deleted event:", trimmed)
    }


    
}

