//
//  NativeLoginView.swift
//  NGA
//
//  客户端登录：nuke.php, app_id=1100, output=14, 密码 AES 加密
//

import SwiftUI

struct NativeLoginView: View {
    @ObservedObject var authService: AuthService
    @State private var name = ""
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
                    TextField("用户名 / 邮箱 / 手机号", text: $name)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()

                    SecureField("密码", text: $password)
                        .textContentType(.password)
                } header: {
                    Text("客户端登录")
                } footer: {
                    Text("支持用户名、邮箱、手机号或用户ID")
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
                    .disabled(name.isEmpty || password.isEmpty || isLoading)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("客户端登录")
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
                try await authService.loginNative(name: name, password: password)
            } catch {
                showError = true
            }
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        NativeLoginView(authService: AuthService.shared)
    }
}
