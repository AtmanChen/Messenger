//
//  Profile.swift
//  Messenger
//
//  Created by Lambert on 2023/12/19.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import PhotosUI


public enum PhotoPickerError: Error, Equatable {
    
}

public enum SettinsOption: Int, CaseIterable, Identifiable {
    case darkMode
    case activeStatus
    case accessibility
    case privacy
    case notifications
    
    public var title: String {
        switch self {
        case .darkMode: return "Dark mode"
        case .activeStatus: return "Active status"
        case .accessibility: return "Accessibility"
        case .privacy: return "Privacy and Safety"
        case .notifications: return "Notifications"
        }
    }
    public var imageName: String {
        switch self {
        case .darkMode: return "moon.circle.fill"
        case .activeStatus: return "message.badge.circle.fill"
        case .accessibility: return "person.circle.fill"
        case .privacy: return "lock.circle.fill"
        case .notifications: return "bell.circle.fill"
        }
    }
    
    public var imageBackgroundColor: Color {
        switch self {
        case .darkMode: return .primary
        case .activeStatus: return Color(.systemGreen)
        case .accessibility: return .primary
        case .privacy: return Color(.systemBlue)
        case .notifications: return Color(.systemPurple)
        }
    }
    public var id: Int { rawValue }
}

public struct ProfileLogic: Reducer {
    public struct State: Equatable {
        public init() {}
        var user: User?
        @BindingState var photoPickerItems: [PhotosPickerItem] = []
        var imageData: Data?
    }
    public enum Action: Equatable, BindableAction {
        case onTask
        case loadUserResponse(User?)
        case binding(BindingAction<State>)
        case loadTransferableResponse(TaskResult<Data?>)
        case logoutButtonTapped
    }
    @Dependency(\.firebaseAuth) var firebaseAuth
    @Dependency(\.chatClient) var chatClient
    public var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce {
            state,
            action in
            switch action {
            case .binding(\.$photoPickerItems):
                guard let photoPickerItem = state.photoPickerItems.first else {
                    return .none
                }
                return .run { send in
                    await send(.loadTransferableResponse(TaskResult {
                        try await photoPickerItem.loadTransferable(type: Data.self)
                    }))
                }
            case let .loadTransferableResponse(.success(.some(data))):
                state.imageData = data
                return .none
                
            case .onTask:
                return .run { send in
                    if let authUser = firebaseAuth.currentUser() {
                        await send(
                            .loadUserResponse(
                                try await chatClient.user(authUser.uid)
                            )
                        )
                    }
                }
                
            case let .loadUserResponse(user):
                state.user = user
                return .none
                
            case .logoutButtonTapped:
                return .run { _ in
                    try firebaseAuth.signOut()
                }
            default: return .none
            }
        }
    }
}

public struct ProfileView: View {
    let store: StoreOf<ProfileLogic>
    public init(store: StoreOf<ProfileLogic>) {
        self.store = store
    }
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                // header
                if let user = viewStore.user {
                    VStack {
                        PhotosPicker(
                            selection: viewStore.$photoPickerItems,
                            maxSelectionCount: 1,
                            selectionBehavior: .ordered,
                            matching: PHPickerFilter.images,
                            preferredItemEncoding: .current) {
                                ZStack(alignment: .bottomTrailing) {
                                    Group {
                                        if let imageData = viewStore.imageData,
                                           let image = UIImage(data: imageData) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .clipShape(Circle())
                                        } else {
                                            CircularProfileImageView(user: user, size: .xLarge)
                                        }
                                    }
                                    ZStack {
                                        Circle()
                                            .fill(Color(.systemBackground))
                                            .frame(width: 24, height: 24)
                                        Image(systemName: "camera.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 18, height: 18)
                                            .foregroundStyle(Color.primary.gradient)
                                    }
                                }
                            }
                        
                        
                        Text(user.fullname)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    // list
                    
                    List {
                        Section {
                            ForEach(SettinsOption.allCases) { option in
                                HStack {
                                    Image(systemName: option.imageName)
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .foregroundStyle(option.imageBackgroundColor.gradient)
                                    Text(option.title)
                                        .font(.subheadline)
                                }
                            }
                            
                        }
                        
                        Section {
                            Button("Log Out", role: .destructive) {
                                viewStore.send(.logoutButtonTapped)
                            }
                            Button("Delete Account", role: .destructive) {
                                
                            }
                        }
                    }
                }
            }
            .task { await viewStore.send(.onTask).finish() }
        }
    }
}

#Preview {
    ProfileView(
        store: Store(
            initialState: ProfileLogic.State(),
            reducer: { ProfileLogic() }
        )
    )
}
