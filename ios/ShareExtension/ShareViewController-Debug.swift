import UIKit
import Social

class ShareViewControllerDebug: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create a simple debug UI
        view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "ContentVault Share Extension"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let debugLabel = UILabel()
        debugLabel.numberOfLines = 0
        debugLabel.font = .systemFont(ofSize: 12)
        debugLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Save", for: .normal)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        view.addSubview(debugLabel)
        view.addSubview(saveButton)
        view.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            debugLabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            debugLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            debugLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            saveButton.topAnchor.constraint(equalTo: debugLabel.bottomAnchor, constant: 20),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -50),
            
            cancelButton.topAnchor.constraint(equalTo: debugLabel.bottomAnchor, constant: 20),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 50)
        ])
        
        // Debug: Check what we received
        var debugText = "Debug Info:\n"
        
        if let item = extensionContext?.inputItems.first as? NSExtensionItem {
            debugText += "Found extension item\n"
            
            if let attachments = item.attachments {
                debugText += "Attachments: \(attachments.count)\n"
                
                for (index, attachment) in attachments.enumerated() {
                    debugText += "\nAttachment \(index):\n"
                    
                    if attachment.hasItemConformingToTypeIdentifier("public.url") {
                        debugText += "- Has URL\n"
                    }
                    if attachment.hasItemConformingToTypeIdentifier("public.plain-text") {
                        debugText += "- Has plain text\n"
                    }
                }
            }
        } else {
            debugText += "No extension items found\n"
        }
        
        debugLabel.text = debugText
    }
    
    @objc func saveTapped() {
        // Save logic here
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    @objc func cancelTapped() {
        extensionContext?.cancelRequest(withError: NSError(domain: "cancelled", code: 0))
    }
}