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

            // The next three view modifiers were added in iOS 17.

            // This embeds the PhotosPicker in this app instead of
            // rendering it in a sheet controlled by a separate process.
            .photosPickerStyle(.inline)

            // This hides the the "Clear" button (deselects all)
            // and the "Done" button (closes picker when not inline.
            // It seems there is no need to disable any of these
            // if the navigation bar and toolbar are hidden (see below).
            // .photosPickerDisabledCapabilities(.selectionActions)

            // This hides the PhotosPicker navigation bar and toolbar.
            // The navigation bar contains the Clear and Done buttons
            // and a segmented Picker to select "Photos" or "Albums".
            // The toolbar contains the "Options" button and some text.
            // When the first argument is `.hidden`,
            // the `edges` argument specifies the edges to hide.
            .photosPickerAccessoryVisibility(.hidden, edges: .all)

            // .ignoresSafeArea()
            // The height of each row is 120.
            .frame(height: 240) // two rows

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
