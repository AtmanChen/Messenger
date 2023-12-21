//
//  LoginPathLogic.swift
//  Messenger
//
//  Created by Lambert on 2023/12/19.
//

import Foundation
import ComposableArchitecture

public struct LoginPathLogic: Reducer {
    public func reduce(into state: inout LoginLogic.State, action: LoginLogic.Action) -> Effect<LoginLogic.Action> {
        switch action {
        case let .path(.element(id, action)):
            switch action {
            case .registerSetting(.delegate(.signInButtonTapped)):
                state.path.pop(from: id)
                return .none
            default: return .none
            }
            
        default: return .none
        }
    }
}
