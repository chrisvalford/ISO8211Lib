// ISO8211Lib.swift
// Swift interface to Objective-c++ wrapper

import ISO8211LibWrapper

public struct ISO8211Lib {

    private var wrapper: ISO8211LibWrapper

    public init(){
        wrapper = ISO8211LibWrapper()
    }
    
    public init(filePath: String){
        wrapper = ISO8211LibWrapper(filePath)
    }
    
    public func readCatalog(filePath: String) -> Bool {
        return wrapper.readCatalog(filePath)
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
