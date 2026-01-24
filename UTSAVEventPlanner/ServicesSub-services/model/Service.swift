// Service.swift
import Foundation

// MARK: - UI MODELS
struct Service:Codable {
    var id: String?
    var name: String
    var subservices: [Subservice]
}

struct Subservice:Codable {
    var id: String?
    var name: String
    var rate: Double
    var unit: String
    var isFixed: Bool        // REQUIRED
}

// MARK: - CREATE PAYLOAD
struct ServiceCreatePayload {
    var name: String
    var subservices: [Subservice]
}

// MARK: - SERVER RECORDS
struct SubserviceRecord: Codable {
    let id: String
    let service_id: String
    let name: String
    let rate: Double
    let unit: String
    let is_fixed: Bool?        // <-- IMPORTANT

    func toSubserviceModel() -> Subservice {
        // read actual DB value
        let fixed = is_fixed ?? true     // default true if missing

        return Subservice(
            id: id,
            name: name,
            rate: rate,
            unit: unit,
            isFixed: fixed
        )
    }
}
struct ServiceRecord: Codable {
    let id: String
    let name: String
    let created_at: String?
    let subservices: [SubserviceRecord]?

    func toServiceModel() -> Service {
        let subs = subservices?.map { $0.toSubserviceModel() } ?? []
        return Service(id: id, name: name, subservices: subs)
    }
}

