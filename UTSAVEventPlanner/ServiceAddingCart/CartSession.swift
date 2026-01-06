//
//  CartSession.swift
//  UTSAV
//
//  Created by Abhishek on 06/01/26.
//
import Foundation

final class CartSession {

    static let shared = CartSession()   // ✅ REQUIRED
    private init() {}

    var currentSessionId: String?

    func startNewSession() {
        currentSessionId = UUID().uuidString
        print("🆕 Cart session:", currentSessionId!)
    }

    func clear() {
        currentSessionId = nil
    }
}
