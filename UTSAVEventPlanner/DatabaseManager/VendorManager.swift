//
// VendorManager.swift
// EventPlanner target - vendor fetch helpers (single source)
//

import Foundation
import Supabase
import UIKit

// Replace this with your Supabase project base URL (example: "https://abcd1234.supabase.co")
private let SUPABASE_BASE_URL = "https://denikpjyrblzbomzamyu.supabase.co"

// ----------------------------
// Vendor model used by EventPlanner
// ----------------------------
public struct VendorRecord: Codable {
    public let id: String
    public var userId: String?
    public var fullName: String?
    public var role: String?
    public var bio: String?
    public var email: String?
    public var phone: String?
    public var businessName: String?
    public var businessAddress: String?
    public var avatarUrl: String?     // full public URL (if stored)
    public var avatarPath: String?    // storage path if only path stored
    public let createdAt: String?
    public let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case fullName = "full_name"
        case role, bio, email, phone
        case businessName = "business_name"
        case businessAddress = "business_address"
        case avatarUrl = "avatar_url"
        case avatarPath = "avatar_path"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// ----------------------------
// Portfolio & Service models (lightweight)
// ----------------------------
public struct PortfolioRecord: Codable {
    public let id: String
    public let vendorId: String?
    public let title: String?
    public let mediaUrl: String?
    public let mediaType: String? // "image" or "video"
    public let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case vendorId = "vendor_id"
        case title
        case mediaUrl = "media_url"
        case mediaType = "media_type"
        case createdAt = "created_at"
    }
}

public struct VendorServiceRecord: Codable {
    public let id: String
    public let vendorId: String?
    public let name: String
    public let description: String?
    public let price: Double?
    public let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case vendorId = "vendor_id"
        case name
        case description
        case price
        case createdAt = "created_at"
    }
}

// ----------------------------
// VendorManager - single copy (EventPlanner)
// ----------------------------
final class VendorManager {
    static let shared = VendorManager()
    private init() {}

    // Uses your existing SupabaseManager in EventPlanner target
    private var client: SupabaseClient {
        return SupabaseManager.shared.client
    }

    // exposed Supabase base URL from your SupabaseManager (fallback to constant)
    private var supabaseBaseURLString: String {
        let url = SupabaseManager.shared.supabaseBaseURL.absoluteString
        return url.isEmpty ? SUPABASE_BASE_URL : url
    }

    /// Fetch all vendors (public read). Ensure DB RLS/policy allows SELECT for the role your client uses.
    func fetchAllVendors() async throws -> [VendorRecord] {
        let res = try await client
            .from("vendors")
            .select("*")
            .order("created_at", ascending: false)
            .execute()

        let d = res.data
        if d.isEmpty { return [] }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return try decoder.decode([VendorRecord].self, from: d)
    }

    /// Fetch a single vendor by id
    func fetchVendorById(_ id: String) async throws -> VendorRecord? {
        let res = try await client
            .from("vendors")
            .select("*")
            .eq("id", value: id)
            .limit(1)
            .execute()

        let d = res.data
        if d.isEmpty { return nil }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let arr = try decoder.decode([VendorRecord].self, from: d)
        return arr.first
    }

    /// Fetch portfolio items for vendor
    /// NOTE: your DB schema uses `portfolio_items` (not `portfolio`) — we query that name here.
    func fetchPortfolioItems(vendorId: String) async throws -> [PortfolioRecord] {
        let res = try await client
            .from("portfolio_items")         // <-- CORRECTED TABLE NAME
            .select("*")
            .eq("vendor_id", value: vendorId)
            .order("created_at", ascending: false)
            .execute()

        let d = res.data
        if d.isEmpty { return [] }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return try decoder.decode([PortfolioRecord].self, from: d)
    }

    /// Fetch services for vendor
    func fetchServicesForVendor(vendorId: String) async throws -> [VendorServiceRecord] {
        let res = try await client
            .from("vendor_services")
            .select("*")
            .eq("vendor_id", value: vendorId)
            .order("created_at", ascending: false)
            .execute()

        let d = res.data
        if d.isEmpty { return [] }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return try decoder.decode([VendorServiceRecord].self, from: d)
    }

    /// Build a public URL for a storage path (bucket default "vendor-media" — change if needed)
    func publicURLForAvatar(bucket: String = "vendor-media", path: String) -> URL? {
        let base = supabaseBaseURLString
        let encoded = path.split(separator: "/")
            .map { String($0).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0) }
            .joined(separator: "/")
        let s = "\(base)/storage/v1/object/public/\(bucket)/\(encoded)"
        return URL(string: s)
    }

    /// Resolve avatar URL string for a vendor (prefer explicit avatarUrl, else build from avatarPath)
    func resolvedAvatarURLString(for vendor: VendorRecord) -> String? {
        if let u = vendor.avatarUrl, !u.isEmpty { return u }
        if let p = vendor.avatarPath, !p.isEmpty, let url = publicURLForAvatar(path: p) { return url.absoluteString }
        return nil
    }
}

