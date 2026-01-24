import Foundation

final class ServicesStore {

    static let shared = ServicesStore()
    private init() {
        loadFromDisk()
    }

    private(set) var services: [Service] = []

    var hasCache: Bool {
        !services.isEmpty
    }

    // MARK: - File
    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("services_cache.json")
    }

    // MARK: - Update
    func set(_ newServices: [Service]) {
        services = newServices
        saveToDisk()
    }

    func clear() {
        services.removeAll()
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Persistence
    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(services)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("❌ Failed to save services cache:", error)
        }
    }

    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            services = try JSONDecoder().decode([Service].self, from: data)
        } catch {
            print("❌ Failed to load services cache:", error)
        }
    }
}

