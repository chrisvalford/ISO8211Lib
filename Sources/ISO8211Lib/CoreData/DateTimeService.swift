//
//  DateTimeService.swift
//  ISO8211Lib
//
//  Created by Christopher Alford on 27/7/22.
//

import CoreData
import Foundation

public class DateTimeService {
    
    public init(){}
    
    public func create(_ date: Date, note: String) {
        
        let stack = CoreDataStack.shared
        stack.persistentContainer.performBackgroundTask({ (context) in
            let dateTime = NSEntityDescription.insertNewObject(forEntityName: "DateTime", into: context) as? DateTime
            dateTime?.date = date
            dateTime?.note = note
            
            do {
                try context.save()
            } catch let error as NSError {
                print("DateTimeService::create() error : \(error.localizedDescription)")
            }
        })
    }
    
    public func get(_ completion: @escaping (DateTime?) -> Void) {
        
        let stack = CoreDataStack.shared
        stack.persistentContainer.performBackgroundTask({ (context) in
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "DateTime")
            do {
                let results = try context.fetch(request) as! [DateTime]
                if results.count > 0 {
                    completion(results.first! as DateTime)
                }
                
            } catch let error as NSError {
                print("DateTimeService::get() error : \(error.localizedDescription)")
            }
            completion(nil)
        })
    }
    
    public func update(_ date: Date, note: String) {
        
        self.get { (dateTime) in
            dateTime?.date = date
            dateTime?.note = note
            do {
                try dateTime?.managedObjectContext?.save()
            } catch let error {
                print("DateTimeService::update() error : \(error.localizedDescription)")
            }
        }
    }
    
    public func delete() {
        // Delete all records, there shouldn't be more than one!
        let stack = CoreDataStack.shared
        stack.persistentContainer.performBackgroundTask({ (context) in
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "DateTime")
            request.includesPropertyValues = false //only fetch the managedObjectID
            do {
                let results = try context.fetch(request) as! [NSManagedObject]
                for dateTime in results {
                    context.delete(dateTime)
                }
            } catch let error as NSError {
                print("DateTimeService::delete: %@", error.localizedDescription)
            }
        })
    }
}
