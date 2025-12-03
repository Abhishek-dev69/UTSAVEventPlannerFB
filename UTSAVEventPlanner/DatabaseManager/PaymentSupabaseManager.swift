//
//  PaymentSupabaseManager.swift
//

import Foundation
import Supabase

final class PaymentSupabaseManager {

    static let shared = PaymentSupabaseManager()
    private let client = SupabaseManager.shared.client

    private init() {}

    // MARK: - Fetch Payments (Optionally filter by payer_type)
    func fetchPayments(eventId: String, payerType: String? = nil) async throws -> [PaymentRecord] {

        var query = client
            .from("event_payments")
            .select("*")
            .eq("event_id", value: eventId)

        if let type = payerType {
            query = query.eq("payer_type", value: type)
        }

        let response = try await query
            .order("received_on", ascending: false)
            .execute()

        return try JSONDecoder().decode([PaymentRecord].self, from: response.data)
    }

    // MARK: - Insert Payment
    func insertPayment(
        eventId: String,
        amount: Double,
        method: String,
        receivedOn: String,
        payerType: String
    ) async throws -> PaymentRecord {

        let payload = PaymentInsert(
            event_id: eventId,
            amount: amount,
            method: method,
            received_on: receivedOn,
            payer_type: payerType
        )

        let response = try await client
            .from("event_payments")
            .insert(payload)
            .select("*")
            .execute()

        return try JSONDecoder().decode([PaymentRecord].self, from: response.data).first!
    }
}
