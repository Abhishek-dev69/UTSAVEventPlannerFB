import Foundation

final class DashboardEventStore {

    static let shared = DashboardEventStore()
    private init() {
        loadFromDisk()
    }

    private(set) var cachedEvents: [EventRecord] = []

    var hasCache: Bool {
        !cachedEvents.isEmpty
    }

    // MARK: - Disk location
    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("dashboard_events.json")
    }

    // MARK: - Save
    func set(_ events: [EventRecord]) {
        cachedEvents = events
        saveToDisk()
    }

    // MARK: - Clear (logout only)
    func clear() {
        cachedEvents.removeAll()
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Disk persistence
    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(cachedEvents)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("❌ Failed to save dashboard cache:", error)
        }
    }

    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            cachedEvents = try JSONDecoder().decode([EventRecord].self, from: data)
        } catch {
            print("❌ Failed to load dashboard cache:", error)
        }
    }
}

