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
        var messages: IdentifiedArrayOf<ChatBubbleLogic.State> = [
            ChatBubbleLogic.State(isFromCurrentUser: true),
            ChatBubbleLogic.State(isFromCurrentUser: false),
            ChatBubbleLogic.State(isFromCurrentUser: true)
        ]
        public var id: String
    }
    public enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case sendMessageButtonTapped
        case bubbleMessage(id: ChatBubbleLogic.State.ID, action: ChatBubbleLogic.Action)
    }
    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .sendMessageButtonTapped:
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
                            Text("Bruce Wayne")
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
                Spacer()
                HStack(alignment: .bottom, spacing: 4) {
                    TextField("Message...", text: viewStore.$messageText, axis: .vertical)
                        .padding()
                        .background(Color(.systemGroupedBackground).gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 25.0))
                        .font(.subheadline)
                    Button {
                        
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
        }
    }
}
