//
//  ActivityButton.swift
//  Messenger
//
//  Created by Lambert on 2023/12/20.
//

import SwiftUI

public struct ActivityButton: View {
    let title: String
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    public init(
        title: String,
        isLoading: Bool,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.black)
                } else {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(appTint.gradient, in: .rect(cornerRadius: 12))
            .contentShape(.rect)
            .opacity(isLoading || isDisabled ? 0.5 : 1.0)
        }
        .disabled(isLoading || isDisabled)
    }
}
