//
//  RootNavigation.swift
//  Messenger
//
//  Created by Lambert on 2023/12/19.
//

import Foundation
import ComposableArchitecture
import SwiftUI

public struct RootNavigationLogic: Reducer {
    public struct State: Equatable {
        public init() {}
        var inbox = InboxLogic.State()
        var path = StackState<Path.State>()
    }
    public enum Action: Equatable {
        case inbox(InboxLogic.Action)
        case path(StackAction<Path.State, Path.Action>)
    }
    public var body: some ReducerOf<Self> {
        RootNavigationPathLogic()
        Scope(state: \.inbox, action: /Action.inbox, child: InboxLogic.init)
        Reduce { state, action in
            switch action {
            case .inbox(.delegate(.pushToProfile)):
                state.path.append(.profile())
                return .none
            case let .inbox(.delegate(.pushToChat(id))):
                state.path.append(.chat(ChatLogic.State(id.uuidString)))
                return .none
            default: return .none
            }
        }
        .forEach(\.path, action: /Action.path) {
            Path()
        }
    }
    
    
    public struct Path: Reducer {
        public enum State: Equatable {
            case profile(ProfileLogic.State = .init())
            case chat(ChatLogic.State)
        }
        public enum Action: Equatable {
            case profile(ProfileLogic.Action)
            case chat(ChatLogic.Action)
        }
        public var body: some ReducerOf<Self> {
            Scope(state: /State.profile, action: /Action.profile, child: ProfileLogic.init)
            Scope(state: /State.chat, action: /Action.chat, child: ChatLogic.init)
        }
    }
}



public struct RootNavigationView: View {
    let store: StoreOf<RootNavigationLogic>
    public init(store: StoreOf<RootNavigationLogic>) {
        self.store = store
    }
    public var body: some View {
        NavigationStackStore(store.scope(state: \.path, action: { .path($0) })) {
            InboxView(
                store: store.scope(
                    state: \.inbox,
                    action: RootNavigationLogic.Action.inbox
                )
            )
        } destination: { initialState in
            switch initialState {
            case .profile:
                CaseLet(
                    /RootNavigationLogic.Path.State.profile,
                     action: RootNavigationLogic.Path.Action.profile,
                     then: ProfileView.init(store:)
                )
                
            case .chat:
                CaseLet(
                    /RootNavigationLogic.Path.State.chat,
                     action: RootNavigationLogic.Path.Action.chat,
                     then: ChatView.init(store:)
                )
            }
        }
    }
}
