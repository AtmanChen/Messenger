//
//  InboxRow.swift
//  Messenger
//
//  Created by Lambert on 2023/12/19.
//

import Foundation
import ComposableArchitecture
import SwiftUI

public struct InboxRowLogic: Reducer {
    public struct State: Equatable, Identifiable {
        // avatar, name, latest message, latest message timestamp etc...
        public let message: Message
        public init(_ message: Message) {
            self.message = message
        }
        public var id: String {
            message.user?.uid ?? ""
        }
    }
    
    public enum Action: Equatable {
        
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
                .none
        }
    }
}

public struct InboxRowView: View {
    let store: StoreOf<InboxRowLogic>
    public init(store: StoreOf<InboxRowLogic>) {
        self.store = store
    }
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            HStack(alignment: .top, spacing: 12) {
//                Image(systemName: "person.circle.fill")
//                    .resizable()
//                    .frame(width: 64, height: 64)
//                    .foregroundStyle(Color(.systemGray4).gradient)
                if let user = viewStore.message.user {
                    CircularProfileImageView(user: user, size: .large)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(user.fullname)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            HStack {
                                Text(viewStore.message.timestamp.dateValue(), style: .time)
                                Image(systemName: "chevron.right")
                            }
                            .font(.footnote)
                        }
                        Text(viewStore.message.messageText)
                            .font(.subheadline)
                            .foregroundStyle(.gray.gradient)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .foregroundStyle(.gray.gradient)
                }
            }
            .frame(height: 72)
        }
    }
}
