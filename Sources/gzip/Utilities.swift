//
//  Utilities.swift
//  gzip
//
//  Created by Honza Dvorsky on 5/23/16.
//
//

import Foundation

func autoreleasepoolIfAvailable<Result>(_ body: @noescape () throws -> Result) rethrows -> Result {
    #if _runtime(_ObjC)
        return try autoreleasepool(body)
    #else
        return try body()
    #endif
}
