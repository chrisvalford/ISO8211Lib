//
//  CoreDataStack.swift
//  ISO8211Lib
//
//  Created by Christopher Alford on 27/7/22.
//

import Foundation
import CoreData

internal final class CoreDataStack {
    
    static let shared = CoreDataStack()
    
    init() { }
    
    deinit {
        self.saveContext()
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.


         */
        let bundle = Bundle.module //Bundle(for: type(of: self))
        debugPrint(bundle.bundleIdentifier)
        guard let modelURL = bundle.url(forResource: "ISO8211Lib", withExtension: "momd") else {
            fatalError("Cannot find model in bundle!")
        }
        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)
        let container = NSPersistentContainer(name: "ISO8211Lib", managedObjectModel: managedObjectModel!)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                debugPrint("Unable to create coredata stack")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            else {
                container.viewContext.automaticallyMergesChangesFromParent = true
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
