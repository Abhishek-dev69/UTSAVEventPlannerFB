//
//  EventDataManager.swift
//  UTSAVEventPlanner
//
//  Handles: Event details, event cart, payments, budget, inventory
//

import Foundation
import Supabase

// MARK: - Models

struct PaymentRecord: Codable {
    let id: String
    let event_id: String
    let amount: Double
    let method: String
    let received_on: String
    let created_at: String
}

struct PaymentInsert: Codable {
    let event_id: String
    let amount: Double
    let method: String
    let received_on: String
}

struct BudgetEntryRecord: Codable {
    let id: String
    let event_id: String
    let title: String
    let amount: Double
    let category: String?
    let created_at: String
}

struct BudgetEntryInsert: Codable {
    let event_id: String
    let title: String
    let amount: Double
    let category: String?
}

struct InventoryItemRecord: Codable {
    let id: String
    let event_id: String
    let name: String
    let quantity: Int
    let unit: String?
    let used: Int
    let created_at: String
}

struct InventoryInsert: Codable {
    let event_id: String
    let name: String
    let quantity: Int
    let unit: String?
}


// MARK: - Event Data Manager

final class EventDataManager {

    static let shared = EventDataManager()
    private init() {}

    private var client: SupabaseClient {
        return SupabaseManager.shared.client
    }

    private func ensureUserId() async throws -> String {
        try await SupabaseManager.shared.ensureUserId()
    }

    // MARK: - 1. Fetch Event Cart Items

    func fetchCartItems(eventId: String) async throws -> [CartItemRecord] {

        let response = try await client
            .from("cart_items")
            .select("*")
            .eq("event_id", value: eventId)
            .execute()

        if let raw = String(data: response.data, encoding: .utf8) {
            print("fetchCartItems(event) raw:", raw)
        }

        return try JSONDecoder().decode([CartItemRecord].self, from: response.data)
    }


    // MARK: - 2. Payments

    func fetchPayments(eventId: String) async throws -> [PaymentRecord] {

        let response = try await client
            .from("event_payments")
            .select("*")
            .eq("event_id", value: eventId)
            .order("received_on", ascending: false)
            .execute()

        return try JSONDecoder().decode([PaymentRecord].self, from: response.data)
    }

    func addPayment(eventId: String, amount: Double, method: String, date: String) async throws -> PaymentRecord {

        let payload = PaymentInsert(
            event_id: eventId,
            amount: amount,
            method: method,
            received_on: date
        )

        let response = try await client
            .from("event_payments")
            .insert(payload)
            .select("*")
            .execute()

        let inserted = try JSONDecoder().decode([PaymentRecord].self, from: response.data)
        return inserted.first!
    }


    // MARK: - 3. Budget Entries

    func fetchBudgetEntries(eventId: String) async throws -> [BudgetEntryRecord] {

        let response = try await client
            .from("budget_entries")
            .select("*")
            .eq("event_id", value: eventId)
            .order("created_at", ascending: false)
            .execute()

        return try JSONDecoder().decode([BudgetEntryRecord].self, from: response.data)
    }

    func addBudgetEntry(eventId: String, title: String, amount: Double, category: String?) async throws -> BudgetEntryRecord {

        let payload = BudgetEntryInsert(
            event_id: eventId,
            title: title,
            amount: amount,
            category: category
        )

        let response = try await client
            .from("budget_entries")
            .insert(payload)
            .select("*")
            .execute()

        let inserted = try JSONDecoder().decode([BudgetEntryRecord].self, from: response.data)
        return inserted.first!
    }


    // MARK: - 4. Inventory Items

    func fetchInventory(eventId: String) async throws -> [InventoryItemRecord] {

        let response = try await client
            .from("inventory_items")
            .select("*")
            .eq("event_id", value: eventId)
            .execute()

        return try JSONDecoder().decode([InventoryItemRecord].self, from: response.data)
    }

    func addInventoryItem(eventId: String, name: String, quantity: Int, unit: String?) async throws -> InventoryItemRecord {

        let payload = InventoryInsert(
            event_id: eventId,
            name: name,
            quantity: quantity,
            unit: unit
        )

        let response = try await client
            .from("inventory_items")
            .insert(payload)
            .select("*")
            .execute()

        let inserted = try JSONDecoder().decode([InventoryItemRecord].self, from: response.data)
        return inserted.first!
    }
}

