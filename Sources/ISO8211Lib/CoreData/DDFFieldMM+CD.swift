//
//  File.swift
//  
//
//  Created by Christopher Alford on 31/7/22.
//

import CoreData
import Foundation
import ISO8211LibWrapper

extension DDFFieldMM {

    // Save as a DDFFieldMO
    func insert() {
        let stack = CoreDataStack.shared
        stack.persistentContainer.performBackgroundTask({ (context) in
            let mo = NSEntityDescription.insertNewObject(forEntityName: "DDFFieldMO", into: context) as? DDFFieldMO
            mo?.name = self.name
            mo?.text = self.text

            // toFieldDefinition  DDFFieldDefinitionMO
            if self.fieldDefinition != nil {
                guard let fieldDefinitionMO = NSEntityDescription.insertNewObject(forEntityName: "DDFFieldDefinitionMO", into: context) as? DDFFieldDefinitionMO else {
                    debugPrint("DDFFieldMO: Unable to create DDFFieldDefinitionMO")
                    return
                }
                fieldDefinitionMO.name = self.fieldDefinition.name
                mo?.toFieldDefinition = fieldDefinitionMO
            }
            do {
                try context.save()
            } catch let error as NSError {
                debugPrint("DDFFieldMO: \(error.localizedDescription)")
            }
        })
    }
}
