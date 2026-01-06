//
//  EventSession.swift
//  UTSAVEventPlanner
//
//  Created by Abhishek on 14/11/25.
//

final class EventSession {
    static let shared = EventSession()
    private init() {}

    var currentEventId: String?
    var currentEventName: String?   // ✅ ADD THIS
}
