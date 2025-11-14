// Service.swift
import UIKit

// UI models
struct Service {
    var id: String?        // server id (uuid) or nil for local only
    var name: String
    var subservices: [Subservice]
}

struct Subservice {
    let id: String?        // server uuid or temporary "local-xxxx"
    var name: String
    var rate: Double
    var unit: String
    var image: UIImage?
}

// Payloads for creating server rows
struct ServiceCreatePayload {
    var name: String
    var subservices: [Subservice]
}

// Server record decodable structs
struct SubserviceRecord: Codable {
    let id: String
    let service_id: String
    let name: String
    let rate: Double
    let unit: String
    let image_url: String?

    func toSubserviceModel() -> Subservice {
        return Subservice(id: id, name: name, rate: rate, unit: unit, image: nil)
    }
}

struct ServiceRecord: Codable {
    let id: String
    let name: String
    let created_at: String?
    var subservices: [SubserviceRecord]?

    func toServiceModel() -> Service {
        let uiSubs = subservices?.map { $0.toSubserviceModel() } ?? []
        return Service(id: id, name: name, subservices: uiSubs)
    }
}

