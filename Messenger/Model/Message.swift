//
//  Message.swift
//  Messenger
//
//  Created by Lambert on 2023/12/22.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

public struct Message: Identifiable, Codable, Equatable {
    @DocumentID public var messageId: String?
    public let fromId: String
    public let toId: String
    public let messageText: String
    public let timestamp: Timestamp
    
    public var user: User?
    public var id: String {
        messageId ?? UUID().uuidString
    }
}
