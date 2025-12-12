import SwiftUI

/// Lightweight image loader with in-memory cache to speed up avatar loads.
final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, UIImage>()
    
    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }
    
    func insert(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
    
    func load(url: URL) async throws -> UIImage {
        if let cached = image(for: url) { return cached }
        let (data, _) = try await URLSession.shared.data(from: url)
        if let img = UIImage(data: data) {
            insert(img, for: url)
            return img
        }
        throw URLError(.cannotDecodeContentData)
    }
}

struct RemoteImageView<Placeholder: View>: View {
    let url: URL?
    let placeholder: () -> Placeholder
    
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let uiImage = image {
                Image(uiImage: uiImage)
                    .resizable()
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            guard let url else { return }
            if let cached = ImageCache.shared.image(for: url) {
                image = cached
                return
            }
            if let loaded = try? await ImageCache.shared.load(url: url) {
                image = loaded
            }
        }
    }
}

