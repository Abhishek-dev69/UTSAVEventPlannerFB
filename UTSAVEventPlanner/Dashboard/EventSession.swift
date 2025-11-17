//
//  EventSession.swift
//  UTSAVEventPlanner
//
//  Created by Abhishek on 14/11/25.
//

import Foundation

final class EventSession {
    static let shared = EventSession()
    private init() {}

    // Set when event is created (EventDetails -> insertEvent)
    var currentEventId: String?
}
