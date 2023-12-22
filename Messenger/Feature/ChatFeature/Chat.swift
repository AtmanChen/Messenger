//
//  Chat.swift
//  Messenger
//
//  Created by Lambert on 2023/12/20.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import FirebaseAuth

public struct ChatLogic: Reducer {
    public struct State: Equatable, Identifiable {
        public init(_ id: String) {
            self.id = id
        }
        var user: User?
        @BindingState var messageText: String = ""
        var messages: IdentifiedArrayOf<ChatBubbleLogic.State> = []
        @BindingState var scrollTo: String?
        public var id: String
    }
    public enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case onTask
        case messageReceivedResponse([Message])
        case scrollToMessage(String)
        case loadUserResponse(User)
        case sendMessageButtonTapped(String)
        case bubbleMessage(id: ChatBubbleLogic.State.ID, action: ChatBubbleLogic.Action)
    }
    
    @Dependency(\.chatClient) var chatClient
    @Dependency(\.firebaseAuth) var firebaseAuth
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onTask:
                return .run { [id = state.id] send in
                    if let fetchedUser = try await chatClient.user(id),
                       let fromId = firebaseAuth.currentUser()?.uid {
                        await send(.loadUserResponse(fetchedUser))
                        for await receivedMessages in chatClient.observeMessages(fromId, fetchedUser) {
                            await send(.messageReceivedResponse(receivedMessages), animation: .default)
                        }
                    }
                }
            case let .messageReceivedResponse(messages):
                if let user = state.user {
                    state.messages.append(contentsOf: messages.map { ChatBubbleLogic.State(message: $0, user: user) })
                    if let lastMessageId = messages.last?.id {
                        return .run { send in
                            await send(.scrollToMessage(lastMessageId), animation: .default)
                        }
                    }
                }
                return .none
                
            case let .loadUserResponse(user):
                state.user = user
                return .none
            case let .sendMessageButtonTapped(content):
                state.messageText = ""
                if let fromId = firebaseAuth.currentUser()?.uid {
                    return .run { [toId = state.id] send in
                        try await chatClient.sendMessage(fromId, toId, content)
                    }
                }
                return .none
            case let .scrollToMessage(messageId):
                state.scrollTo = messageId
                return .none
                
            default: return .none
            }
        }
        .forEach(\.messages, action: /Action.bubbleMessage) {
            ChatBubbleLogic()
        }
    }
}

public struct ChatView: View {
    let store: StoreOf<ChatLogic>
    public init(store: StoreOf<ChatLogic>) {
        self.store = store
    }
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                ScrollView(showsIndicators: false) {
                    if let user = viewStore.user {
                        VStack {
                            CircularProfileImageView(user: user, size: .xLarge)
                            Text(user.fullname)
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("Messenger")
                                .font(.footnote)
                                .foregroundStyle(.gray.gradient)
                        }
                        if viewStore.messages.isEmpty {
                            VStack {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    
                                Text("There's no message yet.")
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(appTint.gradient)
                        } else {
                            ForEachStore(
                                store.scope(
                                    state: \.messages,
                                    action: ChatLogic.Action.bubbleMessage
                                ),
                                content: ChatBubbleView.init(store:)
                            )
                        }
                    }
                }
                .scrollPosition(id: viewStore.$scrollTo)
                Spacer()
                HStack(alignment: .bottom, spacing: 4) {
                    TextField("Message...", text: viewStore.$messageText, axis: .vertical)
                        .padding()
                        .background(Color(.systemGroupedBackground).gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 25.0))
                        .font(.subheadline)
                    Button {
                        viewStore.send(.sendMessageButtonTapped(viewStore.messageText))
                    } label: {
                        Image(systemName: "arrow.up")
                            .resizable()
                            .scaledToFill()
                            .fontWeight(.semibold)
                            .frame(width: 18, height: 18)
                            .padding()
                            .background(
                                Circle()
                                    .fill(viewStore.messageText.isEmpty ? Color.gray.gradient : appTint.gradient)
                            )
                            .foregroundStyle(Color(.systemBackground).gradient)
                    }
                    .disabled(viewStore.messageText.isEmpty)
                    .padding(.horizontal, 4)
                }
                .padding()
            }
            .task {
                await viewStore.send(.onTask).finish()
            }
        }
    }
}
