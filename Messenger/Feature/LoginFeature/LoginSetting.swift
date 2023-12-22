//
//  LoginSetting.swift
//  Messenger
//
//  Created by Lambert on 2023/12/15.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import FirebaseAuth

public struct LoginSettingLogic: Reducer {
    public struct State: Equatable {
        @BindingState var email: String = ""
        @BindingState var password: String = ""
        var isActivityIndicatorVisible = false
        var isLoginDisabled = true
        public init() {}
    }
    
    public enum Action: Equatable, BindableAction {
        case forgetPasswordButtonTapped
        case loginButtonTapped
        case loginFailed
        case signUpButtonTapped
        case binding(BindingAction<State>)
        case delegate(Delegate)
        
        public enum Delegate: Equatable {
            case nextScreen
            case registerSetting
            case forgetPasswordSetting
        }
    }
    
    @Dependency(\.firebaseAuth) var firebaseAuth
    @Dependency(\.chatClient) var chatClient
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce {
            state,
            action in
            switch action {
            case .forgetPasswordButtonTapped:
                return .run { send in
                    await send(.delegate(.forgetPasswordSetting), animation: .default)
                }
                
            case .loginButtonTapped:
                // verify login information
                state.isActivityIndicatorVisible = true
                return .run { [email = state.email, password = state.password] send in
                    if try await firebaseAuth.signIn(email, password) == nil {
                        await send(.loginFailed)
                    }
                } catch: { error, send in
                    print("Login Failed: \(error)")
                }
                
            case .loginFailed:
                state.isActivityIndicatorVisible = false
                return .none
                
            case .signUpButtonTapped:
                return .run { send in
                    await send(.delegate(.registerSetting), animation: .default)
                }
                
            case .delegate:
                return .none
                
            case .binding:
                state.isLoginDisabled = state.email.isEmpty || state.password.isEmpty
                return .none
            }
        }
    }
}

public struct LoginSettingView: View {
    let store: StoreOf<LoginSettingLogic>
    public init(store: StoreOf<LoginSettingLogic>) {
        self.store = store
    }
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                Spacer()
                // logo image
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .foregroundStyle(appTint.gradient)
                Spacer()
                // text fields
                VStack(spacing: 12) {
                    HStack {
                        // TODO: change image tint color when focus changed
                        Image(systemName: "envelope.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(appTint.gradient)
                            .padding(.horizontal, 10)
                        TextField("Enter your name", text: viewStore.$email)
                            .font(.headline)
                            .padding(.vertical, 12)
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal, 24)
                    
                    HStack {
                        Image(systemName: "lock.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(appTint.gradient)
                            .padding(.horizontal, 10)
                        SecureField("Enter your password", text: viewStore.$password)
                            .font(.headline)
                            .padding(.vertical, 12)
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal, 24)
                }
                // forgot password
                Button {
                    
                } label: {
                    Text("Forgot Password?")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .padding(.top)
                        .padding(.trailing, 28)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                // login button
                ActivityButton(
                    title: "Login",
                    isLoading: viewStore.isActivityIndicatorVisible,
                    isDisabled: viewStore.isLoginDisabled
                ) {
                    viewStore.send(.loginButtonTapped)
                }
                .padding(.vertical)
                .padding(.horizontal, 24)
                // fackbook login
                HStack {
                    Rectangle()
                        .frame(width: UIScreen.main.bounds.width / 2 - 40, height: 0.5)
                    Text("OR")
                        .font(.footnote)
                        .fontWeight(.semibold)
                    Rectangle()
                        .frame(width: UIScreen.main.bounds.width / 2 - 40, height: 0.5)
                    
                }
                .foregroundStyle(.gray)
                Button {
                    
                } label: {
                    HStack {
                        Image(systemName: "person.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(appTint.gradient)
                        Text("Continue with Facebook")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundStyle(appTint.gradient)
                    }
                }
                .padding(.top, 8)
                
                Spacer()
                
                Divider()
                HStack(spacing: 3) {
                    Text("Don't have an account?")
                    Button {
                        viewStore.send(.delegate(.registerSetting))
                    } label: {
                        Text("Sign Up")
                            .fontWeight(.semibold)
                    }
                }
                .font(.footnote)
                .foregroundStyle(appTint.gradient)
                .padding(.vertical)
            }
        }
    }
}


#Preview {
    LoginSettingView(
        store: Store(
            initialState: LoginSettingLogic.State()
        ) {
            LoginSettingLogic()
        }
    )
}
