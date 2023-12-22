//
//  Contact.swift
//  Messenger
//
//  Created by Lambert on 2023/12/19.
//

import Foundation
import ComposableArchitecture
import SwiftUI

public struct ContactRowLogic: Reducer {
    public struct State: Equatable, Identifiable {
        public init(_ user: User) {
            self.user = user
        }
        var user: User
        public var id: String {
            user.uid ?? UUID().uuidString
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

public struct ContactRowView: View {
    let store: StoreOf<ContactRowLogic>
    public init(store: StoreOf<ContactRowLogic>) {
        self.store = store
    }
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            HStack {
                CircularProfileImageView(user: viewStore.user, size: .small)
                Text(viewStore.user.fullname)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary.gradient)
            }
            .contentShape(Rectangle())
        }
    }
}
