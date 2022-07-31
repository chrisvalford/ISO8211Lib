//
//  DDFSubfieldDefinition+CD.swift
//  
//
//  Created by Christopher Alford on 30/7/22.
//

import CoreData
import Foundation
import ISO8211LibWrapper

extension DDFSubfieldDefinitionMM {

    // Save as a DDFSubfieldDefinitionMO
    func insert() {
        let stack = CoreDataStack.shared
        stack.persistentContainer.performBackgroundTask({ (context) in
            let mo = NSEntityDescription.insertNewObject(forEntityName: "DDFSubfieldDefinitionMO", into: context) as? DDFSubfieldDefinitionMO
            mo?.name = self.name
            mo?.format = self.format
            mo?.ddfIntValue = Int64(self.ddfIntValue)
            mo?.ddfFloatValue = self.ddfFloatValue
            mo?.ddfStringValue = self.ddfStringValue
            do {
                try context.save()
            } catch let error as NSError {
                debugPrint("DDFSubfieldDefinitionMO: \(error.localizedDescription)")
            }
        })
    }
}
