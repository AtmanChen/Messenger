//
//  CircularProfileImageView.swift
//  Messenger
//
//  Created by Lambert on 2023/12/20.
//

import SwiftUI
import Kingfisher
import FirebaseAuth

public enum ProfileImageSize {
    case xxSmall
    case xSmall
    case small
    case medium
    case large
    case xLarge
    
    public var dimension: CGFloat {
        switch self {
        case .xxSmall: return 28
        case .xSmall: return 32
        case .small: return 40
        case .medium: return 56
        case .large: return 64
        case .xLarge: return 80
        }
    }
}

public struct CircularProfileImageView: View {
    let user: User
    let size: ProfileImageSize
    public init(user: User, size: ProfileImageSize) {
        self.user = user
        self.size = size
    }
    public var body: some View {
        KFImage.url(URL(string: user.profileImageUrl ?? ""), cacheKey: user.profileImageUrl ?? "")
            .placeholder {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: size.dimension, height: size.dimension)
                    .foregroundStyle(Color(.systemGray4).gradient)
            }
            .resizable()
            .scaledToFill()
            .frame(width: size.dimension, height: size.dimension)
            .clipShape(Circle())
        
    }
}
