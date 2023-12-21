//
//  RegisterSetting.swift
//  Messenger
//
//  Created by Lambert on 2023/12/15.
//

import Foundation
import ComposableArchitecture
import SwiftUI

public struct RegisterSettingLogic: Reducer {
    public struct State: Equatable {
        @BindingState var email: String = ""
        @BindingState var fullName: String = ""
        @BindingState var password: String = ""
        var isActivityIndicatorVisible = false
        var isSignUpDisabled = true
        public init() {}
    }
    public enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case signUpButtonTapped
        case signInButtonTapped
        case failedToSignUp
        case delegate(Delegate)
        public enum Delegate: Equatable {
            case signInButtonTapped
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
            case .signInButtonTapped:
                return .run { send in
                    await send(.delegate(.signInButtonTapped))
                }
            case .signUpButtonTapped:
                state.isActivityIndicatorVisible = true
                return .run { [email = state.email, fullname = state.fullName, password = state.password] send in
                    guard let authUser = try await firebaseAuth.signUp(email, fullname, password)?.user else {
                        await send(.failedToSignUp)
                        return
                    }
                }
            case .failedToSignUp:
                state.isActivityIndicatorVisible = false
                return .none
                
            case .binding:
                state.isSignUpDisabled = state.email.isEmpty || state.fullName.isEmpty || state.password.isEmpty
                return .none
            default: return .none
            }
        }
    }
}


public struct RegisterSettingView: View {
    let store: StoreOf<RegisterSettingLogic>
    public init(store: StoreOf<RegisterSettingLogic>) {
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
                // text fields
                Spacer()
                VStack(spacing: 12) {
                    HStack {
                        // TODO: change image tint color when focus changed
                        Image(systemName: "envelope.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(appTint.gradient)
                            .padding(.horizontal, 10)
                        TextField("Enter your email", text: viewStore.$email)
                            .font(.headline)
                            .padding(.vertical, 12)
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal, 24)
                    
                    HStack {
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(appTint.gradient)
                            .padding(.horizontal, 10)
                        TextField("Enter your full name", text: viewStore.$fullName)
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
                
                ActivityButton(
                    title: "Sign Up",
                    isLoading: viewStore.isActivityIndicatorVisible,
                    isDisabled: viewStore.isSignUpDisabled
                ) {
                    viewStore.send(.signUpButtonTapped)
                }
                .padding(.vertical)
                .padding(.horizontal, 24)
                
                Spacer()
                
                
                Divider()
                HStack(spacing: 3) {
                    Text("Already have an account?")
                    Button {
                        viewStore.send(.delegate(.signInButtonTapped))
                    } label: {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .font(.footnote)
                .foregroundStyle(appTint.gradient)
                .padding(.vertical)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    RegisterSettingView(
        store: Store(
            initialState: RegisterSettingLogic.State()
        ) {
            RegisterSettingLogic()
        }
    )
}
