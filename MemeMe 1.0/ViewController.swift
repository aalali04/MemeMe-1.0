//
//  ViewController.swift
//  MemeMe 1.0
//
//  Created by Alaa Alali on 09/09/2019.
//  Copyright © 2019 Alaa Alali. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate,
UINavigationControllerDelegate, UITextFieldDelegate{

    //Mark: outlets
    @IBOutlet weak var imagePickerView: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var bottomTextField: UITextField!
    @IBOutlet weak var topToolBar: UIToolbar!
    @IBOutlet weak var bottomToolBar: UIToolbar!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    //Mark: the meme text attributes
    let memeTextAttributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key.strokeColor: UIColor.black,
        NSAttributedString.Key.foregroundColor: UIColor.white,
        NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
        NSAttributedString.Key.strokeWidth:  -3.5
    ]
    
    //Mark: Meme struct
    struct Meme {
        var topText: String
        var bottomText: String
        var originalImage: UIImage
        var memedImage: UIImage
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textSetUp(textField: topTextField, type: "TOP")
        self.topTextField.delegate = self
        
        textSetUp(textField: bottomTextField, type: "BOTTOM")
        self.bottomTextField.delegate = self
        
        //share button should be disabled until an image is uploaded
        self.shareButton.isEnabled = false
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        subscribeToKeyboardNotifications()
        
        //disable the camera button if the device doesn't support it
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)

    }

    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    
    //Mark: actions
    //picking image from the photo library
    @IBAction func pickAnImageFromAlbum(_ sender: Any) {
        pickAnImage(sourceType: .photoLibrary)
    }
    
    //picking image from the camera
    @IBAction func pickAnImageFromCamera(_ sender: Any) {
        pickAnImage(sourceType: .camera)
    }
    
    //sharing the meme
    @IBAction func shareAMeme(_ sender: Any) {
        let memedImage = generateMemedImage()
        let activityViewController = UIActivityViewController(activityItems: [memedImage], applicationActivities: nil)
        
        //check if device is ipad and set the popoverPresentationController
        if (UIDevice.current.userInterfaceIdiom == .pad)
        {
            if (activityViewController.responds(to: #selector(getter: UIViewController.popoverPresentationController)))
            {
                activityViewController.popoverPresentationController?.sourceView = super.view
            }
        }

        present(activityViewController, animated: true, completion: nil)
        
        //Completion handler
        activityViewController.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed:
            Bool, arrayReturnedItems: [Any]?, error: Error?) in
            if completed {
                self.save()
                return
            }
            if let shareError = error {
                print("error while sharing: \(shareError.localizedDescription)")
            }
        }
    }
    
    //the cancel button should return all values to default
    @IBAction func cancel(_ sender: Any) {
        imagePickerView.image = nil
        topTextField.text = "TOP"
        bottomTextField.text = "BOTTOM"
        self.shareButton.isEnabled = false
    }
    
    
    //allows the user to open from a souce type to pick an image
    func pickAnImage(sourceType: UIImagePickerController.SourceType) {
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        present(imagePicker, animated: true, completion: nil)
        
        //enable the share button after picking an image
        self.shareButton.isEnabled = true
    }
    
    //set the image in the image view
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.imagePickerView.image = image
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    //when the image controller cancels
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
        
        //the share button should be disabled if the image picker is cancelled
        if ( imagePickerView?.image == nil ) {
            self.shareButton.isEnabled = false
        }
    }
    
    //Mark: text setup function
    func textSetUp(textField: UITextField, type: String) {
        textField.defaultTextAttributes = memeTextAttributes
        textField.text = type
        textField.textAlignment = .center
    }

    //set up text to "" when start editing
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        if (textField.text == "TOP" || textField.text == "BOTTOM") {
            textField.text = ""
        }
    }
    
    //keyboard disapears after return
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true;
    }
    
    //subscribe to show/hide keyboard notification
    func subscribeToKeyboardNotifications() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    //unsubscribe to show/hide keyboard notification
    func unsubscribeFromKeyboardNotifications() {
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    //the bottom text field is properly shown while typing
    @objc func keyboardWillShow(_ notification:Notification) {
        
        if (self.bottomTextField.isFirstResponder) {
            view.frame.origin.y -= getKeyboardHeight(notification)
        }
    }
    
    //return the frame to its origin when the keyboard will hide
    @objc func keyboardWillHide(_ notification:Notification) {
        
        view.frame.origin.y = 0
    }
    
 
    //returns the keyboard height
    func getKeyboardHeight(_ notification:Notification) -> CGFloat {
        
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.cgRectValue.height
    }
    
    //generate the memed image
    func generateMemedImage() -> UIImage {
        
        // Hide toolbar and navbar
        self.topToolBar.isHidden = true
        self.bottomToolBar.isHidden = true
        
        // Render view to an image
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
        let memedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // Show toolbar and navbar
        self.topToolBar.isHidden = false
        self.bottomToolBar.isHidden = false
    
        return memedImage
    }
    
    //save the create the meme
    func save() {
        _ = Meme(topText: topTextField.text!, bottomText: bottomTextField.text!, originalImage: imagePickerView.image!, memedImage: generateMemedImage())
    }
}



