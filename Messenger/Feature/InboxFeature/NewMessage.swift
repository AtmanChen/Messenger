//
//  NewMessage.swift
//  Messenger
//
//  Created by Lambert on 2023/12/19.
//

import Foundation
import ComposableArchitecture
import SwiftUI

public struct NewMessageLogic: Reducer {
    public struct State: Equatable {
        public init() {}
        @BindingState var searchText: String = ""
        var currentUser: User?
        var contacts: IdentifiedArrayOf<ContactRowLogic.State> = []
    }
    public enum Action: Equatable, BindableAction {
        case onTask
        case loadContactResponseWithExceptionIds([User], [String])
        case cancelButtonTapped
        case binding(BindingAction<State>)
        case contactRow(id: ContactRowLogic.State.ID, action: ContactRowLogic.Action)
        case contactRowTapped(ContactRowLogic.State.ID)
        case delegate(Delegate)
        
        public enum Delegate: Equatable {
            case contactRowTapped(ContactRowLogic.State.ID)
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.chatClient) var chatClient
    @Dependency(\.firebaseAuth) var firebaseAuth
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce {
            state,
            action in
            switch action {
            case .cancelButtonTapped:
                return .run { _ in
                    await dismiss()
                }
            case .onTask:
                return .run { send in
                    if let currentUser = firebaseAuth.currentUser() {
                        await send(
                            .loadContactResponseWithExceptionIds(
                                try await chatClient.allUsers(),
                                [currentUser.uid]
                            )
                        )
                    }
                }
                
            case let .loadContactResponseWithExceptionIds(users, exceptionIds):
                state.contacts = IdentifiedArray(
                    uniqueElements: users
                        .filter { !exceptionIds.contains($0.id) }
                        .map(ContactRowLogic.State.init)
                )
                return .none
                
            case let .contactRowTapped(id):
                return .run { send in
                    await send(.delegate(.contactRowTapped(id)))
                    await dismiss()
                }
            default: return .none
            }
        }
        .forEach(\.contacts, action: /Action.contactRow) {
            ContactRowLogic()
        }
    }
}

public struct NewMessageView: View {
    let store: StoreOf<NewMessageLogic>
    public init(store: StoreOf<NewMessageLogic>) {
        self.store = store
    }
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView(showsIndicators: false) {
                TextField("To: ", text: viewStore.$searchText)
                    .frame(height: 44)
                    .padding(.leading)
                    .background(Color(.systemGroupedBackground))
                
                Text("CONTACTS")
                    .font(.footnote)
                    .foregroundStyle(.gray.gradient)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                
                ForEachStore(
                    store.scope(
                        state: \.contacts,
                        action: NewMessageLogic.Action.contactRow
                    )) { rowStore in
                        WithViewStore(rowStore, observe: { $0 }) { viewStore in
                            VStack(alignment: .leading) {
                                ContactRowView(store: rowStore)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .onTapGesture {
                                        store.send(.contactRowTapped(viewStore.id))
                                    }
                                Divider()
                                    .padding(.leading, 40)
                            }
                        }
                    }
                    .padding(.leading)
            }
            .task {
                await viewStore.send(.onTask).finish()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewStore.send(.cancelButtonTapped)
                    } label: {
                        Text("Cancel")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.primary)
                    }
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    NavigationStack {
        NewMessageView(
            store: Store(
                initialState: NewMessageLogic.State(),
                reducer: { NewMessageLogic() }
            )
        )
    }
}
