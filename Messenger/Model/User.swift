//
//  User.swift
//  Messenger
//
//  Created by Lambert on 2023/12/19.
//

import Foundation
import FirebaseFirestoreSwift

public struct User: Codable, Identifiable, Equatable {
    @DocumentID public var uid: String?
    public let email: String
    public let fullname: String
    public var profileImageUrl: String?
    public var id: String {
        uid ?? UUID().uuidString
    }
}

public extension User {
    static let mock = User(uid: UUID().uuidString, email: "batman@gmail.com", fullname: "Bruce Wayne", profileImageUrl: "batman")
}
