//
//  LoginView.swift
//  NGA
//
//  Created by William Chen on 3/10/26.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var authService: AuthService
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            AppTheme.Colors.homeBackground
                .ignoresSafeArea()
            
            Form {
                Section {
                    TextField("用户名", text: $username)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()

                    SecureField("密码", text: $password)
                        .textContentType(.password)
                }

                Section {
                    Button(action: signIn) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("登录")
                            }
                            Spacer()
                        }
                    }
                    .disabled(username.isEmpty || password.isEmpty || isLoading)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("登录")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    dismiss()
                }
            }
        }
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(authService.errorMessage ?? "登录失败")
        }
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                dismiss()
            }
        }
    }

    private func signIn() {
        isLoading = true
        Task {
            do {
                try await authService.login(username: username, password: password)
            } catch {
                showError = true
            }
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        LoginView(authService: AuthService.shared)
    }
}
