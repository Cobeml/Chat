//
//  Created by Alex.M on 14.06.2022.
//

import SwiftUI

struct TextInputView: View {
    @Environment(\.chatTheme) private var theme
    @Binding var text: String
    var inputFieldId: UUID
    var style: InputViewStyle
    var availableInput: AvailableInputType

    @FocusState private var isFocused: Bool  // 👈 Replace GlobalFocusState

    var body: some View {
        TextField("", text: $text, axis: .vertical)
            .tint(Color(hex: "e8b717"))
            .focused($isFocused) // 👈 Use FocusState instead of customFocus
            .placeholder(when: text.isEmpty) {
                Text(style.placeholder)
                    .foregroundColor(theme.colors.buttonBackground)
            }
            .foregroundColor(.white)
            .padding(.vertical, 10)
            .padding(.leading, !availableInput.isMediaAvailable ? 12 : 0)
            .onTapGesture {
                isFocused = true
            }
    }
}


