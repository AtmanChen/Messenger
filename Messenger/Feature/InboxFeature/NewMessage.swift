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
        var contacts: IdentifiedArrayOf<ContactRowLogic.State> = [
            ContactRowLogic.State(),
            ContactRowLogic.State()
        ]
    }
    public enum Action: Equatable, BindableAction {
        case cancelButtonTapped
        case binding(BindingAction<State>)
        case contactRow(id: ContactRowLogic.State.ID, action: ContactRowLogic.Action)
    }
    @Dependency(\.dismiss) var dismiss
    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .cancelButtonTapped:
                return .run { _ in
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
                    )) { store in
                        VStack(alignment: .leading) {
                            ContactRowView(store: store)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Divider()
                                .padding(.leading, 40)
                        }
                    }
                    .padding(.leading)
                
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
