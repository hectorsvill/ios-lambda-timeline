//
//  ImagePostViewController.swift
//  LambdaTimeline
//
//  Created by Spencer Curtis on 10/12/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit
import Photos


class ImagePostViewController: ShiftableViewController {
	
	private let filter = CIFilter(name: "CIColorControls")
	private let filterBlur = CIFilter(name: "CIBoxBlur")
	
	
	private let context = CIContext(options: nil)
//	private let blurcontext = CIContext(options: nil)
	
	var originalImage: UIImage?  {
		didSet { updateImage()
			
		}
	}
	
	@IBOutlet var saturationSlider: UISlider!
	@IBOutlet var brightnessSlider: UISlider!
	@IBOutlet var contrastSlider: UISlider!
	@IBOutlet var blurSlider: UISlider!
	
    override func viewDidLoad() {
        super.viewDidLoad()
        setImageViewHeight(with: 1.0)
        updateViews()
    }
	
	@IBAction func saturationSliderValueCahnged(_ sender: Any) {
		updateImage()
	}
	
	@IBAction func brightnessSliderValueCahnged(_ sender: Any) {
		updateImage()
	}
	
	@IBAction func contrastSliderValueCahnged(_ sender: Any) {
		updateImage()
	}
	
	@IBAction func blureSliderValueChanged(_ sender: Any) {
		if let image = imageView.image {
			imageBlur(byFiltering: image)
		}
	}

    func updateViews() {
        
        guard let imageData = imageData,
            let image = UIImage(data: imageData) else {
                title = "New Post"
                return
        }
        
        title = post?.title
        
        setImageViewHeight(with: image.ratio)
        
        imageView.image = image
        
        chooseImageButton.setTitle("", for: [])
    }
    
    private func presentImagePickerController() {
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            presentInformationalAlertController(title: "Error", message: "The photo library is unavailable")
            return
        }
        
        let imagePicker = UIImagePickerController()
        
        imagePicker.delegate = self
        
        imagePicker.sourceType = .photoLibrary

        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func createPost(_ sender: Any) {
        
        view.endEditing(true)
        
        guard let imageData = imageView.image?.jpegData(compressionQuality: 0.1),
            let title = titleTextField.text, title != "" else {
            presentInformationalAlertController(title: "Uh-oh", message: "Make sure that you add a photo and a caption before posting.")
            return
        }
        
        postController.createPost(with: title, ofType: .image, mediaData: imageData, ratio: imageView.image?.ratio) { (success) in
            guard success else {
                DispatchQueue.main.async {
                    self.presentInformationalAlertController(title: "Error", message: "Unable to create post. Try again.")
                }
                return
            }
            
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func chooseImage(_ sender: Any) {
        
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        switch authorizationStatus {
        case .authorized:
            presentImagePickerController()
        case .notDetermined:
            
            PHPhotoLibrary.requestAuthorization { (status) in
                
                guard status == .authorized else {
                    NSLog("User did not authorize access to the photo library")
                    self.presentInformationalAlertController(title: "Error", message: "In order to access the photo library, you must allow this application access to it.")
                    return
                }
                
                self.presentImagePickerController()
            }
            
        case .denied:
            self.presentInformationalAlertController(title: "Error", message: "In order to access the photo library, you must allow this application access to it.")
        case .restricted:
            self.presentInformationalAlertController(title: "Error", message: "Unable to access the photo library. Your device's restrictions do not allow access.")
            
        }
        presentImagePickerController()
    }
    
    func setImageViewHeight(with aspectRatio: CGFloat) {
        
        imageHeightConstraint?.constant = imageView.frame.size.width * aspectRatio
        
        view.layoutSubviews()
    }
    
    var postController: PostController!
    var post: Post?
    var imageData: Data?
    
	@IBOutlet weak var imageView: UIImageView!
	
	
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var chooseImageButton: UIButton!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var postButton: UIBarButtonItem!

}

extension ImagePostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        chooseImageButton.setTitle("", for: [])
        
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        
        originalImage = image
        setImageViewHeight(with: image.ratio)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}


extension ImagePostViewController {
	
	private func updateImage() {
		if let originalImage = originalImage {
			imageView.image = image(byFiltering: originalImage)
		} else {
			imageView.image = nil
		}
	}
	
	private func image(byFiltering image: UIImage) -> UIImage {
		guard let cgImage = image.cgImage else { return image }
		
		let ciImage = CIImage(cgImage: cgImage)
		filter?.setValue(ciImage, forKey: kCIInputImageKey)
		filter?.setValue(saturationSlider.value, forKey: kCIInputSaturationKey)
		filter?.setValue(brightnessSlider.value, forKey: kCIInputBrightnessKey )
		filter?.setValue(contrastSlider.value, forKey: kCIInputContrastKey)

		guard let outputImage = filter?.outputImage else {
			NSLog("Error outputing Image")
			return image
		}

		guard let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
			return  image
		}
		
		return UIImage(cgImage: outputCGImage)
	}
	
	private func imageBlur(byFiltering image: UIImage)  {
		guard let cgImage = image.cgImage else { return }
		
		let ciImage = CIImage(cgImage: cgImage)
		filterBlur?.setValue(ciImage, forKey: kCIInputImageKey)
		filterBlur?.setValue(blurSlider.value * 200, forKey: kCIInputRadiusKey)
		
		guard let blurImage = filterBlur?.outputImage else {
			NSLog("error with blurImage filter")
			return
		}
		
		guard let outputCGImage = context.createCGImage(blurImage, from: blurImage.extent) else {
			NSLog("error with blurcontext ")
			return
		}
		
		imageView.image = UIImage(cgImage: outputCGImage)
		
	}
	
	
	
	
}
