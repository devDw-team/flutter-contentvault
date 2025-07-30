import UIKit
import Social
import MobileCoreServices

class ShareViewController: SLComposeServiceViewController {
    
    private let appGroupName = "group.com.sangdae.contentvault.dw002"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ShareExtension: viewDidLoad")
    }
    
    override func isContentValid() -> Bool {
        print("ShareExtension: isContentValid")
        return true
    }
    
    override func didSelectPost() {
        print("ShareExtension: didSelectPost")
        
        // Process the shared content
        if let item = extensionContext?.inputItems.first as? NSExtensionItem {
            print("ShareExtension: Found extension item")
            
            if let attachments = item.attachments {
                print("ShareExtension: Found \(attachments.count) attachments")
                
                for attachment in attachments {
                    // Log all available type identifiers
                    print("ShareExtension: Attachment registeredTypeIdentifiers: \(attachment.registeredTypeIdentifiers)")
                    
                    if attachment.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                        print("ShareExtension: Processing URL attachment")
                        attachment.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { [weak self] (data, error) in
                            if let error = error {
                                print("ShareExtension: Error loading URL: \(error)")
                            }
                            if let url = data as? URL {
                                print("ShareExtension: Got URL: \(url.absoluteString)")
                                self?.saveURL(url.absoluteString)
                            } else {
                                print("ShareExtension: URL data type: \(type(of: data))")
                            }
                        }
                    } else if attachment.hasItemConformingToTypeIdentifier(kUTTypePlainText as String) {
                        print("ShareExtension: Processing text attachment")
                        attachment.loadItem(forTypeIdentifier: kUTTypePlainText as String, options: nil) { [weak self] (data, error) in
                            if let error = error {
                                print("ShareExtension: Error loading text: \(error)")
                            }
                            if let text = data as? String {
                                print("ShareExtension: Got text: \(text)")
                                // Check if text contains a URL
                                if text.contains("youtube.com") || text.contains("youtu.be") {
                                    print("ShareExtension: Detected YouTube URL in text")
                                }
                                self?.saveURL(text)
                            } else {
                                print("ShareExtension: Text data type: \(type(of: data))")
                            }
                        }
                    } else {
                        print("ShareExtension: Unknown attachment type")
                        // Try to load as text anyway
                        if attachment.hasItemConformingToTypeIdentifier(kUTTypePlainText as String) {
                            attachment.loadItem(forTypeIdentifier: kUTTypePlainText as String, options: nil) { [weak self] (data, error) in
                                if let text = data as? String {
                                    print("ShareExtension: Fallback - got text: \(text)")
                                    self?.saveURL(text)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Delay completion to allow async operations to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
    
    private func saveURL(_ urlString: String) {
        print("ShareExtension: saveURL called with: \(urlString)")
        
        if let userDefaults = UserDefaults(suiteName: appGroupName) {
            var sharedData: [[String: Any]] = userDefaults.object(forKey: "ShareMedia") as? [[String: Any]] ?? []
            
            // Determine content type from URL
            var contentType = "web"
            if urlString.contains("threads.net") {
                contentType = "threads"
            } else if urlString.contains("twitter.com") || urlString.contains("x.com") {
                contentType = "twitter"
            } else if urlString.contains("youtube.com") || urlString.contains("youtu.be") {
                contentType = "youtube"
            }
            
            let newItem: [String: Any] = [
                "path": urlString,
                "type": contentType,  // Use string type instead of integer
                "thumbnail": "",      // Empty string instead of NSNull
                "duration": 0         // Default value instead of NSNull
            ]
            
            sharedData.append(newItem)
            userDefaults.set(sharedData, forKey: "ShareMedia")
            userDefaults.synchronize()
            
            print("ShareExtension: Saved to UserDefaults - total items: \(sharedData.count)")
            
            // Verify save
            if let verifyData = userDefaults.object(forKey: "ShareMedia") as? [[String: Any]] {
                print("ShareExtension: Verified - ShareMedia has \(verifyData.count) items")
                for (index, item) in verifyData.enumerated() {
                    print("ShareExtension: Item \(index): \(item)")
                }
            }
        } else {
            print("ShareExtension: Failed to access UserDefaults with app group: \(appGroupName)")
        }
    }
    
    override func configurationItems() -> [Any]! {
        return []
    }
}