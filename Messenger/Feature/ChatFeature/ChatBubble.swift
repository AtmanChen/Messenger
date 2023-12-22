//
//  ChatBubble.swift
//  Messenger
//
//  Created by Lambert on 2023/12/20.
//

import Foundation
import ComposableArchitecture
import SwiftUI

public struct ChatBubbleLogic: Reducer {
    public struct State: Equatable, Identifiable {
        public let message: Message
        public let user: User
        public let isFromCurrentUser: Bool
        public init(message: Message, user: User) {
            self.message = message
            self.user = user
            self.isFromCurrentUser = user.id == message.toId
        }
        public var id: String {
            message.id
        }
    }
    public enum Action: Equatable {
        case onTask
    }
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
                .none
        }
    }
}

public struct ChatBubbleView: View {
    let store: StoreOf<ChatBubbleLogic>
    public init(store: StoreOf<ChatBubbleLogic>) {
        self.store = store
    }
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            if viewStore.isFromCurrentUser {
                HStack {
                    Spacer()
                    Text(viewStore.message.messageText)
                        .font(.subheadline)
                        .foregroundStyle(.white.gradient)
                        .padding()
                        .background {
                            LinearGradient(
                                colors: [Color(.systemBlue), Color(.systemCyan)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                        .clipShape(ChatBubbleShape(role: .right))
                        .frame(maxWidth: UIScreen.main.bounds.width / 1.5, alignment: .trailing)
                }
                .padding(.horizontal)
            } else {
                HStack(alignment: .bottom, spacing: 4) {
                    CircularProfileImageView(user: viewStore.user, size: .xxSmall)
                    Text(viewStore.message.messageText)
                        .font(.subheadline)
                        .padding()
                        .background {
                            LinearGradient(
                                colors: [Color(.systemMint), Color(.systemPink)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                        .clipShape(ChatBubbleShape(role: .left))
                        .frame(maxWidth: UIScreen.main.bounds.width / 1.75, alignment: .leading)
                    Spacer()
                }
                .padding(.horizontal)
                
            }
            
        }
    }
}

private enum ChatBubbleRole {
    case left
    case right
}

private struct ChatBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [
                .topLeft,
                .topRight,
                role == .left ? .bottomRight : .bottomLeft
            ],
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
        return Path(path.cgPath)
    }
    
    let role: ChatBubbleRole
    let cornerRadius: CGFloat
    init(role: ChatBubbleRole, cornerRadius: CGFloat = 16) {
        self.role = role
        self.cornerRadius = cornerRadius
    }
    
}

