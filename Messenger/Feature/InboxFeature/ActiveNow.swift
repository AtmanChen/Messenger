//
//  ActiveNow.swift
//  Messenger
//
//  Created by Lambert on 2023/12/19.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import FirebaseAuth

public struct ActiveNowItemLogic: Reducer {
    public struct State: Equatable, Identifiable {
        public var id: String {
            user.id
        }
        public init(_ user: User) {
            self.user = user
        }
        let user: User
    }
    public enum Action: Equatable {
        
    }
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
                .none
        }
    }
}

public struct ActiveNowItem: View {
    let store: StoreOf<ActiveNowItemLogic>
    public init(store: StoreOf<ActiveNowItemLogic>) {
        self.store = store
    }
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                ZStack(alignment: .bottomTrailing) {
                    CircularProfileImageView(user: viewStore.user, size: .large)
                    ZStack {
                        Circle()
                            .fill(Color(.systemBackground))
                            .frame(width: 18, height: 18)
                        Circle()
                            .fill(appTint.gradient)
                            .frame(width: 12, height: 12)
                    }
                }
                Text(viewStore.user.fullname)
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
        }
    }
}

public struct ActiveNowLogic: Reducer {
    public struct State: Equatable {
        var items: IdentifiedArrayOf<ActiveNowItemLogic.State> = []
        public init() {}
    }
    public enum Action: Equatable {
        case loadNowUsers
        case loadNowUsersResponse([User])
        case item(id: ActiveNowItemLogic.State.ID, action: ActiveNowItemLogic.Action)
        case itemTapped(id: ActiveNowItemLogic.State.ID)
        case delegate(Delegate)
        public enum Delegate: Equatable {
            case itemTapped(id: ActiveNowItemLogic.State.ID)
        }
    }
    @Dependency(\.chatClient) var chatClient
    @Dependency(\.firebaseAuth) var firebaseAuth
    public var body: some ReducerOf<Self> {
        Reduce {
            state,
            action in
            switch action {
            case .loadNowUsers:
                return .run { send in
                    await send(
                        .loadNowUsersResponse(
                            try await chatClient.allUsers(10)
                        ),
                        animation: .default
                    )
                }
            case let .loadNowUsersResponse(users):
                var filteredUsers: [User] = []
                if let currentUser = firebaseAuth.currentUser() {
                    filteredUsers = users.filter { $0.id != currentUser.uid }
                }
                state.items = IdentifiedArray(uniqueElements: filteredUsers.map(ActiveNowItemLogic.State.init))
                return .none
            case let .itemTapped(id):
                return .run { send in
                    await send(.delegate(.itemTapped(id: id)))
                }
            default: return .none
            }
        }
        .forEach(\.items, action: /Action.item) {
            ActiveNowItemLogic()
        }
        
    }
}

public struct ActiveNowView: View {
    let store: StoreOf<ActiveNowLogic>
    public init(store: StoreOf<ActiveNowLogic>) {
        self.store = store
    }
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 32) {
                ForEachStore(
                    store.scope(state: \.items, action: ActiveNowLogic.Action.item)
                ) { itemStore in
                    WithViewStore(itemStore, observe: { $0 }) { viewStore in
                        ActiveNowItem(store: itemStore)
                            .onTapGesture {
                                store.send(.itemTapped(id: viewStore.id))
                            }
                    }
                }
            }
            .padding(.vertical)
        }
        .frame(height: 106)
    }
}

#Preview {
    ActiveNowView(
        store: Store(
            initialState: ActiveNowLogic.State(),
            reducer: { ActiveNowLogic() }
        )
    )
}
