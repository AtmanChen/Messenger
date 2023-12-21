//
//  Onboard.swift
//  Messenger
//
//  Created by Lambert on 2023/12/15.
//

import Foundation
import ComposableArchitecture
import SwiftUI

public struct OnboardLogic: Reducer {
    public init() {}
    public struct State: Equatable {
        public init() {}
    }
    
    public enum Action: Equatable {
        case getStartButtonTapped
    }
    
    @Dependency(\.userDefaults) var userDefaults
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .getStartButtonTapped:
                return .run { _ in
                    await userDefaults.setOnboardCompleted(true)
                }
            }
        }
    }
    
    /*
    public struct Path: Reducer {
        public enum State: Equatable {
            case
        }
    }
     */
}

public struct OnboardView: View {
    public let store: StoreOf<OnboardLogic>
    public init(store: StoreOf<OnboardLogic>) {
        self.store = store
    }
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                Spacer()
                Button {
                    viewStore.send(.getStartButtonTapped)
                } label: {
                    Text("Get Started")
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(appTint.gradient, in: .rect(cornerRadius: 12))
                        .contentShape(.rect)
                }
                .padding()
            }
            .background(
                Color(.systemBackground)
                    .ignoresSafeArea()
            )
        }
    }
}

#Preview {
    OnboardView(
        store: Store(
            initialState: OnboardLogic.State()
        ) {
            OnboardLogic()
        }
    )
}
