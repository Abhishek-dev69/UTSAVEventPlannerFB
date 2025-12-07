//
//  InventoryDataManager.swift
//
//  Inventory-only safe reflection + URLSession RPC fallback.
//  Added: fetchLostPostEventRows(eventId:) to fetch lost/damaged post-event rows from DB.
//

import Foundation
import Supabase

// -----------------------------
// Models
// -----------------------------
struct InventoryItemRecord: Codable {
    let id: String
    let eventId: String
    let name: String
    let quantity: Int
    let unit: String?
    let used: Int?
    let sourceType: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case name
        case quantity
        case unit
        case used
        case sourceType = "source_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct InventoryInsert: Encodable {
    let event_id: String
    let name: String
    let quantity: Int
    let unit: String?
    let source_type: String
}

struct InventoryUsedUpdate: Encodable {
    let used: Int
}

// PostEventRow maps the shape we use in UI (matches vw_postevent_pending where possible)
struct PostEventRow: Codable {
    let posteventId: String
    let inventoryItemId: String
    let eventId: String
    var postQty: Int                // mutable so UI can decrement
    let state: String
    let note: String?
    let name: String
    let inventoryQuantity: Int?
    let unit: String?
    let sourceType: String?
    let postCreatedAt: String?

    enum CodingKeys: String, CodingKey {
        case posteventId = "postevent_id"
        case inventoryItemId = "inventory_item_id"
        case eventId = "event_id"
        case postQty = "post_qty"
        case state
        case note
        case name
        case inventoryQuantity = "inventory_quantity"
        case unit
        case sourceType = "source_type"
        case postCreatedAt = "post_created_at"
    }
}

struct PostEventInsert: Encodable {
    let inventory_item_id: String
    let event_id: String
    let quantity: Int
    let state: String
}

// -----------------------------
// InventoryDataManager
// -----------------------------
final class InventoryDataManager {

    static let shared = InventoryDataManager()
    private init() {}

    private var client: SupabaseClient { SupabaseManager.shared.client }

    // MARK: — discover base URL and anon key safely from SupabaseManager / client using Mirror
    private var baseURLString: String {
        // 1) Try looking up common properties on SupabaseManager.shared via Mirror
        let managerMirror = Mirror(reflecting: SupabaseManager.shared)
        let candidateNames = ["supabaseBaseURL", "supabaseURL", "supabaseUrl", "url", "baseURL", "baseUrl", "projectUrl"]
        for child in managerMirror.children {
            if let label = child.label, candidateNames.contains(label) {
                if let url = child.value as? URL { return url.absoluteString }
                if let s = child.value as? String { return s }
            }
        }

        // 2) Try to find in the client object by Mirror (avoid KVC)
        let clientMirror = Mirror(reflecting: client)
        let clientNameCandidates = ["supabaseBaseURL", "supabaseURL", "baseURL", "baseUrl", "url"]
        for child in clientMirror.children {
            if let label = child.label, clientNameCandidates.contains(label) {
                if let url = child.value as? URL { return url.absoluteString }
                if let s = child.value as? String { return s }
            }
        }

        // 3) Fallback hard-coded placeholder (replace with your project's URL if desired)
        return "https://denikpjyrblzbomzamyu.supabase.co"
    }

    private var anonKey: String {
        // 1) Try common properties from SupabaseManager.shared via Mirror
        let managerMirror = Mirror(reflecting: SupabaseManager.shared)
        let keyNames = ["supabaseKey", "supabase_key", "anonKey", "anon_key", "anon", "apiKey", "serviceKey"]
        for child in managerMirror.children {
            if let label = child.label, keyNames.contains(label) {
                if let s = child.value as? String, !s.isEmpty { return s }
            }
        }

        // 2) Try to find in the client object's mirror (avoid KVC)
        let clientMirror = Mirror(reflecting: client)
        let clientKeyCandidates = ["supabaseKey", "apiKey", "anonKey", "anon"]
        for child in clientMirror.children {
            if let label = child.label, clientKeyCandidates.contains(label) {
                if let s = child.value as? String, !s.isEmpty { return s }
            }
        }

        // 3) Try to read session accessToken if present (some clients keep session under auth)
        for child in clientMirror.children {
            if let label = child.label, label == "auth" {
                let authMirror = Mirror(reflecting: child.value)
                for authChild in authMirror.children {
                    if let authLabel = authChild.label, authLabel == "session" {
                        let sessionMirror = Mirror(reflecting: authChild.value)
                        for sChild in sessionMirror.children {
                            if let sLabel = sChild.label, (sLabel == "accessToken" || sLabel == "access_token"), let token = sChild.value as? String, !token.isEmpty {
                                return token
                            }
                        }
                    }
                }
            }
        }

        // 4) Fallback placeholder — keep your real dev anon key here if you want local testing
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRlbmlrcGp5cmJsemJvbXphbXl1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMwNTExMzIsImV4cCI6MjA3ODYyNzEzMn0.k6kqcjIu-G0_YV9H1VjHfWaPahvl1RhMo9gBODYqUbo"
    }

    // MARK: Standard CRUD (unchanged)
    func fetchInventory(eventId: String) async throws -> [InventoryItemRecord] {
        let response = try await client
            .from("inventory_items")
            .select("*")
            .eq("event_id", value: eventId)
            .order("created_at", ascending: true)
            .execute()
        let decoder = JSONDecoder()
        return try decoder.decode([InventoryItemRecord].self, from: response.data)
    }

    func addInventoryItem(
        eventId: String,
        name: String,
        quantity: Int,
        unit: String?,
        sourceType: String
    ) async throws -> InventoryItemRecord {

        let payload = InventoryInsert(
            event_id: eventId,
            name: name,
            quantity: quantity,
            unit: unit,
            source_type: sourceType
        )

        let response = try await client
            .from("inventory_items")
            .insert([payload])
            .select("*")
            .execute()

        let decoder = JSONDecoder()
        let arr = try decoder.decode([InventoryItemRecord].self, from: response.data)
        guard let first = arr.first else {
            throw NSError(domain: "InventoryDataManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Empty insert response"])
        }
        return first
    }

    func updateUsedCount(itemId: String, used: Int) async throws -> InventoryItemRecord {
        let payload = InventoryUsedUpdate(used: used)

        let response = try await client
            .from("inventory_items")
            .update(payload)
            .eq("id", value: itemId)
            .select("*")
            .execute()

        let decoder = JSONDecoder()
        let arr = try decoder.decode([InventoryItemRecord].self, from: response.data)
        guard let first = arr.first else {
            throw NSError(domain: "InventoryDataManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Empty update response"])
        }
        return first
    }

    func deleteInventoryItem(itemId: String) async throws {
        _ = try await client
            .from("inventory_items")
            .delete()
            .eq("id", value: itemId)
            .execute()
    }

    // Post-event fetch/create
    func fetchPendingPostEventRows(eventId: String) async throws -> [PostEventRow] {
        let response = try await client
            .from("vw_postevent_pending")
            .select("*")
            .eq("event_id", value: eventId)
            .order("post_created_at", ascending: true)
            .execute()
        let decoder = JSONDecoder()
        return try decoder.decode([PostEventRow].self, from: response.data)
    }

    func createPostEventRow(inventoryItemId: String, eventId: String, qty: Int = 1) async throws {
        let payload = PostEventInsert(inventory_item_id: inventoryItemId, event_id: eventId, quantity: qty, state: "pending")
        _ = try await client
            .from("inventory_postevent")
            .insert([payload])
            .execute()
    }

    // --------------------------
    // New: Fetch lost/damaged post-event rows (server-backed)
    // --------------------------
    /// Fetch post-event rows with state = 'lost' and include inventory item metadata.
    /// Returns an array of PostEventRow constructed from the joined response.
    func fetchLostPostEventRows(eventId: String) async throws -> [PostEventRow] {
        // Select inventory_postevent rows with state = 'lost' and join inventory_items for meta
        // The select string uses PostgREST embedding: inventory_items(*)
        let response = try await client
            .from("inventory_postevent")
            .select("*, inventory_items(*)")
            .eq("event_id", value: eventId)
            .eq("state", value: "lost")
            .order("updated_at", ascending: false)
            .execute()

        // Parse raw JSON and construct PostEventRow array
        let raw = try JSONSerialization.jsonObject(with: response.data, options: []) as? [[String: Any]] ?? []

        var rows: [PostEventRow] = []
        for item in raw {
            // PostgREST commonly returns 'id' for the postevent row; the migration earlier used id = uuid
            let postId = (item["id"] as? String) ?? (item["postevent_id"] as? String) ?? ""
            let invId = item["inventory_item_id"] as? String ?? ""
            let evtId = item["event_id"] as? String ?? eventId

            // quantity could be under "quantity" or "post_qty"
            let qty: Int
            if let q = item["quantity"] as? Int { qty = q }
            else if let q = item["post_qty"] as? Int { qty = q }
            else if let qString = item["quantity"] as? String, let q = Int(qString) { qty = q }
            else if let qString = item["post_qty"] as? String, let q = Int(qString) { qty = q }
            else { qty = 0 }

            let state = item["state"] as? String ?? "lost"
            let note = item["note"] as? String

            // inventory_items nested object:
            var name = ""
            var invQuantity: Int? = nil
            var unit: String? = nil
            var sourceType: String? = nil
            if let nested = item["inventory_items"] as? [String: Any] {
                name = nested["name"] as? String ?? ""
                if let nq = nested["quantity"] as? Int { invQuantity = nq }
                else if let nqS = nested["quantity"] as? String, let nq = Int(nqS) { invQuantity = nq }
                unit = nested["unit"] as? String
                sourceType = nested["source_type"] as? String
            }

            let postCreatedAt = (item["created_at"] as? String) ?? (item["post_created_at"] as? String)

            let row = PostEventRow(
                posteventId: postId,
                inventoryItemId: invId,
                eventId: evtId,
                postQty: qty,
                state: state,
                note: note,
                name: name,
                inventoryQuantity: invQuantity,
                unit: unit,
                sourceType: sourceType,
                postCreatedAt: postCreatedAt
            )
            rows.append(row)
        }

        return rows
    }

    // --------------------------
    // RPC via URLSession (uses discovered baseURLString and anonKey)
    // --------------------------
    private func callRPC(functionName: String, jsonBody: Data) async throws {
        guard let base = URL(string: baseURLString), base.host != nil else {
            throw NSError(domain: "InventoryDataManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Supabase URL — please set baseURLString or ensure SupabaseManager exposes it"])
        }

        let rpcURL = base.appendingPathComponent("/rest/v1/rpc/\(functionName)")

        var req = URLRequest(url: rpcURL)
        req.httpMethod = "POST"
        req.httpBody = jsonBody
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Set Supabase headers
        let key = anonKey
        req.setValue(key, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("return=representation", forHTTPHeaderField: "Prefer")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let txt = String(data: data, encoding: .utf8) ?? "no body"
            throw NSError(domain: "InventoryDataManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "RPC \(functionName) failed: \(txt)"])
        }
    }

    func markPostEventReceived(postEventId: String, qty: Int = 1) async throws {
        let dict: [String: Any] = ["p_id": postEventId, "p_qty": qty]
        let body = try JSONSerialization.data(withJSONObject: dict, options: [])
        try await callRPC(functionName: "mark_postevent_received", jsonBody: body)
    }

    func markPostEventLost(postEventId: String, qty: Int = 1, note: String? = nil) async throws {
        var dict: [String: Any] = ["p_id": postEventId, "p_qty": qty]
        if let n = note { dict["p_note"] = n }
        let body = try JSONSerialization.data(withJSONObject: dict, options: [])
        try await callRPC(functionName: "mark_postevent_lost", jsonBody: body)
    }
}

