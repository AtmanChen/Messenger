//
//  Inbox.swift
//  Messenger
//
//  Created by Lambert on 2023/12/19.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import FirebaseAuth

public struct InboxLogic: Reducer {
    public struct State: Equatable {
        public init() {}
        var currentUser: User?
        var navigationTitle: String {
            if let currentUser {
                let name = currentUser.fullname
                return name
            } else {
                return "Chats"
            }
        }
        var activeNow = ActiveNowLogic.State()
        var inboxRows: IdentifiedArrayOf<InboxRowLogic.State> = []
        @PresentationState var destination: Destination.State?
    }
    
    public enum Action: Equatable {
        case onTask
        case currentUserResponse(User?)
        case activeNow(ActiveNowLogic.Action)
        case inboxRow(id: InboxRowLogic.State.ID, action: InboxRowLogic.Action)
        case inboxRowTapped(InboxRowLogic.State.ID)
        case delete(IndexSet)
        case move(IndexSet, Int)
        case newMessageButtonTapped
        case destination(PresentationAction<Destination.Action>)
        case avatarViewTapped
        case delegate(Delegate)
        public enum Delegate: Equatable {
            case pushToProfile
            case pushToChat(InboxRowLogic.State.ID)
        }
    }
    @Dependency(\.firebaseAuth) var firebaseAuth
    @Dependency(\.chatClient) var chatClient
    @Dependency(\.mainQueue) var mainQueue
    
    public var body: some ReducerOf<Self> {
        Scope(state: \.activeNow, action: /Action.activeNow, child: ActiveNowLogic.init)
        Reduce {
            state,
            action in
            switch action {
            case .onTask:
                return .run { send in
                    if let authUser = firebaseAuth.currentUser() {
                        await send(
                            .currentUserResponse(
                                try await chatClient.user(authUser.uid)
                            )
                        )
                    }
                }
                
            case let .currentUserResponse(user):
                state.currentUser = user
                return .none
                
            case .activeNow:
                return .none
            case let .delete(indexSet):
                for index in indexSet {
                    state.inboxRows.remove(id: state.inboxRows[index].id)
                }
                return .none
                
            case var .move(source, destination):
                source = IndexSet(
                    source
                        .map { state.inboxRows[$0] }
                        .compactMap { state.inboxRows.index(id: $0.id) }
                )
                destination = 
                    (destination < state.inboxRows.endIndex
                     ? state.inboxRows.index(id: state.inboxRows[destination].id)
                    : state.inboxRows.endIndex
                ) ?? destination
                state.inboxRows.move(fromOffsets: source, toOffset: destination)
                return .none
            case .newMessageButtonTapped:
                state.destination = .newMessage()
                return .none
            case .avatarViewTapped:
                return .run { send in
                    await send(.delegate(.pushToProfile))
                }
                
            case let .inboxRowTapped(id):
                return .send(.delegate(.pushToChat(id)), animation: .default)
                
            case let .destination(.presented(.newMessage(.delegate(.contactRowTapped(id))))):
                return .run { send in
                    try await mainQueue.sleep(for: .milliseconds(250))
                    await send(.inboxRowTapped(id))
                }
                
            default: return .none
            }
        }
        .forEach(\.inboxRows, action: /Action.inboxRow) {
            InboxRowLogic()
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
    }
    
    public struct Destination: Reducer {
        public enum State: Equatable {
            case newMessage(NewMessageLogic.State = .init())
        }
        public enum Action: Equatable {
            case newMessage(NewMessageLogic.Action)
        }
        public var body: some ReducerOf<Self> {
            Scope(state: /State.newMessage, action: /Action.newMessage) {
                NewMessageLogic()
            }
        }
    }
}

public struct InboxView: View {
    let store: StoreOf<InboxLogic>
    public init(store: StoreOf<InboxLogic>) {
        self.store = store
    }
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            List {
                if !viewStore.activeNow.items.isEmpty {
                    ActiveNowView(
                        store: store.scope(state: \.activeNow, action: InboxLogic.Action.activeNow)
                    )
                    .listRowSeparator(.hidden)
                }
                ForEachStore(
                    store.scope(
                        state: \.inboxRows,
                        action: InboxLogic.Action.inboxRow
                    )) { rowStore in
                        WithViewStore(rowStore, observe: { $0 }) { viewStore in
                            InboxRowView(store: rowStore)
                                .onTapGesture {
                                    store.send(.inboxRowTapped(viewStore.id))
                                }
                        }
                        
                    }
                    .onDelete { viewStore.send(.delete($0)) }
                    .onMove { viewStore.send(.move($0, $1)) }
            }
            .overlay {
                if viewStore.inboxRows.isEmpty {
                    VStack {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                        Text("There's no chat yet.")
                            .font(.footnote)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(appTint.gradient)
                }
            }
            .listStyle(.plain)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)

                        Text(viewStore.navigationTitle)
                            .font(.title)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(appTint.gradient)
                    .onTapGesture {
                        viewStore.send(.avatarViewTapped)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewStore.send(.newMessageButtonTapped)
                    } label: {
                        Image(systemName: "square.and.pencil.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                    }
                    .foregroundStyle(appTint.gradient)
                }
            }
            .task {
                await viewStore.send(.onTask).finish()
            }
            .sheet(
                store: store.scope(state: \.$destination, action: { .destination($0) })) { destinationStore in
                    SwitchStore(destinationStore) { initialState in
                        switch initialState {
                        case .newMessage:
                            CaseLet(
                                /InboxLogic.Destination.State.newMessage,
                                 action: InboxLogic.Destination.Action.newMessage) { store in
                                     NavigationStack {
                                         NewMessageView(store: store)
                                     }
                                 }
                        }
                    }
                }
        }
    }
}


#Preview {
    NavigationStack {
        InboxView(
            store: Store(
                initialState: InboxLogic.State(),
                reducer: { InboxLogic() }
            )
        )
    }
}
