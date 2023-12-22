//
//  FirebaseAuthClient.swift
//  Messenger
//
//  Created by Lambert on 2023/12/20.
//

import Foundation
import FirebaseAuth
import Dependencies

public struct FirebaseAuthClient {
    
    public var currentUser: @Sendable () -> FirebaseAuth.User?
    public var addStateDidChangeListener: @Sendable () -> AsyncStream<FirebaseAuth.User?>
    public var signIn: @Sendable (String, String) async throws -> AuthDataResult?
    public var signUp: @Sendable (String, String, String) async throws -> FirebaseAuth.User?
    public var signOut: @Sendable () throws -> Void
    public var canHandle: @Sendable (URL) -> Bool
    public var verifyEmail: @Sendable (String) async throws -> String?
    public var credential: @Sendable (String, String) -> AuthCredential
    public var currentUserIdToken: @Sendable () async throws -> String?
}

extension FirebaseAuthClient: DependencyKey {
    public static var liveValue = Self(
        currentUser: { Auth.auth().currentUser },
        addStateDidChangeListener: {
            AsyncStream { continuation in
                Auth.auth().addStateDidChangeListener { _, user in
                    continuation.yield(user)
                }
            }
        },
        signIn: { email, password in
            try await withCheckedThrowingContinuation { continuation in
                Auth.auth().signIn(withEmail: email, password: password) { result, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: result)
                    }
                }
            }
        },
        signUp: { email, fullname, password in
            try await withCheckedThrowingContinuation { continuation in
                Auth.auth().createUser(withEmail: email, password: password) { result, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let user = result?.user {
                        let updateProfileRequest = user.createProfileChangeRequest()
                        updateProfileRequest.displayName = fullname
                        updateProfileRequest.commitChanges { error in
                            if let error {
                                continuation.resume(throwing: error)
                            } else {
                                continuation.resume(returning: user)
                            }
                        }
                    } else {
                        continuation.resume(returning: result?.user)
                    }
                }
            }
        },
        signOut: { try Auth.auth().signOut() },
        canHandle: { Auth.auth().canHandle($0) },
        verifyEmail: { email in
            email
        },
        credential: { email, password in
            EmailAuthProvider.credential(withEmail: email, password: password)
        },
        currentUserIdToken: {
            guard let currentUser = Auth.auth().currentUser else { return nil }
            return try await currentUser.getIDToken()
        }
    )
}

public extension DependencyValues {
  var firebaseAuth: FirebaseAuthClient {
    get { self[FirebaseAuthClient.self] }
    set { self[FirebaseAuthClient.self] = newValue }
  }
}
