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
        public var id: String
        public init(_ id: String) {
            self.id = id
        }
        var user: User?
        
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
                if let user = viewStore.user {
                    ZStack(alignment: .bottomTrailing) {
                        CircularProfileImageView(user: user, size: .large)
                        ZStack {
                            Circle()
                                .fill(Color(.systemBackground))
                                .frame(width: 18, height: 18)
                            Circle()
                                .fill(Color(.systemGreen))
                                .frame(width: 12, height: 12)
                        }
                    }
                    Text(user.fullname)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
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
        case item(id: ActiveNowItemLogic.State.ID, action: ActiveNowItemLogic.Action)
        case itemTapped(id: ActiveNowItemLogic.State.ID)
    }
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .itemTapped:
                return .none
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
