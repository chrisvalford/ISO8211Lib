//
//  AppDelegate.swift
//  ISO8211Lib
//
//  Created by Christopher Alford on 1/5/23.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var ddfModule: DDFModule?
    var filePath: String?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Open the file.
        if filePath == nil {
            filePath = "/Users/christopheralford/Downloads/CATALOG.031"
        }
        if ddfModule == nil {
            ddfModule = DDFModule()
        }
        if ddfModule?.open(filePath, bFailQuietly: 0) == 0 {
            exit(1)
        }
        
        // Loop reading records till there are none left.
        var iRecord = 0
        
        while true {
            guard let poRecord: DDFRecord = ddfModule?.readRecord else {
                break
            }
            iRecord += 1
            debugPrint("Record %d (%d bytes)\n", iRecord, poRecord.getDataSize)
            
            // Loop over each field in this particular record.
            // TODO: Check why this value is too large
            let fieldCount = poRecord.getFieldCount - 1
            for iField in 0 ..< fieldCount {
                let poField: DDFField = poRecord.getField(iField)
                viewRecordField(poField)
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    /**
    *      Dump the contents of a field instance in a record.
    */
    func viewRecordField(_ poField: DDFField) {
        var nBytesRemaining: Int
        var pachFieldData: String
        var poFieldDefn: DDFFieldDefinition = poField.getFieldDefn!
        
        // Report general information about the field.
        debugPrint("    Field %s: %@\n",
                   poFieldDefn.getName ,
                   poFieldDefn.getDescription )
        
        // Get pointer to this fields raw data.  We will move through
        // it consuming data as we report subfield values.
        pachFieldData = poField.getData
        nBytesRemaining = poField.getDataSize

        // Loop over the repeat count for this fields subfields.
        // The repeat count will almost always be one.
        for _ in 0 ..< poField.getRepeatCount {
            // Loop over all the subfields of this field, advancing
            // the data pointer as we consume data.
            for iSF in 0 ..< poFieldDefn.getSubfieldCount() {
                if let poSFDefn: DDFSubfieldDefinition = poFieldDefn.getSubfield(i: iSF) {
                    var nBytesConsumed = viewSubfield(poSFDefn,
                                                      pachFieldData: pachFieldData,
                                                      nBytesRemaining: nBytesRemaining)
                    nBytesRemaining -= nBytesConsumed
                    pachFieldData = String(pachFieldData.suffix(nBytesConsumed))
                }
            }
        }
    }
    
    /**
     * Dump the contents of a subfield
     */
    func viewSubfield(_ poSFDefn: DDFSubfieldDefinition,
                      pachFieldData: String,
                      nBytesRemaining: Int) -> Int {
        var nBytesConsumed: Int32 = 0
        switch poSFDefn.getType {
        case .int:
            if poSFDefn.getBinaryFormat == DDFBinaryFormat.uInt {
                debugPrint( "        %s = %u\n",
                            poSFDefn.name ?? "MISSING",
                            poSFDefn.extractIntData(pachFieldData,
                                                    nMaxBytes: Int32(nBytesRemaining),
                                                    pnConsumedBytes: &nBytesConsumed)
                )
            } else {
                debugPrint( "        %s = %d\n",
                            poSFDefn.name ?? "MISSING",
                            poSFDefn.extractIntData( pachFieldData,
                                                     nMaxBytes: Int32(nBytesRemaining),
                                                     pnConsumedBytes: &nBytesConsumed)
                )
            }
            
        case .float:
            debugPrint( "        %s = %f\n",
                        poSFDefn.name ?? "MISSING",
                        poSFDefn.extractFloatData(pachFieldData,
                                                  nMaxBytes: Int32(nBytesRemaining),
                                                  pnConsumedBytes: &nBytesConsumed)
            )
            
        case .string:
            debugPrint("        %s = '%@'\n",
                       poSFDefn.name ?? "MISSING",
                       poSFDefn.extractStringData(pachFieldData,
                                                  nMaxBytes: Int32(nBytesRemaining),
                                                  pnConsumedBytes: &nBytesConsumed) ?? ""
            )
            
        case .binaryString:
            //rjensen 19-Feb-2002 5 integer variables to decode NAME and LNAM
            var vrid_rcnm = 0
            var vrid_rcid = 0
            var foid_agen = 0
            var foid_find = 0
            var foid_fids = 0
            
            // Was GByte
            let pabyBString = poSFDefn.extractStringData(pachFieldData,
                                                         nMaxBytes: Int32(nBytesRemaining),
                                                         pnConsumedBytes: &nBytesConsumed).utf8CString
            
            debugPrint("        %s = 0x", poSFDefn.name ?? "MISSING")
            for i in 0 ..< min(Int(nBytesConsumed), 24) {
                debugPrint( "%02X", pabyBString[i] )
            }
            
            if nBytesConsumed > 24 {
                debugPrint( "%s", "..." )
            }
            
            // rjensen 19-Feb-2002 S57 quick hack. decode NAME and LNAM bitfields
            if  "NAME" == poSFDefn.name {
                vrid_rcnm = Int(pabyBString[0])
                let bs1 = Int(pabyBString[1])
                let bs2 = Int(pabyBString[2]) * 256
                let bs3 = Int(pabyBString[3]) * 65536
                let bs4 = Int(pabyBString[4]) * 16777216
                vrid_rcid = bs1 + bs2 + bs3 + bs4
                debugPrint("\tVRID RCNM = %d,RCID = %u",vrid_rcnm, vrid_rcid)
            } else if "LNAM" == poSFDefn.name {
                foid_agen = Int(pabyBString[0]) + (Int(pabyBString[1]) * 256)
                let bs2 = Int(pabyBString[2])
                let bs3 = Int(pabyBString[3]) * 256
                let bs4 = Int(pabyBString[4]) * 65536
                let bs5 = Int(pabyBString[5]) * 16777216
                foid_find = bs2 + bs3 + bs4 + bs5
                foid_fids = Int(pabyBString[6]) + (Int(pabyBString[7])*256)
                debugPrint("\tFOID AGEN = %u,FIDN = %u,FIDS = %u", foid_agen, foid_find, foid_fids)
            }
            debugPrint( "\n" );
        @unknown default:
            debugPrint("Unknown Type")
        }
        
        return Int(nBytesConsumed)
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "ISO8211Lib")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(_ sender: AnyObject?) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        let context = persistentContainer.viewContext

        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Customize this code block to include application-specific recovery steps.
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }

    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return persistentContainer.viewContext.undoManager
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        let context = persistentContainer.viewContext
        
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }
        
        if !context.hasChanges {
            return .terminateNow
        }
        
        do {
            try context.save()
        } catch {
            let nserror = error as NSError

            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if (result) {
                return .terminateCancel
            }
            
            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)
            
            let answer = alert.runModal()
            if answer == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }

}

