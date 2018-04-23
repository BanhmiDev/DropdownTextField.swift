//
//  DropdownTextField.swift
//  dropdowntextfield
//
//  Created by Son on 12.04.18.
//  Copyright © 2018 Son Nguyen. All rights reserved.
//

import UIKit

enum DropdownTextFieldMode {
    case Single
    case Dual
}

class DropdownTextField: UITextField, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // Defaults to single mode
    var dropdownMode = DropdownTextFieldMode.Single
    
    // Triggers notification on value change if not nil
    var notificationName: String?
    
    // The data set
    var items = [String]()
    
    // Dismiss bar on top of the UIPickerView
    lazy var inputToolbar: UIToolbar = {
        var toolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.isTranslucent = true
        toolbar.sizeToFit()
        
        var doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(inputToolbarDonePressed))
        var spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        toolbar.setItems([spaceButton, doneButton], animated: false)
        toolbar.isUserInteractionEnabled = true
        return toolbar
    }()
    
    // Main UIPickerView displaying the data set
    lazy var pickerView: UIPickerView = {
        var picker = UIPickerView()
        picker.autoresizingMask = UIViewAutoresizing(rawValue: UIViewAutoresizing.RawValue(UInt8(UIViewAutoresizing.flexibleWidth.rawValue)|UInt8(UIViewAutoresizing.flexibleHeight.rawValue)))
        picker.showsSelectionIndicator = true
        picker.delegate = self
        picker.dataSource = self
        return picker
    }()
    
    @objc func inputToolbarDonePressed() {
        if items.count > 0 {
            // Actual input text
            self.text = selectedItem()
            
            // Update image (if dual mode)
            if dropdownMode == DropdownTextFieldMode.Dual {
                let preview = UIImageView(image: UIImage(named: items[selectedRow()].lowercased()))
                preview.frame = CGRect(x: 0, y: 0, width: self.bounds.width/2, height: self.bounds.height)
                preview.contentMode = .scaleAspectFit
                preview.clipsToBounds = true
                self.leftView = preview
            }
            
            // Notification
            if notificationName != nil {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: notificationName!), object: self, userInfo: ["value": selectedItem(), "row": selectedRow()])
            }
        }
        endEditing(true)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // UITextField modification
        self.delegate = self
        self.inputAccessoryView = inputToolbar
        self.inputView = pickerView
        
        // Dropdown icon
        self.rightViewMode = .always
        toggleArrow(isExpanded: false)
    }
    
    func toggleArrow(isExpanded: Bool) {
        if isExpanded {
            self.rightView = UIImageView(image: UIImage(named: "ic_arrow_drop_up"))
        } else {
            self.rightView = UIImageView(image: UIImage(named: "ic_arrow_drop_down"))
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        toggleArrow(isExpanded: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        toggleArrow(isExpanded: false)
    }
    
    func setSelection(row: Int) {
        // Prevent under/overflow
        if row < items.count {
            // Update actual text
            self.text = items[row]
            
            // Update image (if dual mode)
            if dropdownMode == DropdownTextFieldMode.Dual {
                let preview = UIImageView(image: UIImage(named: items[row].lowercased()))
                preview.frame = CGRect(x: 0, y: 0, width: self.bounds.width/2, height: self.bounds.height)
                preview.contentMode = .scaleAspectFit
                preview.clipsToBounds = true
                self.leftView = preview
            }
            
            // Update picker
            self.pickerView.selectRow(row, inComponent: 0, animated: true)
        }
    }
    
    func setItems(_ items: [String]) {
        // Refresh data list and select the first itemf
        self.items = items
        pickerView.reloadAllComponents()
        
        // Data list should not be empty
        if items.count > 0 {
            pickerView.selectRow(0, inComponent: 0, animated: true)
            self.text = items[0]
            
            // Additionally display image in dual mode
            if dropdownMode == DropdownTextFieldMode.Dual {
                let preview = UIImageView(image: UIImage(named: items[0].lowercased()))
                preview.frame = CGRect(x: 0, y: 0, width: self.bounds.width/2, height: self.bounds.height)
                preview.contentMode = .scaleAspectFit
                preview.clipsToBounds = true
                self.leftViewMode = .always
                self.leftView = preview
            }
        } else {
            self.text = "N/A"
        }
    }
    
    func selectedItem() -> String {
        return items[selectedRow()]
    }
    
    func selectedRow() -> Int {
        return pickerView.selectedRow(inComponent: 0)
    }
    
    // MARK: - UITextField overrides
    override func caretRect(for position: UITextPosition) -> CGRect {
        return CGRect.zero
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return false
    }
    
    // MARK: - UIPickerView delegate, datasource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        if dropdownMode == DropdownTextFieldMode.Single {
            // Label only
            let label = UILabel()
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true
            label.backgroundColor = .clear
            label.font = UIFont.systemFont(ofSize: 18.0)
            label.text = items[row]
            return label
        } else {
            // Image + Label (Image is named after the label text)
            let image = UIImageView(image: UIImage(named: items[row].lowercased()))
            let dualView = UIView()
            let label = UILabel()
            label.adjustsFontSizeToFitWidth = true
            label.backgroundColor = .clear
            label.font = UIFont.boldSystemFont(ofSize: 18.0)
            label.text = items[row]
            dualView.addSubview(label)
            dualView.addSubview(image)
            
            // Fit according to text length
            label.sizeToFit()
            
            // Component helpers
            let rowHeight = pickerView.rowSize(forComponent: 0).height
            let rowMiddle = pickerView.frame.width/2
            let labelHalf = label.frame.width/2
            
            // Additionally adds -10 as padding
            let imageFrame: CGRect = CGRect(x: rowMiddle - labelHalf - rowHeight - 10, y: 0, width: rowHeight, height: rowHeight)
            image.frame = imageFrame
            let labelFrame: CGRect = CGRect(x: rowMiddle - labelHalf, y: 0, width: label.frame.width, height: rowHeight)
            label.frame = labelFrame
            
            return dualView
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return items[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return items.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.text = items[row]
    }
}

