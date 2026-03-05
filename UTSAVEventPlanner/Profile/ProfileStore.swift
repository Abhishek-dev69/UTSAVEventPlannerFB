//
//  ProfileStore.swift
//  UTSAV
//
//  Created by Abhishek on 27/01/26.
//

import Foundation

final class ProfileStore {

    static let shared = ProfileStore()
    private init() {
        loadFromDisk()
    }

    private(set) var cachedProfile: UserProfile?

    var hasCache: Bool {
        cachedProfile != nil
    }

    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("user_profile.json")
    }

    func set(_ profile: UserProfile) {
        cachedProfile = profile
        saveToDisk()
    }
    func clear() {
        cachedProfile = nil
        try? FileManager.default.removeItem(at: fileURL)
    }
    private func saveToDisk() {
        guard let profile = cachedProfile else { return }
        do {
            let data = try JSONEncoder().encode(profile)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("❌ Failed to save profile cache:", error)
        }
    }

    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            cachedProfile = try JSONDecoder().decode(UserProfile.self, from: data)
        } catch {
            print("❌ Failed to load profile cache:", error)
        }
    }
}
