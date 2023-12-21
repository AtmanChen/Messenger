//
//  Login.swift
//  Messenger
//
//  Created by Lambert on 2023/12/15.
//

import Foundation
import ComposableArchitecture
import SwiftUI

public struct LoginLogic: Reducer {
    public struct State: Equatable {
        var login = LoginSettingLogic.State()
        var path = StackState<Path.State>()
        public init() {}
    }
    
    public enum Action: Equatable {
        case login(LoginSettingLogic.Action)
        case path(StackAction<Path.State, Path.Action>)
    }
    
    public var body: some ReducerOf<Self> {
//        LoginPathLogic()
        Scope(state: \.login, action: /Action.login) {
            LoginSettingLogic()
        }
        Reduce { state, action in
            switch action {
            case .login(.delegate(.registerSetting)):
                state.path.append(.registerSetting())
                return .none
            case let .path(.element(id, action)):
                switch action {
                case .registerSetting(.delegate(.signInButtonTapped)):
                    state.path.pop(from: id)
                    return .none
                default: return .none
                }
            default: return .none
            }
        }
        .forEach(\.path, action: /Action.path) {
            Path()
        }
    }
    
    public struct Path: Reducer {
        public enum State: Equatable {
            case registerSetting(RegisterSettingLogic.State = .init())
        }
        
        public enum Action: Equatable {
            case registerSetting(RegisterSettingLogic.Action)
        }
        
        public var body: some ReducerOf<Self> {
            Scope(state: /State.registerSetting, action: /Action.registerSetting, child: RegisterSettingLogic.init)
        }
    }
}

public struct LoginView: View {
    let store: StoreOf<LoginLogic>
    public init(store: StoreOf<LoginLogic>) {
        self.store = store
    }
    public var body: some View {
        NavigationStackStore(
            store.scope(state: \.path, action: { .path($0) })) {
                LoginSettingView(store: store.scope(state: \.login, action: LoginLogic.Action.login))
            } destination: { store in
                switch store {
                case .registerSetting:
                    CaseLet(
                        /LoginLogic.Path.State.registerSetting,
                         action: LoginLogic.Path.Action.registerSetting,
                         then: RegisterSettingView.init(store:)
                    )
                }
            }

    }
}
