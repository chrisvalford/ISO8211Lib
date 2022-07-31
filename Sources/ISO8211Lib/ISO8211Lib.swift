// ISO8211Lib.swift
// Swift interface to Objective-c++ wrapper

import ISO8211LibWrapper

public struct ISO8211Lib {

    private var wrapper: ISO8211LibWrapper

    public init(){
        wrapper = ISO8211LibWrapper()
        let service = DateTimeService()
        service.create(Date(), note: "Startup")
    }
    
    public init(filePath: String){
        wrapper = ISO8211LibWrapper(filePath)
    }
    
    public func readCatalog(filePath: String) async {
        let record = wrapper.readCatalog(filePath)
        await record?.insert()
    }
    
    public func addition(value1: Float, value2: Float) -> Float {
        wrapper.addition(value1, value2)
    }
    
    public func subtraction(value1: Float, value2: Float) -> Float {
        wrapper.subtraction(value1, value2)
    }
    
    public func multiplication(value1: Float, value2: Float) -> Float {
        wrapper.multiplication(value1, value2)
    }
    
    public func division(value1: Float, value2: Float) -> Float {
        wrapper.division(value1, value2)
    }
}
