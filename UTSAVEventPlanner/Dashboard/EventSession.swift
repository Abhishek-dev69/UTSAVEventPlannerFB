//
//  EventSession.swift
//  UTSAVEventPlanner
//
//  Created by Abhishek on 14/11/25.
//
import Foundation
import UIKit
final class EventSession {
    static let shared = EventSession()
    private init() {}

    var currentEventId: String?
    var currentEventName: String?
    var currentClientName: String = ""
    var currentLocation: String = ""
    var currentStartDate: Date?
    var currentEndDate: Date?// ✅ ADD THIS
}
