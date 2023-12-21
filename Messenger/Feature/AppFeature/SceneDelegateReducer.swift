//
//  SceneDelegateReducer.swift
//  Messenger
//
//  Created by Lambert on 2023/12/20.
//

import Foundation
import ComposableArchitecture
import UIKit

public struct SceneDelegateLogic: Reducer {
    public struct State: Equatable {
        public init() {}
    }
    public enum Action: Equatable {
        case shortcutItem(UIApplicationShortcutItem)
    }
    public func reduce(into state: inout State, action: Action) -> Effect<Action> {
        .none
    }
}

