//
//  DetailViewController.swift
//  MasterDetailV2
//
//  Created by Philip Trwoga on 27/03/2018.
//  Copyright © 2020 Charitha Rajapakse. All rights reserved.
//

import UIKit
import CoreData

class TaskTableViewCell: UITableViewCell {
    
    @IBOutlet weak var taskNameLbl                              : UILabel!
    @IBOutlet weak var taskNotes                                : UILabel!
    @IBOutlet weak var progressBar                              : UIProgressView!
    @IBOutlet weak var taskProgressCircle                       : ProgressBarCircular!
    @IBOutlet weak var reaminLbl                                : UILabel!
    @IBOutlet weak var remainingDateCountLbl                    : UILabel!
    
    let colors                                                  : Colors = Colors()
    let calculations                                            : DateCalculator = DateCalculator()
}

class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var assessmentSelectedNameLbl            : UILabel!
    @IBOutlet weak var assessmentModuleNameLbl              : UILabel!
    @IBOutlet weak var assessmentLevelLbl                   : UILabel!
    @IBOutlet weak var assessmentValueLbl                   : UILabel!
    @IBOutlet weak var assessmentNotesTxtView               : UITextView!
    @IBOutlet weak var assessmentProgressBar                : ProgressBarCircular!
    @IBOutlet weak var assessmentRemainingDaysProgressBar   : RemainingDaysCircular!
    
    @IBOutlet weak var addTaskBtnPress                      : UIBarButtonItem!
    @IBOutlet weak var editTaskBtnPress                     : UIBarButtonItem!
    
    @IBOutlet weak var tableView                            : UITableView!
     var managedObjectContext                               : NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var fetchRequest                                        : NSFetchRequest<Task>!
    var tasks                                               : [Task]!
    
    let colors                                              : Colors = Colors()
    let calculations                                        : DateCalculator = DateCalculator()
    var totalTaskPercentage = 10.0
    static var progressVariable                             : Int?
    
    var assessment: Assessment? {
        didSet {
            configureView()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //disable buttons before selecting an assessment
        addTaskBtnPress.isEnabled = false
        editTaskBtnPress.isEnabled = false
        
        configureView()
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    //setting up the view
    func configureView() {
        if let project = assessment {
            if let nameLabel = assessmentSelectedNameLbl {
                nameLabel.text = project.name
                //enable toolbar buttons
                addTaskBtnPress.isEnabled = true
                //editTaskBtnPress.isEnabled = true

            }
            if let moduleLabel = assessmentModuleNameLbl {
                moduleLabel.text = "Module : \(project.moduleName ?? "")"
            }
            if let levelLabel = assessmentLevelLbl {
                levelLabel.text = "Level : \(String(project.level))"
            }
            if let valueLabel = assessmentValueLbl {
                valueLabel.text = "Value : \(String(project.value))"
            }
            if let notesTxtView = assessmentNotesTxtView {
                notesTxtView.text = "Notes: \(project.notes ?? "")"
            }
            
            //progress circle data getting
            let progressPercentage = (MasterViewController.assessmentProgressVariable)
            let finalPer = (progressPercentage ?? 0)
            //progress circle draw
            DispatchQueue.main.async {
                let colours = self.colors.getProgressGradient(finalPer, negative: true)
                self.assessmentProgressBar.customSubtitle = "Completed"
                self.assessmentProgressBar?.startGradientColor = colours[0]
                self.assessmentProgressBar?.endGradientColor = colours[1]
                self.assessmentProgressBar?.progress = CGFloat(finalPer)/100

            }
            
            //get the no of remaingn days
            let calendar = Calendar.current
            //current date
            let date = Date()
            // Replace the hour (time) of both dates with 00:00
            let date1 = calendar.startOfDay(for: date)
            let date2 = calendar.startOfDay(for: assessment?.dueDate ?? date)
            let remain = calendar.dateComponents([.day], from: date1, to: date2)
            
            //remaining Days Circle
            if((remain.day!) < 0){
                DispatchQueue.main.async {
                    let colours = self.colors.getProgressGradient((Int(0.0)), negative: true)
                    self.assessmentRemainingDaysProgressBar.customSubtitle = "Expired"
                    self.assessmentRemainingDaysProgressBar?.startGradientColor = colours[0]
                    self.assessmentRemainingDaysProgressBar?.endGradientColor = colours[1]
                    self.assessmentRemainingDaysProgressBar?.progress = CGFloat(((Double(0.0))/100))
                }
            } else {
                DispatchQueue.main.async {
                    let colours = self.colors.getProgressGradient((remain.day! ), negative: true)
                    self.assessmentRemainingDaysProgressBar.customSubtitle = "Days Left"
                    self.assessmentRemainingDaysProgressBar?.startGradientColor = colours[0]
                    self.assessmentRemainingDaysProgressBar?.endGradientColor = colours[1]
                    self.assessmentRemainingDaysProgressBar?.progress = CGFloat(((Double(remain.day!))/100))
                }
            }
        }
    }
    //sending assessment data to the segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addTask"
        {
            if let AddNewTaskPopup = segue.destination as? AddNewTaskPopup{
                AddNewTaskPopup.currentAssessment = assessment
            }
        }
        //edit task
        if segue.identifier == "editTask"
        {
            if let EditNewTaskPopup = segue.destination as? AddNewTaskPopup{
                let indexPath = tableView.indexPathForSelectedRow!
                let object = fetchedResultsController.object(at: indexPath)
                EditNewTaskPopup.editingTask = object as Task
                EditNewTaskPopup.currentAssessment = assessment
            }
            
        }
    }
  
    // MARK: - tableView delegate section
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = self.fetchedResultsController.managedObjectContext
            context.delete(self.fetchedResultsController.object(at: indexPath))
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    //enable edit task button when task is selected
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        editTaskBtnPress.isEnabled = true
        let task = fetchedResultsController.object(at: indexPath)
        
    }
    
    //sending data to the table view cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "taskCell", for: indexPath) as! TaskTableViewCell
        let task = fetchedResultsController.object(at: indexPath)
        
        cell.taskNameLbl!.text = task.name
        cell.taskNotes!.text = task.notes
        
        let tasks = (assessment?.tasks!.allObjects as! [Task])
        let projectProgress = calculations.getProjectProgress(tasks)
        DetailViewController.progressVariable = projectProgress
        
        let finalPer = (projectProgress)
        //change overall assignment when new task added
        DispatchQueue.main.async {
            let colours = self.colors.getProgressGradient(finalPer, negative: true)
            self.assessmentProgressBar.customSubtitle = "Completed"
            self.assessmentProgressBar?.startGradientColor = colours[0]
            self.assessmentProgressBar?.endGradientColor = colours[1]
            self.assessmentProgressBar?.progress = CGFloat(finalPer)/100
        }
        
        let tProgress = Int(task.progress)
        //setting colors to the progress circle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        let colours = cell.colors.getProgressGradient(tProgress, negative: true)
            self.totalTaskPercentage = Double(task.progress)
            cell.taskProgressCircle?.startGradientColor = colours[0]
            cell.taskProgressCircle?.endGradientColor = colours[1]
            cell.taskProgressCircle?.progress = CGFloat(tProgress)/100
        }
        
        //get the no of remaingn days
        let calendar = Calendar.current
        //current date
        let date = Date()
        // Replace the hour (time) of both dates with 00:00
        let date1 = calendar.startOfDay(for: date)
        let dateDue = calendar.startOfDay(for: task.dueDate!)
        let dateStart = calendar.startOfDay(for: task.startDate!)
        //remainng days left
        let remain = calendar.dateComponents([.day], from: date1, to: dateDue)
        
        if((remain.day!) < 5 && (remain.day!) > 0){
            cell.remainingDateCountLbl!.text = String(remain.day!)
            cell.reaminLbl!.textColor = UIColor.red
            cell.remainingDateCountLbl!.textColor = UIColor.red
        } else if (remain.day!) <= 0{
            cell.remainingDateCountLbl!.text = "Task Expired"
            cell.reaminLbl!.textColor = UIColor.red
            cell.remainingDateCountLbl!.textColor = UIColor.red
        } else{
            cell.remainingDateCountLbl!.text = String(remain.day!)
        }
        
       //getting a percentage of remaining days
        let allDays = calendar.dateComponents([.day], from: dateStart, to: dateDue)
        let remeaingPercentageDates = (Double(remain.day!) / Double(allDays.day!))
        print(remeaingPercentageDates)
        
        //setting up the progress bar minus from 100 to get the remining
        cell.progressBar?.setProgress(Float(remeaingPercentageDates), animated: true)
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, indexPath: IndexPath) {
    }
   
    //MARK: - fetch results controller
    var _fetchedResultsController: NSFetchedResultsController<Task>? = nil
    
    var fetchedResultsController: NSFetchedResultsController<Task> {
        
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
                
        let currentAssessment  = self.assessment
        let request:NSFetchRequest<Task> = Task.fetchRequest()
        
        request.fetchBatchSize = 20
        //sort alphabetically
        let taskNameSortDescriptor = NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))
        
        request.sortDescriptors = [taskNameSortDescriptor]
        //we want the tasks for the fromAssessment - via the relationship
        if(self.assessment != nil){
            let predicate = NSPredicate(format: "fromAssessment = %@", currentAssessment!)
            request.predicate = predicate
        }
        else {
            //just do all tasks for the first assessment in the list
            //replace this to get the first assessment in the record
            let predicate = NSPredicate(format: "assessment = %@","Pink Floyd")
            request.predicate = predicate
        }
        let frc = NSFetchedResultsController<Task>(
            fetchRequest: request,
            managedObjectContext: managedObjectContext,
            sectionNameKeyPath: #keyPath(Task.assessment),
            cacheName:nil)
        frc.delegate = self
        _fetchedResultsController = frc
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        
        return frc as! NSFetchedResultsController<NSFetchRequestResult> as! NSFetchedResultsController<Task>
    }
    
      //MARK: - fetch results table view functions
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    //must have a NSFetchedResultsController to work
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case NSFetchedResultsChangeType(rawValue: 0)!:
            // iOS 8 bug - Do nothing if we get an invalid change type.
            break
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            self.configureCell(tableView.cellForRow(at: indexPath!)!, indexPath: newIndexPath!)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
            
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
}
