//
//  CreatePostView.swift
//  SocialMediaFeedApp
//
//  Created by Prince Lunagariya on 21/04/26.
//

import SwiftUI
import PhotosUI
import CoreData
import CoreLocation

struct CreatePostView: View {

    @Environment(\.managedObjectContext) private var viewContext

    @StateObject private var viewModel = CreatePostViewModel()
    @EnvironmentObject private var locationManager: LocationManager
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showDiscardAlert: Bool = false
    @State private var showLocationDeniedAlert: Bool = false
    @FocusState private var descriptionFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        imagePickerSection

                        descriptionSection

                        locationSection

                        postButton
                    }
                    .padding(16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.canSave {
                        Button("Clear") {
                            showDiscardAlert = true
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.red)
                    }
                }
            }
            .alert("Discard Post?", isPresented: $showDiscardAlert) {
                Button("Discard", role: .destructive) { viewModel.resetForm() }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("Are you sure you want to discard this post?")
            }
            .alert("Location Access Denied", isPresented: $showLocationDeniedAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("Location access is denied. Please go to Settings > Privacy > Location Services to enable it, or enter your location manually below.")
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onChange(of: photosPickerItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    do {
                        if let data = try await newItem.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                viewModel.selectedImage = image
                                viewModel.errorMessage = nil
                            }
                        } else {
                            await MainActor.run {
                                viewModel.errorMessage = "The selected image format is unsupported."
                            }
                        }
                    } catch {
                        await MainActor.run {
                            viewModel.errorMessage = "Failed to load image. Please try another one."
                        }
                    }
                }
            }
            .onChange(of: locationManager.locationString) { _, newVal in
                if !newVal.isEmpty && viewModel.locationText.isEmpty {
                    viewModel.locationText = newVal
                }
            }
            .onChange(of: viewModel.didSave) { _, saved in
                if saved {
                    viewModel.resetForm()
                    photosPickerItem = nil
                }
            }
            .onAppear {
                locationManager.requestLocation()
            }
        }
    }

    private var imagePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Photo", systemImage: "camera.fill")

            PhotosPicker(selection: $photosPickerItem, matching: .images) {
                ZStack {
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 240)
                            .clipped()
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    viewModel.selectedImage = nil
                                    photosPickerItem = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 26))
                                        .foregroundColor(.white)
                                        .shadow(radius: 4)
                                }
                                .padding(10)
                            }
                    } else {
                        ZStack {
                            LinearGradient(
                                colors: [Color(.systemGray5), Color(.systemGray6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            VStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.linearGradient(
                                        colors: [.accentColor, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                Text("Tap to Select Photo")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            viewModel.selectedImage == nil
                                ? Color(.systemGray4).opacity(0.6)
                                : Color.clear,
                            style: StrokeStyle(lineWidth: 1.5, dash: [6])
                        )
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Description", systemImage: "text.alignleft")

            TextField("What's on your mind?", text: $viewModel.descriptionText, axis: .vertical)
                .font(.system(size: 15))
                .lineLimit(4...8)
                .focused($descriptionFocused)
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack {
                Spacer()
                Text("\(viewModel.descriptionText.count) characters")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Location", systemImage: "mappin.and.ellipse")

            locationStatusRow
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Location")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                HStack(spacing: 10) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 16))
                        .foregroundColor(.accentColor)

                    TextField("Enter location manually…", text: $viewModel.locationText)
                        .font(.system(size: 15))
                        .submitLabel(.done)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private var locationStatusRow: some View {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            HStack(spacing: 8) {
                Image(systemName: "location.circle")
                    .foregroundColor(.accentColor)
                Text("Requesting location permission…")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

        case .authorizedWhenInUse, .authorizedAlways:
            if locationManager.isFetchingLocation {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Detecting your location…")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            } else if !locationManager.locationString.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 13))
                    Text("Auto-detected: \(locationManager.locationString)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Button("Use") {
                        viewModel.locationText = locationManager.locationString
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.accentColor)
                }
                .padding(10)
                .background(Color.green.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else if let error = locationManager.errorMessage {
                locationErrorRow(message: error)
            }

        case .denied, .restricted:
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 13))
                VStack(alignment: .leading, spacing: 6) {
                    Text("Location access is disabled.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Button("Open Settings to Enable Location") {
                        showLocationDeniedAlert = true
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.accentColor)
                }
            }
            .padding(10)
            .background(Color.orange.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

        @unknown default:
            EmptyView()
        }
    }

    private func locationErrorRow(message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 13))
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var postButton: some View {
        Button {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            viewModel.savePost(context: viewContext)
        } label: {
            HStack(spacing: 10) {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                }
                Text(viewModel.isSaving ? "Posting…" : "Post")
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                viewModel.canSave
                    ? LinearGradient(
                        colors: [.accentColor, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    : LinearGradient(
                        colors: [Color(.systemGray4), Color(.systemGray4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(
                color: viewModel.canSave ? Color.accentColor.opacity(0.4) : .clear,
                radius: 10, x: 0, y: 4
            )
        }
        .disabled(!viewModel.canSave || viewModel.isSaving)
        .padding(.top, 4)
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.linearGradient(
                    colors: [.accentColor, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            Text(title)
                .font(.system(size: 16, weight: .semibold))
        }
    }
}

#Preview {
    CreatePostView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(LocationManager())
}
