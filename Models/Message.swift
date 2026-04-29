//
//  Message.swift
//  AISecurityChatbot
//
//  Created by Donggeun Lee on 4/29/26.
//

import Foundation

struct Message: Identifiable {
    let id = UUID()
    let role: String
    var content: String
    
    var isUser: Bool { role == "user" }
}
