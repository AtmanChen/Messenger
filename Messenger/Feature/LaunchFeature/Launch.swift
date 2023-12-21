//
//  LaunchFeature.swift
//  Messenger
//
//  Created by Lambert on 2023/12/15.
//

import Foundation
import ComposableArchitecture
import SwiftUI

public struct LaunchLogic: Reducer {
    public init() {}
    
    public struct State: Equatable {
        public init() {}
    }
    
    public enum Action: Equatable {
        case onTask
    }
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onTask:
                return .none
            }
        }
    }
}

public struct LaunchView: View {
    let store: StoreOf<LaunchLogic>
    public init(store: StoreOf<LaunchLogic>) {
        self.store = store
    }
    public var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .foregroundStyle(appTint.gradient)
        }
    }
}

