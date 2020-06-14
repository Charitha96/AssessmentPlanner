//
//  AddAssessmnet.swift
//  AssessmentPlannerApp
//
//  Created by Charitha Rajapakse on 4/10/20.
//  Copyright © 2020 Charitha Rajapakse. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import EventKit

class AddAssessmnet: UIViewController {
    
    @IBOutlet weak var assessmentNameTF         : UITextField!
    @IBOutlet weak var moduleNameTF             : UITextField!
    @IBOutlet weak var levelTF                  : UITextField!
    @IBOutlet weak var valueTF                  : UITextField!
    @IBOutlet weak var markAwardedTF            : UITextField!
    @IBOutlet weak var dueDateTF                : UITextField!
    @IBOutlet weak var addToCalendarSwitch      : UISwitchCustom!
    @IBOutlet weak var assessmentNotesTF        : UITextField!
    
    private var datePicker                      : UIDatePicker?
    var projects                                : [NSManagedObject] = []
    var editingMode                             : Bool = false
    
    let context             = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var datePickerVisible   = false
    let now                 = Date();
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDueDate()
        assessmentNameTF.becomeFirstResponder()
    }
    
    @IBAction func saveAssessment(_ sender: UIButton) {
        //validating the numbers and inputs
        if validate() && stringValidate() {
            var calenderID = ""
            var addedToCalendar = false
            let eventDeleted = false
            let addToCalendarFlag = Bool(addToCalendarSwitch.isOn)
            let eventStore = EKEventStore()
            let moduleName = moduleNameTF.text
            let projectName = assessmentNameTF.text
            let levelAssignment = levelTF.text!
            let valueAssignment = valueTF.text!
            let markAwarded = markAwardedTF.text!
            
            //converting from strings
            let levelAssignmentVal = Int(levelAssignment)
            let valueAssignmentVal = Double( valueAssignment )
            let markAwardedVal = Double( markAwarded )
           
            let notes = assessmentNotesTF.text!
            let endDate = NSDate()
            
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return
            }
            
            let managedContext = appDelegate.persistentContainer.viewContext
            let entity = NSEntityDescription.entity(forEntityName: "Assessment", in: managedContext)!
            
            var project = NSManagedObject()
            project = NSManagedObject(entity: entity, insertInto: managedContext)
            
            //adding to the calender
            if addToCalendarFlag {

                    if (EKEventStore.authorizationStatus(for: .event) != EKAuthorizationStatus.authorized) {
                        eventStore.requestAccess(to: .event, completion: {
                            granted, error in
                            calenderID = self.createEvent(eventStore, title: projectName!, startDate: self.now, endDate: endDate as Date)
                        })
                    } else {
                        calenderID = createEvent(eventStore, title: projectName!, startDate: now, endDate: (datePicker?.date)!)
                    }

                if calenderID != "" {
                    addedToCalendar = true
                }
            }
            
            // Handle event creation state
            if eventDeleted {
                addedToCalendar = false
            }
            
            //store data inside core data
            project.setValue(projectName, forKeyPath: "name")
            project.setValue(moduleName, forKeyPath: "moduleName")
            project.setValue(notes, forKeyPath: "notes")
            project.setValue(now, forKeyPath: "startDate")
            project.setValue(datePicker?.date, forKeyPath: "dueDate")
            project.setValue(levelAssignmentVal, forKey: "level")
            project.setValue(valueAssignmentVal, forKey: "value")
            project.setValue(markAwardedVal, forKey: "marks")
            project.setValue(addedToCalendar, forKeyPath: "addToCalendar")
            project.setValue(calenderID, forKey: "calenderID")
            print(project)
            
            do {
                try managedContext.save()
                //adding assessment data
                projects.append(project)
            } catch _ as NSError {
                let alert = UIAlertController(title: "Error", message: "An error occured while saving the project.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            //close popover when save has completed
            dismiss(animated: true, completion: nil)
            
        } else {
                let alert = UIAlertController(title: "Error", message: "Please fill the required fields.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
        }
    }
    
    // Creates an event in the EKEventStore
    func createEvent(_ eventStore: EKEventStore, title: String, startDate: Date, endDate: Date) -> String {
        let event = EKEvent(eventStore: eventStore)
        var identifier = ""
        
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            identifier = event.eventIdentifier
        } catch {
            let alert = UIAlertController(title: "Error", message: "Calendar event could not be created!", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        return identifier
    }
    
    //setting the due date
    func setDueDate(){
        datePicker = UIDatePicker()
        //today is the minimum date
        datePicker?.minimumDate = Date()
        datePicker?.datePickerMode = .date
        datePicker?.addTarget(self, action: #selector(AddAssessmnet.dateChanged(datePicker :)), for: .valueChanged)
        
        //get a tap gesture recognizer
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AddAssessmnet.viewTapped(gestureRecognizer:)))
        view.addGestureRecognizer(tapGestureRecognizer)
        dueDateTF.inputView = datePicker
        
        //Done button for the Date Picker
        let toolBar = UIToolbar()
        toolBar.barStyle = .default
        toolBar.isTranslucent = true
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(onClickDoneButton))
        toolBar.setItems([space, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        toolBar.sizeToFit()
        dueDateTF.inputAccessoryView = toolBar
        
    }
    //done button actions
    @objc func onClickDoneButton() {
        self.view.endEditing(true)
    }
    
    @objc func viewTapped(gestureRecognizer: UITapGestureRecognizer){
        view.endEditing(true)
    }
    
    @objc func dateChanged(datePicker: UIDatePicker){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        dueDateTF.text = dateFormatter.string(from: datePicker.date)
        
    }
    // Check if the required fields are empty or not
    func validate() -> Bool {
        
        if !(assessmentNameTF.text?.isEmpty)! && !(moduleNameTF.text?.isEmpty)! && !(levelTF.text?.isEmpty)! && !(valueTF.text?.isEmpty)! && !(dueDateTF.text?.isEmpty)! && !(assessmentNotesTF.text?.isEmpty)! {
            return true
        }
        return false
    }
    
    // Check if the INt text fields contain letters
    func stringValidate() -> Bool {
        let numericCharSet = CharacterSet.init(charactersIn: "abcdefghijklmnopqrstuvwxyz")

        if ((levelTF.text!.rangeOfCharacter(from: numericCharSet) != nil) || (valueTF.text!.rangeOfCharacter(from: numericCharSet) != nil) || (markAwardedTF.text!.rangeOfCharacter(from: numericCharSet) != nil)){
            print("Error contains strings")
            
            let alert = UIAlertController(title: "Wrong Input", message: "Level and Value should contaion numbers only.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return false
        }
        return true
    }
}

//button design
extension UIButton {
    open override func draw(_ rect: CGRect) {
        //provide custom style
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
    }
}
