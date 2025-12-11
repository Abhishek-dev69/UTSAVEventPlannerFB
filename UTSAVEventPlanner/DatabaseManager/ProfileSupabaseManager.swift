//
//  ProfileSupabaseManager.swift
//

import Foundation
import Supabase
import UIKit

final class ProfileSupabaseManager {

    static let shared = ProfileSupabaseManager()
    private init() {}

    private let client = SupabaseManager.shared.client

    // MARK: - FETCH PROFILE
    func fetchProfile(for userId: String) async throws -> UserProfile? {

        let res = try await client
            .from("user_profiles")
            .select()
            .eq("id", value: userId)
            .limit(1)
            .execute()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let list = try decoder.decode([UserProfile].self, from: res.data)
        return list.first
    }

    // MARK: - UPSERT PROFILE
    func saveProfile(_ profile: UserProfileInsert) async throws -> UserProfile {

        let res = try await client
            .from("user_profiles")
            .upsert(profile)
            .select()
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(UserProfile.self, from: res.data)
    }
    
    // MARK: - UPLOAD PROFILE IMAGE
    func uploadProfileImage(userId: String, image: UIImage) async throws -> String {

        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw NSError(domain: "image", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "File conversion failed"])
        }

        let path = "profiles/\(userId).jpg"
        let bucket = client.storage.from("profile-photos")

        // Delete old file
        _ = try? await bucket.remove(paths: [path])

        // Upload new image
        try await bucket.upload(
            path,
            data: data,
            options: FileOptions(contentType: "image/jpeg")
        )

        // Get public URL
        let publicURL = try client
            .storage
            .from("profile-photos")
            .getPublicURL(path: path)
        
        let urlString = publicURL.absoluteString
        
        // ⭐ CRITICAL: Update the database with the new image URL
        try await client
            .from("user_profiles")
            .update(["profile_image_url": urlString])
            .eq("id", value: userId)
            .execute()

        return urlString
    }
}

