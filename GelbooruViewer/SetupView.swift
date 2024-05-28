//
//  SetupView.swift
//  GelbooruViewer
//
//  Created by Amrit Bhogal on 27/05/2024.
//

import SwiftUI

struct SetupView: View {
    @State private var apiKey: String = ""
    @State private var userID: String = ""
    @State private var saveError: (any Error)? = nil
    @State private var showAlert = false
    var onSave: (String, String) throws -> Void

    var body: some View {
        VStack {
            TextField("API Key", text: $apiKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            TextField("User ID", text: $userID)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button("Save") {
                do {
                    try onSave(apiKey, userID)
                    saveError = nil
                    showAlert = false
                } catch {
                    saveError = error
                    showAlert = true
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(saveError?.localizedDescription ?? "An unknown error occurred"), dismissButton: .default(Text("Ok")))
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding()
    }
}


#Preview {
    SetupView(onSave: { _, _ in })
}
