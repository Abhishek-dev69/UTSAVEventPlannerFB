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
}

// MARK: - MAIN MANAGER
final class EventSupabaseManager {
    
    static let shared = EventSupabaseManager()
    
    private let client: SupabaseClient
    
    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string:"https://denikpjyrblzbomzamyu.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRlbmlrcGp5cmJsemJvbXphbXl1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMwNTExMzIsImV4cCI6MjA3ODYyNzEzMn0.k6kqcjIu-G0_YV9H1VjHfWaPahvl1RhMo9gBODYqUbo"
        )
    }
    
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
    func insertEvent(details: EventDetails) async throws -> EventRecord {
        
        let uid = try await ensureUserId()
        
        // Convert Date → YYYY-MM-DD
        let start = isoDate(details.startDate)
        let end = isoDate(details.endDate)
        
        // Build object for Supabase
        let insertObject = EventInsert(
            user_id: uid,
            event_name: details.eventName,
            client_name: details.clientName,
            location: details.location,
            guest_count: details.guestCount,
            budget_in_paise: Int64(details.budgetInPaise),
            start_date: start,
            end_date: end,
            metadata: [:]
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
        
        print("Inserted Event →", String(data: data, encoding: .utf8) ?? "<json>")
        
        return record
    }
    // MARK: - Fetch All Events for User
    func fetchUserEvents(userId: String) async throws -> [EventRecord] {
        
        let response = try await client
            .from("events")
            .select("*")
            .eq("user_id", value: userId)
            .order("start_date", ascending: true)
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
        f.timeZone = .init(abbreviation: "UTC")
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
    // MARK: - Link all cart items to this event
    // MARK: - Link all cart items to this event
    func linkCartItemsToEvent(eventId: String) async throws {
        
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
        
        // 1) fetch user's cart item ids and event_id values
        struct IdAndEvent: Codable {
            let id: String
            let event_id: String?
        }
        
        let fetchResp = try await client
            .from("cart_items")
            .select("id, event_id")
            .eq("user_id", value: uid)
            .execute()
        
        // decode rows
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let allRows = try decoder.decode([IdAndEvent].self, from: fetchResp.data)
        
        // 2) select rows that are not yet linked (event_id == nil or empty)
        let idsToUpdate = allRows
            .filter { ($0.event_id ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { $0.id }
        
        guard !idsToUpdate.isEmpty else {
            print("No cart items to link for user:", uid)
            return
        }
        
        // 3) update only those ids
        struct UpdateEventId: Encodable {
            let event_id: String
        }
        let updateBody = UpdateEventId(event_id: trimmed)
        
        // if SDK signature is .in(_ column: String, values: [Any])
        let updResp = try await client
            .from("cart_items")
            .update(updateBody)
            .`in`("id", values: idsToUpdate)    // backticks escape the name `in`
            .select("id,event_id")
            .execute()
        if let raw = String(data: updResp.data, encoding: .utf8) {
            print("linkCartItemsToEvent update response:", raw)
        }
        
        print("Linked \(idsToUpdate.count) cart items to event:", trimmed)
    }
    
}
