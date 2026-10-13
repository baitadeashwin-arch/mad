//
//  CreateProfileView.swift
//  AntiSocial
//
//  Created by Alejandro Piguave on 2/1/22.
//  Updated for AntiSocial on 16/8/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct CreateProfileView: View {
    @State private var userName: String = ""
    @State private var userBio: String = ""
    @State private var datePickerSelection: Date = Date()
    @State private var genderSelection: String = ""
    @State private var orientationSelection: Orientation? = .both
    @State private var connectionModeSelection: ConnectionMode = .both
    @State private var collegeCommunity: String = ""
    @State private var selectedInterests: [String] = []
    @State private var collegeEmail: String = ""
    @State private var nearbyEnabled: Bool = false
    @State private var accountEmail: String = ""
    @State private var accountPassword: String = ""
    
    @State private var pictures: [PictureModel] = []
    @State private var image = UIImage()
    @State private var selectedContentType: UIImagePickerController.SourceType = .photoLibrary

    @State private var showImagePicker: Bool = false
    @State private var showContentTypeSheet: Bool = false
    @State private var showError: Bool = false
    @State private var showRemoveConfirmation: Bool = false
    @State private var showPermissionDenied: Bool = false

    @State private var confirmRemoveImageIndex: Int = 0
    @State private var droppedOutside: Bool = false

    @EnvironmentObject var contentViewModel: ContentViewModel
    @StateObject private var createProfileViewModel = CreateProfileViewModel()

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var partialRange: PartialRangeThrough<Date> {
        let eighteenYearsAgo = Calendar.current.date(byAdding: .year, value: -18, to: Date())!
        return ...eighteenYearsAgo
    }
    
    var body: some View {
        ProfileForm {
            PictureGridView(pictures: $pictures, droppedOutside: $droppedOutside, onAddedImageClick: { index in
                confirmRemoveImageIndex = index
                showRemoveConfirmation.toggle()
            }, onAddImageClick: {
                showContentTypeSheet.toggle()
            })
            .padding(.horizontal)

            ProfileSection("connection-mode") {
                ProfileRow {
                    Picker("", selection: $connectionModeSelection) {
                        ForEach(ConnectionMode.allCases, id: \.self) { mode in
                            Text(LocalizedStringKey(mode.titleKey)).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: .infinity)
                }
            }

            ProfileSection("college-community") {
                ProfileRow {
                    TextField("enter-college", text: $collegeCommunity)
                }
                ProfileRow {
                    TextField("College email (kept private)", text: $collegeEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }

            ProfileSection("Account") {
                ProfileRow {
                    TextField("Email", text: $accountEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                ProfileRow {
                    SecureField("Password", text: $accountPassword)
                }
            }

            ProfileSection("shared-interests") {
                VStack(alignment: .leading, spacing: 8) {
                    InterestChipsView(selectedInterests: $selectedInterests)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
            }

            ProfileSection("personal-info") {
                ProfileRow {
                    TextField("enter-your-name", text: $userName)
                }
                ProfileRow {
                    DatePicker(selection: $datePickerSelection, in: partialRange, displayedComponents: .date, label: { Text("pick-your-birthday") })
                }
            }

            ProfileSection("about-you") {
                ProfileRow {
                    ProfileTextEditor($userBio)
                }
            }

            ProfileSection("gender") {
                ProfileRow {
                    Picker("", selection: $genderSelection) {
                        ForEach(Constants.genderOptions, id: \.self) {
                            Text(LocalizedStringKey($0)).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: .infinity)
                }
            }

            ProfileSection("Nearby") {
                ProfileRow {
                    Toggle("Enable Nearby Mode", isOn: $nearbyEnabled)
                }
            }

            ProfileSection("i-am-interested-in") {
                ProfileRow {
                    Picker("", selection: $orientationSelection) {
                        ForEach(Orientation.allCases, id: \.self) {
                            Text(LocalizedStringKey($0.rawValue)).tag($0 as Orientation?)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: .infinity)
                }
            }

            Button {
                submitInformation()
            } label: {
                HStack(spacing: 12) {
                    Image("icons8-google-48")
                        .resizable()
                        .frame(width: 24, height: 24)

                    Text(accountEmail.isBlank ? "create-account-google" : "Create account")
                        .font(.body.weight(.semibold))
                }
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    isInformationIncomplete() ?
                        LinearGradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.4)], startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(colors: AppColor.appColors, startPoint: .leading, endPoint: .trailing)
                )
                .foregroundColor(.white)
                .cornerRadius(25)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .disabled(isInformationIncomplete())
            
        }
        .background(AppColor.lighterGray)
        .navigationBarTitle("create-profile")
        .showLoading(createProfileViewModel.isLoading)
        .onDrop(of: [UTType.text], delegate: DropOutsideDelegate(droppedOutside: $droppedOutside))
        .onChange(of: createProfileViewModel.signUpError, perform: { _ in
            if createProfileViewModel.signUpError != nil {
                showError = true
            }
        })
        .onChange(of: image, perform: { newValue in
            pictures.append(PictureModel.newPicture(newValue))
        })
        .onChange(of: createProfileViewModel.isSignUpComplete) { newValue in
            if newValue {
                self.presentationMode.wrappedValue.dismiss()
                contentViewModel.updateAuthState()
            }
        }
        .sheet(isPresented: $showContentTypeSheet) {
            ContentTypeView(onContentTypeSelected: { contentType in
                switch contentType {
                case .permissionDenied:
                    showPermissionDenied.toggle()
                    return
                case .contentType(let sourceType):
                    self.selectedContentType = sourceType
                    showImagePicker.toggle()
                    return
                }
            })
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: selectedContentType, selectedImage: $image)
        }
        .alert("camera-permission-denied", isPresented: $showPermissionDenied, actions: {}, message: { Text("user-must-grant-camera-permission") })
        .alert("error", isPresented: $showError, actions: {}, message: {
            Text(createProfileViewModel.signUpError ?? "")
        })
        .alert("remove-confirmation", isPresented: $showRemoveConfirmation, actions: {
            Button("yes", action: removePicture)
            Button("cancel", role: .cancel, action: {})
        })
    }

    private func removePicture() {
        pictures.remove(at: confirmRemoveImageIndex)
    }

    private func isInformationIncomplete() -> Bool {
        return userName.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 ||
               userName.count > 30 ||
               genderSelection.isEmpty ||
               orientationSelection == nil ||
               pictures.count < 2 ||
               selectedInterests.count < Constants.minInterestsCount ||
               selectedInterests.count > Constants.maxInterestsCount
    }

    private func submitInformation() {
        let isMale = Constants.genderOptions.firstIndex(of: genderSelection) == 0
        let orientation = orientationSelection ?? .both
        
        let profileData = CreateProfileModel(
            name: userName.trimmingCharacters(in: .whitespacesAndNewlines),
            birthDate: datePickerSelection,
            bio: userBio,
            isMale: isMale,
            orientation: orientation,
            pictures: pictures.map({ $0.picture }),
            connectionMode: connectionModeSelection,
            college: collegeCommunity.trimmingCharacters(in: .whitespacesAndNewlines),
            collegeEmail: collegeEmail.trimmingCharacters(in: .whitespacesAndNewlines),
            interests: selectedInterests,
            nearbyEnabled: nearbyEnabled,
            email: accountEmail.isBlank ? nil : accountEmail.trimmingCharacters(in: .whitespacesAndNewlines),
            password: accountPassword.isBlank ? nil : accountPassword
        )
        
        createProfileViewModel.signUp(profileData: profileData, controller: getRootViewController())
    }
}

// Interest Chips View
struct InterestChipsView: View {
    @Binding var selectedInterests: [String]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 8) {
            ForEach(Constants.availableInterests, id: \.self) { interest in
                let isSelected = selectedInterests.contains(interest)
                Button {
                    if isSelected {
                        selectedInterests.removeAll(where: { $0 == interest })
                    } else if selectedInterests.count < Constants.maxInterestsCount {
                        selectedInterests.append(interest)
                    }
                } label: {
                    Text(interest)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            isSelected ?
                                LinearGradient(colors: AppColor.appColors, startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [Color(UIColor.systemGray5), Color(UIColor.systemGray5)], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(isSelected ? .white : Color.primary)
                        .cornerRadius(16)
                }
            }
        }
    }
}

struct CreateProfileView_Previews: PreviewProvider {
    static var previews: some View {
        CreateProfileView()
    }
}
