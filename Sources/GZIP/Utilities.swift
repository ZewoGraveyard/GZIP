//
//  Utilities.swift
//  gzip
//
//  Created by Honza Dvorsky on 5/23/16.
//
//

import Foundation

public func autoreleasepoolIfAvailable<Result>(_ body: () throws -> Result) rethrows -> Result {
    #if _runtime(_ObjC)
        return try autoreleasepool(invoking: body)
    #else
        return try body()
    #endif
}
