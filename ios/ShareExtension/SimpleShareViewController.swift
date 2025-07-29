import UIKit
import MobileCoreServices

class SimpleShareViewController: UIViewController {
    
    private let appGroupName = "group.com.sangdae.contentvault.dw002"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSLog("SimpleShareViewController: viewDidLoad called")
        
        view.backgroundColor = .systemBackground
        
        // Create UI
        let label = UILabel()
        label.text = "ContentVault Share"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Save", for: .normal)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        view.addSubview(saveButton)
        view.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -50),
            saveButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 30),
            
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 50),
            cancelButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 30)
        ])
        
        // Process shared content
        processSharedContent()
    }
    
    private func processSharedContent() {
        NSLog("SimpleShareViewController: processSharedContent called")
        
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem else {
            NSLog("SimpleShareViewController: No extension item found")
            return
        }
        
        guard let attachments = extensionItem.attachments else {
            NSLog("SimpleShareViewController: No attachments found")
            return
        }
        
        NSLog("SimpleShareViewController: Found \(attachments.count) attachments")
        
        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                NSLog("SimpleShareViewController: Processing URL attachment")
                attachment.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { [weak self] (data, error) in
                    if let url = data as? URL {
                        self?.saveURL(url.absoluteString)
                    }
                }
            } else if attachment.hasItemConformingToTypeIdentifier(kUTTypePlainText as String) {
                NSLog("SimpleShareViewController: Processing text attachment")
                attachment.loadItem(forTypeIdentifier: kUTTypePlainText as String, options: nil) { [weak self] (data, error) in
                    if let text = data as? String {
                        self?.saveURL(text)
                    }
                }
            }
        }
    }
    
    private func saveURL(_ urlString: String) {
        NSLog("SimpleShareViewController: saveURL called with: \(urlString)")
        
        if let userDefaults = UserDefaults(suiteName: appGroupName) {
            var sharedData: [[String: Any]] = userDefaults.object(forKey: "ShareMedia") as? [[String: Any]] ?? []
            
            let newItem: [String: Any] = [
                "path": urlString,
                "type": 0,
                "thumbnail": NSNull(),
                "duration": NSNull()
            ]
            
            sharedData.append(newItem)
            userDefaults.set(sharedData, forKey: "ShareMedia")
            userDefaults.synchronize()
            
            NSLog("SimpleShareViewController: Saved to UserDefaults successfully")
        }
    }
    
    @objc private func saveTapped() {
        NSLog("SimpleShareViewController: Save button tapped")
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    @objc private func cancelTapped() {
        NSLog("SimpleShareViewController: Cancel button tapped")
        extensionContext?.cancelRequest(withError: NSError(domain: "cancelled", code: 0))
    }
}