//
//  KeyLearningSheetView.swift
//  MSMA
//
//  Created by Pramuditha Muhammad Ikhwan on 08/05/25.
//
//
//  KeyLearningSheetView.swift
//  MSMA
//
//  Created by Pramuditha Muhammad Ikhwan on 08/05/25.
//

import SwiftUI
import PhotosUI
import SwiftData

// MARK: - Image Views

struct ImageDocumentation: View {
    let imageState: KeyLearningModel.ImageState
    
    var body: some View {
        switch imageState {
        case .loading:
            ProgressView()
        case .success(let image):
            image.image.resizable()
        case .failure(let error):
            Text("Error: \(error.localizedDescription)")
                .foregroundColor(.red)
                .font(.caption)
        case .empty:
            EmptyView()
        }
    }
}

struct RectangularImageDocumentation: View {
    let imageState: KeyLearningModel.ImageState
    
    var body: some View {
        ImageDocumentation(imageState: imageState)
            .scaledToFill()
            .frame(width: 320, height: 320)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
    }
}

// MARK: - Main View

struct EditableRectangularImageDocumentation: View {
    
    @State private var keyLearningStory: String = ""
    @State private var showSuccessAlert: Bool = false
    @State private var navigateToSavedStories = false
    @State private var showImagePicker = false
    @State private var showImageSourceDialog = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @ObservedObject var viewModel: KeyLearningModel
    
    @State private var navigateToProfile = false
        
    // Env for database
    @Environment(\.modelContext) private var modelContext
    
    // Env for dismiss
    @Environment(\.dismiss) private var dismiss
    
    // Identifier for quest
    let questId: UUID
    
    @EnvironmentObject var levelController: LevelProgressController

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Title and Instructions
                    VStack(alignment: .center, spacing: 8) {
                        Text(Strings.questStoryHeadingMsg)
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.top, 20)
                        
                        Text(Strings.questStoryPrompt)
                            .font(.body)
                            .padding(.bottom, 10)
                        
                        Text(Strings.questStoryBodyMsg)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 4)
                    }
                    .padding(.bottom, 10)

                    // Image & Picker
                    RectangularImageDocumentation(imageState: viewModel.imageState)
                    
                    Button {
                        showImageSourceDialog = true
                    } label: {
                        if case .empty = viewModel.imageState {
                            ZStack {
                                AddImage()
                            }
                        } else {
                            HStack(spacing: 8) {
                                Text("Pilih gambar lagi")
                                Image(systemName: "square.and.arrow.up")
                            }
                            .foregroundStyle(.blue)
                            .padding(.top, 5)
                        }
                    }
                    .confirmationDialog("Pilih Sumber Gambar", isPresented: $showImageSourceDialog) {
                        Button("Ambil Foto") {
                            imageSourceType = .camera
                            showImagePicker = true
                        }
                        Button("Pilih dari Album") {
                            imageSourceType = .photoLibrary
                            showImagePicker = true
                        }
                        Button("Batal", role: .cancel) {}
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Tulis ceritamu di bawah ini")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        // Text Editor
                        TextEditor(text: $keyLearningStory)
                            .padding(4)
                            .frame(width: 320, height: 100)
                            .background(
                                RoundedRectangle(
                                    cornerRadius: 10
                                )
                                .stroke(
                                    Color.gray.opacity(0.2),
                                    lineWidth: 1.5
                                )
                            )
                            .autocorrectionDisabled(true)
                            .fullScreenCover(isPresented: $showImagePicker) {
                                CameraAndPhotoPicker(sourceType: imageSourceType) { image in
                                    viewModel.setImage(image)
                                }
                            }
                        
                        //                        .sheet(isPresented: $showImagePicker) {
                        //                            CameraAndPhotoPicker(sourceType: imageSourceType) { image in
                        //                                viewModel.setImage(image)
                        //                            }
                        //                        }
                    }
                    .padding(.top, 10)

                    // Save Button
                    Button {
                        if case let .success(doc) = viewModel.imageState {
                            saveStory(image: doc.uiImage, storyText: keyLearningStory, modelContext: modelContext)
                            
                            showSuccessAlert = true
                        } else {
                            showSuccessAlert = false
                        }
                    } label: {
                        Text("Simpan")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(Color("milk"))
                            .frame(maxWidth: 320, maxHeight: 50)
                            .padding(.vertical, 20)
                            .background(Color("E0610B"))
                    }
                    .cornerRadius(20)
                    .alert("Berhasil menyimpan gambar", isPresented: $showSuccessAlert) {
                        Button("Oke") {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                navigateToProfile = true
                            }
                            dismiss()
                        }
                    }
                    .padding(.top, 10)
                }
                .padding()
            }
        }
    }
    
    func saveStory(image: UIImage, storyText: String, modelContext: ModelContext) {
        guard let imageData = image.jpegData(compressionQuality: 0.9) else { return }
        
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let uniqueName = UUID().uuidString + ".jpg"
        let fileURL = documentsURL.appendingPathComponent(uniqueName)
        
        do {
            try imageData.write(to: fileURL)
            
            let newStory = Story(imagePath: fileURL.path, storyText: storyText, questId: questId)
            modelContext.insert(newStory)
            
            // Give XP to user after saving story
            levelController.addXP(100)
        } catch {
            print("Gagal menyimpan gambar \(error.localizedDescription)")
        }
    }
}



