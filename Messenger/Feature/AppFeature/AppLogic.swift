//
//  AppLogic.swift
//  Messenger
//
//  Created by Lambert on 2023/12/15.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import FirebaseAuth

public struct AppLogic: Reducer {
    public init() {}
    
    public struct State: Equatable {
        var account = Account()
        var appDelegate = AppDelegateLogic.State()
        var sceneDelegate = SceneDelegateLogic.State()
        var view: View.State
        
        struct Account: Equatable {
            var authUser = AsyncValue<FirebaseAuth.User?>.none
        }
        
        public init() {
            view = View.State.login()
        }
    }
    
    @Dependency(\.userDefaults) var userDefaults
    @Dependency(\.chatClient) var chatClient
    @Dependency(\.firebaseAuth.currentUser) var currentUser
    
    public enum Action {
        case appDelegate(AppDelegateLogic.Action)
        case sceneDelegate(SceneDelegateLogic.Action)
        case view(View.Action)
        case authUserResponse(TaskResult<FirebaseAuth.User?>)
        case createUser(User, String)
    }
    
    public var body: some Reducer<State, Action> {
        core
            .onChange(of: \.account) { account, state, _ in
                guard case let .success(user) = account.authUser else {
                    return .none
                }
                let onboardCompleted = userDefaults.onboardCompleted()
                if let user, onboardCompleted {
                    state.view = .navigation()
                    return .run { send in
                        let uid = user.uid
                        if try await chatClient.user(uid) == nil {
                            if let authUser = currentUser() {
                                let user = User(email: authUser.email ?? "", fullname: authUser.displayName ?? "")
                                await send(.createUser(user, uid))
                            }
                        }
                    } catch: { error, send in
                        
                    }
                    
                }  else {
                    if case .onboard = state.view {
                        
                    } else {
                        state.view = .onboard()
                    }
                }
                return .none
            }
        Reduce { state, action in
            switch action {
            case .view(.onboard(.getStartButtonTapped)):
                state.view = .login()
                return .none
            case .view(.login(.login(.delegate(.nextScreen)))):
                state.view = .navigation()
                return .none
            case let .createUser(user, uid):
                return .run { _ in
                    try await chatClient.createUser(user, uid)
                }
            default: return .none
            }
        }
        
    }
    
    @ReducerBuilder<State, Action>
    var core: some Reducer<State, Action> {
        Scope(state: \.appDelegate, action: /Action.appDelegate) {
            AppDelegateLogic()
        }
        Scope(state: \.sceneDelegate, action: /Action.sceneDelegate) {
            SceneDelegateLogic()
        }
        Scope(state: \.view, action: /Action.view) {
            View()
        }
        AuthLogic()
    }
    
    public struct View: Reducer {
        public enum State: Equatable {
            case launch(LaunchLogic.State = .init())
            case onboard(OnboardLogic.State = .init())
            case login(LoginLogic.State = .init())
            case navigation(RootNavigationLogic.State = .init())
        }
        
        public enum Action: Equatable {
            case launch(LaunchLogic.Action)
            case onboard(OnboardLogic.Action)
            case login(LoginLogic.Action)
            case navigation(RootNavigationLogic.Action)
        }
        
        public var body: some ReducerOf<Self> {
            Scope(state: /State.launch, action: /Action.launch) {
                LaunchLogic()
            }
            Scope(state: /State.onboard, action: /Action.onboard) {
                OnboardLogic()
            }
            Scope(state: /State.login, action: /Action.login) {
                LoginLogic()
            }
            Scope(state: /State.navigation, action: /Action.navigation) {
                RootNavigationLogic()
            }
        }
    }
}

public struct AppView: View {
    let store: StoreOf<AppLogic>
    public init(store: StoreOf<AppLogic>) {
        self.store = store
    }
    public var body: some View {
        SwitchStore(store.scope(state: \.view, action: AppLogic.Action.view)) { initialState in
            switch initialState {
            case .launch:
                CaseLet(
                    /AppLogic.View.State.launch,
                    action: AppLogic.View.Action.launch,
                     then: LaunchView.init(store:)
                )
                
            case .onboard:
                CaseLet(
                    /AppLogic.View.State.onboard,
                     action: AppLogic.View.Action.onboard,
                     then: OnboardView.init(store:)
                )
                
            case .login:
                CaseLet(
                    /AppLogic.View.State.login,
                     action: AppLogic.View.Action.login,
                     then: LoginView.init(store:)
                )
                
            case .navigation:
                CaseLet(
                    /AppLogic.View.State.navigation,
                     action: AppLogic.View.Action.navigation,
                     then: RootNavigationView.init(store:)
                )
            }
        }
    }
}

