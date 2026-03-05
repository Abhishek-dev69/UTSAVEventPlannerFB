//
//  PaymentSupabaseManager.swift
//

import Foundation
import Supabase

// MARK: - Insert Model

struct VendorPaymentInsert: Encodable {
    let planner_id: String
    let event_id: String?
    let vendor_id: String?
    let amount: Double
    let method: String
    let received_on: String
    let payer_type: String
}

final class PaymentSupabaseManager {

    static let shared = PaymentSupabaseManager()
    private let client = SupabaseManager.shared.client

    private init() {}

    // MARK: - Fetch Payments (Event Based)
    func fetchPayments(eventId: String, payerType: String? = nil) async throws -> [PaymentRecord] {

        let plannerId = try await SupabaseManager.shared.ensureUserId()

        var query = client
            .from("event_payments")
            .select("*")
            .eq("event_id", value: eventId)
            .eq("planner_id", value: plannerId)   

        if let type = payerType {
            query = query.eq("payer_type", value: type)
        }

        let response = try await query
            .order("received_on", ascending: false)
            .execute()

        return try JSONDecoder().decode([PaymentRecord].self, from: response.data)
    }


    // MARK: - Fetch Vendor Payments (Single Vendor)
    func fetchVendorPayments(vendorId: String) async throws -> [PaymentRecord] {

        let plannerId = try await SupabaseManager.shared.ensureUserId()

        let response = try await client
            .from("event_payments")
            .select("*")
            .eq("payer_type", value: "vendor")
            .eq("vendor_id", value: vendorId)
            .eq("planner_id", value: plannerId)   // ✅ FIXED
            .order("received_on", ascending: false)
            .execute()

        return try JSONDecoder().decode([PaymentRecord].self, from: response.data)
    }
    // MARK: - Fetch Payments for Multiple Events (Batch)
    func fetchPaymentsForEvents(eventIds: [String]) async throws -> [PaymentRecord] {

        guard !eventIds.isEmpty else { return [] }

        let plannerId = try await SupabaseManager.shared.ensureUserId()

        let response = try await client
            .from("event_payments")
            .select("*")
            .in("event_id", values: eventIds)
            .eq("planner_id", value: plannerId)
            .eq("payer_type", value: "client")
            .execute()

        return try JSONDecoder().decode([PaymentRecord].self, from: response.data)
    }


    // MARK: - Fetch ALL Vendor Payments
    func fetchAllVendorPayments() async throws -> [PaymentRecord] {

        let plannerId = try await SupabaseManager.shared.ensureUserId()

        let response = try await client
            .from("event_payments")
            .select("*")
            .eq("payer_type", value: "vendor")
            .eq("planner_id", value: plannerId)   // ✅ FIXED
            .order("received_on", ascending: false)
            .execute()

        return try JSONDecoder().decode([PaymentRecord].self, from: response.data)
    }


    // MARK: - Insert Vendor Payment
    func insertVendorPayment(
        vendorId: String,
        amount: Double,
        method: String,
        receivedOn: String
    ) async throws -> PaymentRecord {

        let plannerId = try await SupabaseManager.shared.ensureUserId()

        let payload = VendorPaymentInsert(
            planner_id: plannerId,   // ✅ OWNER
            event_id: nil,
            vendor_id: vendorId,
            amount: amount,
            method: method,
            received_on: receivedOn,
            payer_type: "vendor"
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
}
