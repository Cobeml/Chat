//
//  PlanInviteAttachmentFullPageView.swift
//  ExyteChat
//

import SwiftUI
import AVKit

struct PlanInviteAttachmentFullPageViewss: View {
    let attachment: Attachment

    var body: some View {
        if attachment.type == .image {
            CachedAsyncImage(url: attachment.full, urlCache: .imageCache) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                default:
                    ActivityIndicator()
                }
            }
        } else if attachment.type == .video {
            VideoView(viewModel: VideoViewModel(attachment: attachment))
        } else {
            Rectangle()
                .foregroundColor(Color.gray)
                .frame(minWidth: 100, minHeight: 100)
                .frame(maxHeight: 200)
                .overlay {
                    Text("Unknown")
                }
        }
    }
}


struct PlanInviteAttachmentFullPageView: View {
    let user: User
    let attachment: Attachment

    var body: some View {
        GeometryReader { geometry in
            Text("Height: \(geometry.size.height), SafeAreaTop: \(geometry.safeAreaInsets.top)")
                .hidden()
            if #available(iOS 17.0, *) {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        VideoPlayerInviteUserView(
                            user: user,
                            attachment: attachment,
                            onAccept: {
//                                threadsViewModel.updateConversationStatus(id: conversation.id, status: "approved") {
//                                    approvalTask()
//                                }
                            },
                            onReject: {
//                                threadsViewModel.updateConversationStatus(id: conversation.id, status: "denied") {
//                                    Task {
//                                        await viewModel.getData()
//                                    }
//                                    dismissAction()
//                                }
                            })
                                .frame(height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom) // don't mess with this
                                .clipped()
                    }
                }
                .edgesIgnoringSafeArea(.all)
            }
        }
    }
}

struct VideoPlayerInviteUserView: View {
    let user: User
    let attachment: Attachment
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        ZStack(alignment: .trailing) {
            // MARK: - Video Player Section
            TTVideoPlayerView(url:  attachment.full)
                .edgesIgnoringSafeArea(.all)
                .scaleEffect(1.13)
                .padding(.bottom, 77)
                .overlay(
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .allowsHitTesting(false)
                )

            // MARK: - Bottom UI Overlay
            VStack(spacing: 0) {
                Spacer()

                // MARK: - Location & Description Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack  {
                        // Location Info
                        HStack(spacing: 8) {
                            Text("Blank Street")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                            Text("$ $ ")
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }

                    // Description Text
                    Text("Cozy coffee shop with amazing pastries and garden seating")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                        .padding(.top, -10)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)

                // MARK: - User Info Section
                HStack {
                    HStack(alignment: .center, spacing: 60) {
                        // Profile Image
                        ProfilePictureView(user: user)
                            .frame(width: 90, height: 90)  // Profile picture size
                            .padding(.horizontal, -10)  // Negative padding might cause overlap

                        // User Details
                        VStack(alignment: .leading, spacing: 8) {
                            // Occupation Pill
                            PillView(text: "Compatible", color: .yellow)

                            // Compatible Pill
                            IconPillView(text: "Occupation", color: .white, icon: "briefcase")

                            ButtonPillView(text: "Add +1", color: .white)
                        }
                        .frame(width: 90)
                        .padding(.top, -20)

                        //Spacer()
                        VStack{
                            Text("08:30 PM Tonight")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                            Button(action: onAccept) {
                                Text("Accept")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.black)
                                    .frame(width: 80, height: 28)
                                    .background(Color.white)
                                    .cornerRadius(14)
                            }
                            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                            .padding(.top, 4)

                            Button(action: onReject) {
                                Text("Decline")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.black)
                                    .frame(width: 80, height: 28)
                                    .background(Color.white)
                                    .cornerRadius(14)
                            }
                            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                            .padding(.top, 4)
                        }

                    }
                    .padding(.leading, 20)  // Left padding for user info

                    Spacer()
                }
                .padding(.bottom, 100)  // Space from bottom of screen
            }
        }
    }
}

struct ProfilePictureView: View {
    let user: User
    @State private var offsetY: CGFloat = 0

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            AvatarView(url: user.avatarURL, avatarSize: 40)
                .contentShape(Circle())
            HStack(spacing: 4) {
                Text(user.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 40)
    }
}

struct PillView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .frame(height: 28)
            .frame(minWidth: 120)
            .padding(.horizontal, 12)
            .background(color.opacity(0.3))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
    }
}

struct IconPillView: View {
    let text: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.white)
            Text(text)
        }
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .frame(height: 28)
            .frame(minWidth: 120)
            .padding(.horizontal, 12)
            .background(color.opacity(0))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
    }
}

struct ButtonPillView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .frame(height: 28)
            .frame(minWidth: 120)
            .padding(.horizontal, 12)
            .background(color.opacity(0.0))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(
                        Color.white.opacity(0.5),
                        lineWidth: 2
                    )
            )
    }
}


struct TTVideoPlayerView: View {
    let url: URL
    @State private var player: AVPlayer
    @State private var isVisible: Bool = false

    init(url: URL) {
        self.url = url
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                // Only start playing if the view is visible
                if isVisible {
                    startPlaying()
                }
            }
            .onDisappear {
                pausePlayer()
            }
            // Use onChange to track visibility changes
            .onChange(of: isVisible) { newValue in
                if newValue {
                    startPlaying()
                } else {
                    pausePlayer()
                }
            }
            // Add visibility detection
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: VisibilityPreferenceKey.self,
                        value: geometry.frame(in: .global)
                    )
                }
            )
            .onPreferenceChange(VisibilityPreferenceKey.self) { frame in
                let isCurrentlyVisible = !frame.isEmpty && frame.intersects(UIScreen.main.bounds)
                if isCurrentlyVisible != isVisible {
                    DispatchQueue.main.async {
                        isVisible = isCurrentlyVisible
                    }
                }
            }
    }

    private func startPlaying() {
        player.seek(to: .zero)
        player.play()

        // Setup video looping
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            if isVisible {
                player.play()
            }
        }
    }

    private func pausePlayer() {
        player.pause()
        NotificationCenter.default.removeObserver(
            self,
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
    }
}

struct VisibilityPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
