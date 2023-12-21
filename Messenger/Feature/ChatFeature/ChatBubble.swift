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
        public let isFromCurrentUser: Bool
        public let id = UUID()
    }
    public enum Action: Equatable {
        
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
            Group {
                if viewStore.isFromCurrentUser {
                    HStack {
                        Spacer()
                        Text("This is a test message for now")
                            .font(.subheadline)
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
                } else {
                    HStack(alignment: .bottom, spacing: 4) {
                        //                    CircularProfileImageView(user: .mock, size: .xxSmall)
                        Text("Welcome to ISSUE #208 of The Overflow! This newsletter is by developers, for developers, written and curated by the Stack Overflow team and Cassidy Williams. This week: we discuss how to modernize alerting and incident management, ride a reindeer, and adopt a developer tool.")
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
                    }
                    Spacer()
                }
            }
            .padding(.horizontal)
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

#Preview {
    Group {
        ChatBubbleView(
            store: Store(
                initialState: ChatBubbleLogic.State(isFromCurrentUser: true),
                reducer: { ChatBubbleLogic() }
            )
        )
        ChatBubbleView(
            store: Store(
                initialState: ChatBubbleLogic.State(isFromCurrentUser: false),
                reducer: { ChatBubbleLogic() }
            )
        )
    }
}
