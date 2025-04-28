//
//  Created by Alex.M on 08.07.2022.
//

import SwiftUI

struct MessageTimeView: View {

    let text: String
    let isCurrentUser: Bool
    var chatTheme: ChatTheme

    var body: some View {
        Text(text)
            .font(.system(size: 8, weight: .medium, design: .default))
            .foregroundColor(isCurrentUser ? chatTheme.colors.myMessageTime : Color.white.opacity(0.6))
    }
}

struct MessageTimeWithCapsuleView: View {

    let text: String
    let isCurrentUser: Bool
    var chatTheme: ChatTheme

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium, design: .default))
            .foregroundColor(chatTheme.colors.timeCapsuleForeground)
            .opacity(0.8)
            .padding(.top, 4)
            .padding(.bottom, 4)
            .padding(.horizontal, 8)
            .background {
                Capsule()
                    .fill(chatTheme.colors.timeCapsuleBackground)
            }
    }
}

