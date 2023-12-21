//
//  FirebaseCoreClient.swift
//  Messenger
//
//  Created by Lambert on 2023/12/20.
//

import Foundation
import FirebaseCore
import Dependencies

public struct FirebaseCoreClient {
    public var configure: @Sendable () -> Void
}

extension FirebaseCoreClient: DependencyKey {
    public static let liveValue = Self {
        FirebaseApp.configure()
    }
}

public extension DependencyValues {
  var firebaseCore: FirebaseCoreClient {
    get { self[FirebaseCoreClient.self] }
    set { self[FirebaseCoreClient.self] = newValue }
  }
}
