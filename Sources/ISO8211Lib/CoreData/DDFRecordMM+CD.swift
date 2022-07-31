//
//  File.swift
//  
//
//  Created by Christopher Alford on 31/7/22.
//

import CoreData
import Foundation
import ISO8211LibWrapper

extension DDFRecordMM {

    // Save as a DDFRecordMO
    func insert() async {
        let stack = CoreDataStack.shared
        await stack.persistentContainer.performBackgroundTask({ (context) in
            let mo = NSEntityDescription.insertNewObject(forEntityName: "DDFRecordMO", into: context) as? DDFRecordMO

            // toFields 1-n
            for field in (self.ddfFields as! [DDFFieldMM]) {
                guard let fieldMO = NSEntityDescription.insertNewObject(forEntityName: "DDFFieldMO", into: context) as? DDFFieldMO else {
                    debugPrint("DDFRecordMO: Unable to create DDFFieldMO")
                    break
                }
                fieldMO.name = field.name
                fieldMO.text = field.text
                mo?.addToToFields(fieldMO)
            }
            do {
                try context.save()
            } catch let error as NSError {
                debugPrint("DDFRecordMO: \(error.localizedDescription)")
            }
        })
    }
}

