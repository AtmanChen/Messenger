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
    public var user: @Sendable (String) async throws -> User?
    public var allUsers: @Sendable () async throws -> [User]
    public var sendMessage: @Sendable (String, String, String) async throws -> Void
    public var observeMessages: @Sendable (String, User) -> AsyncStream<[Message]>
}

extension ChatClient: DependencyKey {
    public static var liveValue = Self(
        createUser: {
            user, id in
            guard let encodedUser = try? Firestore.Encoder().encode(user) else { return }
            let userDocument = Firestore.firestore().collection("users").document(id)
            try await userDocument.setData(encodedUser)
        },
        user: { uid in
            do {
                let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
                return try snapshot.data(as: User.self)
            } catch {
                return nil
            }
        },
        allUsers: {
            do {
                let snapshot = try await Firestore.firestore().collection("users").getDocuments()
                return snapshot.documents.compactMap { try? $0.data(as: User.self) }
            } catch {
                return []
            }
        },
        sendMessage: {
            from,
            to,
            content in
            let messageCollection = Firestore.firestore().collection("messages")
            let currentUserRef = messageCollection.document(from).collection(to).document()
            let chatPartnerRef = messageCollection.document(to).collection(from)
            let messageId = currentUserRef.documentID
            let message = Message(
                messageId: messageId,
                fromId: from,
                toId: to,
                messageText: content,
                timestamp: Timestamp()
            )
            guard let messageData = try? Firestore.Encoder().encode(message) else { return }
            currentUserRef.setData(messageData)
            chatPartnerRef.document(messageId).setData(messageData)
        }, observeMessages: { fromId, toUser in
            AsyncStream { continuation in
                let messageCollection = Firestore.firestore().collection("messages")
                let query = messageCollection
                    .document(fromId)
                    .collection(toUser.id)
                    .order(by: "timestamp", descending: false)
                
                query.addSnapshotListener { snapshot, _ in
                    guard let changes = snapshot?.documentChanges.filter({ $0.type == .added }) else {
                        return
                    }
                    var messages = changes.compactMap({ try? $0.document.data(as: Message.self) })
                    for (index, message) in messages.enumerated() where message.fromId != fromId {
                        messages[index].user = toUser
                    }
                    continuation.yield(messages)
                }
            }
        }
    )
}

extension DependencyValues {
    var chatClient: ChatClient {
        get { self[ChatClient.self] }
        set { self[ChatClient.self] = newValue }
    }
}
