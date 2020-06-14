//
//  AddTask.swift
//  AssessmentPlannerApp
//
//  Created by Charitha Rajapakse on 4/10/20.
//  Copyright © 2020 Charitha Rajapakse. All rights reserved.
//

import UIKit
import CoreData
import EventKit

class AddNewTaskPopup: UIViewController {

    @IBOutlet weak var taskName1Lbl             : UITextField!
    @IBOutlet weak var taskStart1Lbl            : UITextField!
    @IBOutlet weak var taskDue1Lbl              : UITextField!
    @IBOutlet weak var taskNotes1Lbl            : UITextField!
    @IBOutlet weak var labelAssessmentName      : UILabel!
    @IBOutlet weak var progressValueTF          : UILabel!
    @IBOutlet weak var addNotificationSwitch    : UISwitchCustom!
    @IBOutlet weak var progressSlider1          : UISlider!
    
    var currentAssessment                       :Assessment?
    private var datePickerDue                   : UIDatePicker?
    private var datePickerStart                 : UIDatePicker?
    var projects                                : [NSManagedObject] = []
    var editingMode                             : Bool = false
    let calculations                            : DateCalculator = DateCalculator()
    var selectedAssessment                      : Assessment?
    static var newTaskChangeProgress            : Int?
    let formatter                               : Formatter = Formatter()
    static var assessmentProgressEdit           : Int?
    
    var datePickerVisible   = false
    var progressVal         = 0
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    //Add notification
    let notificationCenter = UNUserNotificationCenter.current()
    
    var editingTask: Task? {
        didSet {
            // Update the view.
            editingMode = true
            configureView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDueDate()
        //setting the name up for the task add page
        labelAssessmentName.text = currentAssessment?.name
        
        //editing changes
        configureView()
        
        // Configure Notification Center
        notificationCenter.delegate = self as? UNUserNotificationCenterDelegate
    }
    
    func configureView() {
        
        if editingMode {
            self.navigationItem.title = "Edit Task"
            self.navigationItem.rightBarButtonItem?.title = "Edit"
        }
        
        if let task = editingTask {
            if let textField = taskName1Lbl {
                textField.text = task.name
            }
            if let textView = taskNotes1Lbl {
                textView.text = task.notes
            }
            if let labelStart = taskStart1Lbl {
                labelStart.text = formatDate(task.startDate!)
            }
            if let datePickerStart = datePickerStart {
                datePickerStart.date = task.startDate!
            }
            
            if let label = taskDue1Lbl {
                label.text = formatDate(task.dueDate!)
            }
            if let datePicker = datePickerDue {
                datePicker.date = task.dueDate!
            }
            if let uiSwitch = addNotificationSwitch {
                uiSwitch.setOn(task.addNotification, animated: true)
            }
            if let slider = progressSlider1 {
                slider.value = task.progress
            }
            if let labelProgress = progressValueTF {
                labelProgress.text = "\(Int(task.progress))"
            }
        }
    }
    
    public func formatDate(_ date: Date) -> String {
        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy HH:mm"
        return dateFormatter.string(from: date)
    }

    @IBAction func saveAlbum(_ sender: UIButton) {
        //validating the label inputs
        if validate(){
            let taskName = taskName1Lbl.text
            let dueDate = datePickerDue?.date
            let startDate = datePickerStart?.date
            let progress = progressValueTF?.text
            let notes = taskNotes1Lbl.text
            
            //converting from strings
            let progressVal : Float = Float(progress!)!
            //adding reminders to tasks
            let addNotificationFlag = Bool(addNotificationSwitch.isOn)
            
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return
            }
         
            let managedContext = appDelegate.persistentContainer.viewContext
            let entity = NSEntityDescription.entity(forEntityName: "Task", in: managedContext)!
            
            var task = NSManagedObject()
            
            if editingMode {
                task = (editingTask as? Task)!
            } else {
                task = NSManagedObject(entity: entity, insertInto: managedContext)
            }
            
            //adding reminder to task
            if addNotificationFlag {
                let eventStore = EKEventStore()
                
                eventStore.requestAccess(to: EKEntityType.reminder, completion: {
                 granted, error in
                 if (granted) && (error == nil) {
                   print("granted \(granted)")

                   let reminder:EKReminder = EKReminder(eventStore: eventStore)
                    reminder.title = self.taskName1Lbl.text
                    reminder.priority = 2
                    reminder.notes = self.taskNotes1Lbl.text

                    let alarmTime = self.datePickerDue?.date
                    let alarm = EKAlarm(absoluteDate: alarmTime!)
                   reminder.addAlarm(alarm)

                   reminder.calendar = eventStore.defaultCalendarForNewReminders()
                   do {
                     try eventStore.save(reminder, commit: true)
                   } catch {
                     print("Cannot save")
                     return
                   }
                   print("Reminder saved")
                 }
                })
            }
            
            //saving in to core data
            task.setValue(taskName, forKeyPath: "name")
            task.setValue(notes, forKeyPath: "notes")
            task.setValue(startDate, forKeyPath: "startDate")
            task.setValue(dueDate, forKeyPath: "dueDate")
            task.setValue(addNotificationFlag, forKeyPath: "addNotification")
            task.setValue(progressVal, forKey: "progress")
            print(task)
            
            currentAssessment?.addToTasks((task as? Task)!)
            
            do {
                try managedContext.save()
                //adding task to the assignment
                projects.append(task)
            } catch _ as NSError {
                let alert = UIAlertController(title: "Error", message: "An error occured while saving the task.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            let alert = UIAlertController(title: "Error", message: "Please fill the required fields.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        //remove the popup
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addNotificationSwitch(_ sender: UISwitch) {
        
    }
    
    func requestAuthorization(completionHandler: @escaping (_ success: Bool) -> ()) {
        // Request Authorization
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { (success, error) in
            if let error = error {
                print("Request Authorization Failed (\(error), \(error.localizedDescription))")
            }
            completionHandler(success)
        }
    }
   
    //progress slider value set 
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        let currentValue = Int(sender.value)
        progressValueTF.text = String(currentValue)
    }
    
    //setting the due date
    func setDueDate(){
        //getting the due date from assignment to set as the maxium date
        let maximumDate = currentAssessment?.dueDate
       
        //due date
        datePickerDue = UIDatePicker()
        //today is the minimum date
        datePickerDue?.minimumDate = Date()
        datePickerDue?.maximumDate = maximumDate
        datePickerDue?.datePickerMode = .date
        datePickerDue?.addTarget(self, action: #selector(AddNewTaskPopup.dateChanged(datePickerDue :)), for: .valueChanged)
        
        //start date
        datePickerStart = UIDatePicker()
        //today is the minimum date
        datePickerStart?.minimumDate = Date()
        datePickerStart?.maximumDate = maximumDate
        datePickerStart?.datePickerMode = .date
        datePickerStart?.addTarget(self, action: #selector(AddNewTaskPopup.dateChangedStart(datePickerStart :)), for: .valueChanged)
        
        //get a tap gesture recognizer
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(AddAssessmnet.viewTapped(gestureRecognizer:)))
        view.addGestureRecognizer(tapGestureRecognizer)
        
        taskStart1Lbl.inputView = datePickerStart
        taskDue1Lbl.inputView = datePickerDue
        
        //Done button for the Date Picker
        let toolBar = UIToolbar()
        toolBar.barStyle = .default
        toolBar.isTranslucent = true
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(onClickDoneButton))
        toolBar.setItems([space, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        toolBar.sizeToFit()
        taskDue1Lbl.inputAccessoryView = toolBar
        taskStart1Lbl.inputAccessoryView = toolBar
        
    }
    //done button actions
    @objc func onClickDoneButton() {
        self.view.endEditing(true)
    }
    
    @objc func viewTapped(gestureRecognizer: UITapGestureRecognizer){
        view.endEditing(true)
    }
    
    @objc func dateChanged(datePickerDue: UIDatePicker){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        taskDue1Lbl.text = dateFormatter.string(from: datePickerDue.date)
    }
    
    @objc func dateChangedStart(datePickerStart: UIDatePicker){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        taskStart1Lbl.text = dateFormatter.string(from: datePickerStart.date)
    }
    
    // Check if the required fields are empty or not
    func validate() -> Bool {
        if !(taskName1Lbl.text?.isEmpty)! && !(taskNotes1Lbl.text?.isEmpty)! &&  !(taskDue1Lbl.text?.isEmpty)! && !(taskStart1Lbl.text?.isEmpty)! {
            return true
        }
        return false
    }
}
