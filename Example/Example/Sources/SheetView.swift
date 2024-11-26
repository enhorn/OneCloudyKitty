//
//  SheetView.swift
//  OneCloudyKitty
//
//  Created by Robin Enhorn on 2024-11-26.
//

import SwiftUI

struct SheetView<Content: View>: View {

    @State private var height: CGFloat = .zero
    private let content: () -> Content

    init(content: @escaping  () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .overlay { GeometryReader { Color.clear.preference(key: InnerHeightPreferenceKey.self, value: $0.size.height) } }
            .onPreferenceChange(InnerHeightPreferenceKey.self) { height = $0 }
            .presentationDetents([.height(height)])
    }

}

fileprivate struct InnerHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
