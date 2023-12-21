//
//  AppDelegate.swift
//  Messenger
//
//  Created by Lambert on 2023/12/20.
//

import Foundation
import ComposableArchitecture
import SwiftUI

public struct AppDelegateLogic: Reducer {
    public struct State: Equatable {
        public init() {}
    }
    public enum Action: Equatable {
        case didFinishLaunching
        case delegate(Delegate)
        
        public enum Delegate: Equatable {
            case didFinishLaunching
        }
    }
    @Dependency(\.userDefaults) var userDefaults
    @Dependency(\.firebaseAuth) var firebaseAuth
    @Dependency(\.firebaseCore) var firebaseCore
    
    public func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .didFinishLaunching:
            return .run { @MainActor send in
                firebaseCore.configure()
                await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask {
                      await send(.delegate(.didFinishLaunching))
                    }
                }
            }
        default: return .none
        }
    }
}
