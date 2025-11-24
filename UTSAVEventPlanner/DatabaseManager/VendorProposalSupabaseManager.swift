//
//  VendorProposalSupabaseManager.swift
//  UTSAV
//
//  Created by Abhishek on 21/11/25.
//

//
//  VendorProposalSupabaseManager.swift
//  UTSAVEventPlanner / VendorApp
//
//  Handles sending, listing, and real-time updates
//  for vendor proposals between Planner App ↔ Vendor App
//

import Foundation
import Supabase

// MARK: - Proposal Models

struct VendorProposalInsert: Encodable {
    let event_id: String
    let vendor_id: String
    let planner_id: String
    let service_name: String
    let description: String
    let proposed_budget: Double
    let completion_date: String
    let notes: String
    let status: String
}

struct VendorProposalRecord: Codable {
    let id: String
    let eventId: String?
    let vendorId: String?
    let plannerId: String?
    let serviceName: String?
    let description: String?
    let proposedBudget: Double?
    let completionDate: String?
    let notes: String?
    let status: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case vendorId = "vendor_id"
        case plannerId = "planner_id"
        case serviceName = "service_name"
        case description
        case proposedBudget = "proposed_budget"
        case completionDate = "completion_date"
        case notes
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}


// MARK: - Manager

final class VendorProposalSupabaseManager {

    static let shared = VendorProposalSupabaseManager()
    private init() {}

    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    private func ensureUserId() async throws -> String {
        try await SupabaseManager.shared.ensureUserId()
    }


    // MARK: - 1. Send Proposal (Planner App)

    func sendProposal(
        eventId: String,
        vendorId: String,
        serviceName: String,
        description: String,
        budget: Double,
        completionDate: String,
        notes: String
    ) async throws {

        let plannerId = try await ensureUserId()

        let payload = VendorProposalInsert(
            event_id: eventId,
            vendor_id: vendorId,
            planner_id: plannerId,
            service_name: serviceName,
            description: description,
            proposed_budget: budget,
            completion_date: completionDate,
            notes: notes,
            status: "pending"
        )

        _ = try await client
            .from("vendor_proposals")
            .insert(payload)
            .select()
            .execute()

        print("📤 Sent proposal to vendor → \(vendorId)")
    }


    // MARK: - 2. Fetch All Proposals For Vendor (Vendor App)

    func fetchProposalsForVendor(vendorId: String) async throws -> [VendorProposalRecord] {

        let res = try await client
            .from("vendor_proposals")
            .select("*")
            .eq("vendor_id", value: vendorId)
            .order("created_at", ascending: false)
            .execute()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([VendorProposalRecord].self, from: res.data)
    }


    // MARK: - 3. Fetch All Proposals Sent By Planner (Planner App)

    func fetchPlannerProposals(plannerId: String) async throws -> [VendorProposalRecord] {

        let res = try await client
            .from("vendor_proposals")
            .select("*")
            .eq("planner_id", value: plannerId)
            .order("created_at", ascending: false)
            .execute()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([VendorProposalRecord].self, from: res.data)
    }


    // MARK: - 4. Real-Time Subscription (Vendor App)
    func subscribeToNewProposals(
        vendorId: String,
        onReceive: @escaping (VendorProposalRecord) -> Void
    ) {
        let channel = client.channel("vendor-proposals-\(vendorId)")

        // Fixed API for Supabase Swift SDK 2.37.0
        channel.onPostgresChange(
            AnyAction.self,
            schema: "public",
            table: "vendor_proposals",
            filter: "vendor_id=eq.\(vendorId)"
        ) { action in
            // Only process INSERT events
            guard case .insert(let record) = action else { return }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: record)
                let decoded = try JSONDecoder().decode(VendorProposalRecord.self, from: data)
                onReceive(decoded)
            } catch {
                print("❌ REALTIME decode failed:", error)
            }
        }

        // Use subscribeWithError instead of deprecated subscribe()
        Task {
            do {
                try await channel.subscribeWithError()
                print("📡 Vendor subscribed for proposals → \(vendorId)")
            } catch {
                print("❌ Realtime subscribe error:", error)
            }
        }
    }
    
    // MARK: - 5. Update Status (Vendor Accept/Reject)

    struct ProposalStatusUpdate: Encodable {
        let status: String
    }

    func updateProposalStatus(proposalId: String, status: String) async throws {
        let payload = ProposalStatusUpdate(status: status)

        _ = try await client
            .from("vendor_proposals")
            .update(payload)
            .eq("id", value: proposalId)
            .execute()

        print("🔄 Updated proposal \(proposalId) → \(status)")
    }
}

