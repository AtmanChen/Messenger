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
        public let id = UUID()
        public init() {}
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
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(Color(.systemGray4).gradient)
                Text("Bruce")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary.gradient)
            }
        }
    }
}
