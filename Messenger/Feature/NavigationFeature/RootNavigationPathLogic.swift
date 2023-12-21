//
//  RootNavigationPathLogic.swift
//  Messenger
//
//  Created by Lambert on 2023/12/19.
//

import Foundation
import ComposableArchitecture

public struct RootNavigationPathLogic: Reducer {
    public func reduce(into state: inout RootNavigationLogic.State, action: RootNavigationLogic.Action) -> Effect<RootNavigationLogic.Action> {
        .none
    }
}
