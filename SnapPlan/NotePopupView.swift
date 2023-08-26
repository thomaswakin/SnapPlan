//
//  NotePopupView.swift
//  SnapPlan
//
//  Created by Thomas Akin on 8/26/23.
//

import SwiftUI

struct NotePopupView: View {
    @Binding var note: String
    @State private var isEditing = false
    @State private var editedNote: String = ""

    var body: some View {
        VStack {
            if isEditing {
                TextField("Edit Note", text: $editedNote)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Button("Save") {
                    note = editedNote  // Update the original note
                    isEditing = false  // Exit editing mode
                }
                .padding()
            } else {
                Text(note)  // Display the original note
                    .padding()
                Button("Edit") {
                    isEditing = true  // Enter editing mode
                    editedNote = note  // Populate the TextField with the original note
                }
                .padding()
            }
        }
    }
}
