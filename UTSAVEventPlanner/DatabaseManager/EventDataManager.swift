//
//  EventDataManager.swift
//  UTSAVEventPlanner
//
//  Handles: Event details, event cart, payments, budget, inventory
//

import Foundation
import Supabase

// MARK: - Budget Models

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
// MARK: - Event Data Manager

final class EventDataManager {

    static let shared = EventDataManager()
    private init() {}
    var currentEventId: String?

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

    func addPayment(
        eventId: String,
        amount: Double,
        method: String,
        date: String
    ) async throws -> PaymentRecord {

        let plannerId = try await ensureUserId()   
        let event = try await EventSupabaseManager.shared.fetchEvent(id: eventId)

        let payload = PaymentInsert(
            planner_id: plannerId,
            event_id: eventId,
            event_name: event.eventName,
            vendor_id: nil,
            vendor_name: nil,
            total_contracted_amount: nil, // Not used for direct client payments yet
            amount: amount,
            method: method,
            received_on: date,
            payer_type: "client"
        )

        let response = try await client
            .from("event_payments")
            .insert(payload)
            .select("*")
            .execute()

        return try JSONDecoder()
            .decode([PaymentRecord].self, from: response.data)
            .first!
    }
    // MARK: - Fetch Cart Items for Multiple Events
    func fetchCartItemsForEvents(eventIds: [String]) async throws -> [CartItemRecord] {

        guard !eventIds.isEmpty else { return [] }

        let response = try await client
            .from("cart_items")
            .select("*")
            .in("event_id", values: eventIds)
            .execute()

        return try JSONDecoder().decode([CartItemRecord].self, from: response.data)
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
}

