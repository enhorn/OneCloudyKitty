//
//  NewEntityFormView.swift
//  OneCloudyKitty
//
//  Created by Robin Enhorn on 2024-11-26.
//

import SwiftUI

struct NewEntityFormView: View {

    @Binding var newItem: GenericFormView.NewItem
    @FocusState private var isFocused: Bool

    let onCancel: () -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack {

            HStack {
                Button("Cancel", action: onCancel)
                Spacer()
                Button("Add", action: onAdd).bold()
            }.padding(.bottom, 16)

            TextField("Title", text: $newItem.title).focused($isFocused)
            DatePicker("Date", selection: $newItem.date)
            Stepper("Integer: \(newItem.integer)", value: $newItem.integer, in: .init(uncheckedBounds: (0, 10)), step: 1)

            HStack(spacing: 16) {
                Slider(value: $newItem.double, in: .init(uncheckedBounds: (0, 1)))
                Text("\(String(format: "%.2f", newItem.double))")
            }

        }
        .padding(16)
        .onAppear { isFocused = true }
    }

}
