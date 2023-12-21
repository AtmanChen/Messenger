//
//  ChatClient.swift
//  Messenger
//
//  Created by Lambert on 2023/12/21.
//

import Foundation
import Dependencies
import FirebaseFirestoreSwift
import Firebase

public struct ChatClient {
    public var createUser: @Sendable (User, String) async throws -> Void
//    public var user: @Sendable (String) -> AsyncThrowingStream<User, Error>
//    public var currentUser: @Sendable () -> AsyncThrowingStream<User, Error>
}

extension ChatClient: DependencyKey {
    public static var liveValue = Self(
        createUser: { user, id in
            guard let encodedUser = try? Firestore.Encoder().encode(user) else { return }
            let userDocument = Firestore.firestore().collection("users").document(id)
            try await userDocument.setData(encodedUser)
        }
    )
}

extension DependencyValues {
    var chatClient: ChatClient {
        get { self[ChatClient.self] }
        set { self[ChatClient.self] = newValue }
    }
}
