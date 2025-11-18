//
//  InventoryDataManager.swift
//

import Foundation
import Supabase

// MARK: - Inventory Row Model
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

// MARK: - Insert Payload
struct InventoryInsert: Encodable {
    let event_id: String
    let name: String
    let quantity: Int
    let unit: String?
    let source_type: String
}

// MARK: - Update Payload
struct InventoryUsedUpdate: Encodable {
    let used: Int
}

// MARK: - Data Manager
final class InventoryDataManager {

    static let shared = InventoryDataManager()
    private init() {}

    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    // MARK: Fetch Inventory
    func fetchInventory(eventId: String) async throws -> [InventoryItemRecord] {

        let response = try await client
            .from("inventory_items")
            .select("*")
            .eq("event_id", value: eventId)
            .order("created_at", ascending: true)
            .execute()

        let decoder = JSONDecoder()   // IMPORTANT: do NOT use convertFromSnakeCase
        return try decoder.decode([InventoryItemRecord].self, from: response.data)
    }

    // MARK: Insert Item
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
            .insert([payload])          // MUST be array
            .select("*")                // MUST return event_id
            .execute()

        // Debug raw JSON if needed
        // print(String(data: response.data, encoding: .utf8)!)

        let decoder = JSONDecoder()
        let arr = try decoder.decode([InventoryItemRecord].self, from: response.data)

        return arr.first!
    }

    // MARK: Update Used Count
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

        return arr.first!
    }

    // MARK: Delete
    func deleteInventoryItem(itemId: String) async throws {
        _ = try await client
            .from("inventory_items")
            .delete()
            .eq("id", value: itemId)
            .execute()
    }
}

