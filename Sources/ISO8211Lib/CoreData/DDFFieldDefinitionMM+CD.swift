//
//  DDFFieldDefinitionMM+CD.swift
//  
//
//  Created by Christopher Alford on 31/7/22.
//

import CoreData
import Foundation
import ISO8211LibWrapper

extension DDFFieldDefinitionMM {

    // Save as a DDFFieldDefinitionMO
    func insert() {
        let stack = CoreDataStack.shared
        stack.persistentContainer.performBackgroundTask({ (context) in
            let mo = NSEntityDescription.insertNewObject(forEntityName: "DDFFieldDefinitionMO", into: context) as? DDFFieldDefinitionMO
            mo?.name = self.name

            // toSubfields 1-n
            for subfield in (self.subfields as! [DDFSubfieldDefinitionMM]) {
                guard let subfieldMO = NSEntityDescription.insertNewObject(forEntityName: "DDFSubfieldDefinitionMO", into: context) as? DDFSubfieldDefinitionMO else {
                    debugPrint("DDFFieldMO: Unable to create DDFSubfieldDefinitionMO")
                    return
                }
                subfieldMO.name = subfield.name
                subfieldMO.format = subfield.format
                subfieldMO.ddfIntValue = Int64(subfield.ddfIntValue)
                subfieldMO.ddfFloatValue = subfield.ddfFloatValue
                subfieldMO.ddfStringValue = subfield.ddfStringValue
                mo?.addToToSubfields(subfieldMO)
            }
            do {
                try context.save()
            } catch let error as NSError {
                debugPrint("DDFFieldDefinitionMO: \(error.localizedDescription)")
            }
        })
    }
}
