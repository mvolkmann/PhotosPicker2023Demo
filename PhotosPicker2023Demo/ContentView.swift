import PhotosUI
import SwiftUI

// Holding Images inside custom struct instances enables making them Hashable.
struct MyImage: Hashable {
    let image: Image
    let id = UUID()

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ContentView: View {
    @State var images: [MyImage] = []
    @State var imageSelections: [PhotosPickerItem] = []

    private static let gridItem = GridItem(
        .fixed(100),
        spacing: 10,
        alignment: .topLeading
    )
    private let gridItems: [GridItem] = Array(repeating: gridItem, count: 3)

    private func loadItems(
        from items: [PhotosPickerItem]
    ) async throws {
        images = []
        do {
            for item in items {
                if let image = try await loadItem(from: item) {
                    images.append(MyImage(image: image))
                }
            }
        } catch {
            print("loadMultipleSelections error:", error)
        }
    }

    private func loadItem(
        from item: PhotosPickerItem?
    ) async throws -> Image? {
        guard let data = try await item?.loadTransferable(
            type: Data.self
        ) else { return nil }

        guard let uiImage = UIImage(data: data) else { return nil }

        return Image(uiImage: uiImage)
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Tap photos to select them.").fontWeight(.bold)
            PhotosPicker(
                selection: $imageSelections,
                selectionBehavior: .continuous,
                matching: .images,
                preferredItemEncoding: .current,
                photoLibrary: .shared()
            ) {
                Image(systemName: "photo")
                    .imageScale(.large)
            }
            .photosPickerStyle(.inline)
            .ignoresSafeArea()
            .photosPickerDisabledCapabilities(.selectionActions)
            .photosPickerAccessoryVisibility(.hidden, edges: .all)
            .frame(height: 200)

            if !images.isEmpty {
                Divider().frame(height: 3).background(.tint)
                Text("Selected photos:").fontWeight(.bold)
                LazyVGrid(columns: gridItems, alignment: .leading) {
                    ForEach(images, id: \.self) { image in
                        image.image.resizable().scaledToFit()
                    }
                }
            }

            Spacer()
        }
        .onChange(of: imageSelections) {
            Task {
                try await loadItems(from: imageSelections)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
