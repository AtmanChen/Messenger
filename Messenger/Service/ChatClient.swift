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
    public var users: @Sendable ([String]) async throws -> [User]
    public var allUsers: @Sendable (Int?) async throws -> [User]
    public var sendMessage: @Sendable (String, String, String) async throws -> Void
    public var observeChatMessages: @Sendable (String, User) -> AsyncStream<[Message]>
    public var observeRecentMessages: @Sendable (String) -> AsyncStream<[Message]>
}

extension ChatClient: DependencyKey {
    public static var liveValue = Self(
        createUser: {
            user,
            id in
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
        }
        ,users: { uids in
            let db = Firestore.firestore().collection("users")
            var users: [User] = []
            for uid in uids {
                let userData = try await db.document(uid).getDocument()
                users.append(try userData.data(as: User.self))
            }
            return users
        }
        ,allUsers: { limit in
            do {
                let query = Firestore.firestore().collection("users")
                if let limit {
                    query.limit(to: limit)
                }
                let snapshot = try await query.getDocuments()
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
            let recentCurrentUserRef = messageCollection.document(from).collection("recent-messages").document(to)
            let recentPartnerRef = messageCollection.document(to).collection("recent-messages").document(from)
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
            
            recentCurrentUserRef.setData(messageData)
            recentPartnerRef.setData(messageData)
        },
        observeChatMessages: { fromId, toUser in
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
        },
        observeRecentMessages: { uid in
            AsyncStream { continuation in
                let messageCollection = Firestore.firestore().collection("messages")
                let query = messageCollection
                    .document(uid)
                    .collection("recent-messages")
                    .order(by: "timestamp", descending: true)
                query.addSnapshotListener {
                    snapshot,
                    _ in
                    guard let changes = snapshot?.documentChanges.filter({
                        $0.type == .added || $0.type == .modified
                    }) else { return }
                    var messages = changes.compactMap({ try? $0.document.data(as: Message.self) })
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
