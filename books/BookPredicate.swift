//
//  BookPredicate.swift
//  books
//
//  Created by Andrew Bennet on 28/03/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import Foundation

class BookPredicate {
    
    static let titleFieldName = "title"
    static let authorFieldName = "authorList"
    static let readStateFieldName = "readState"
    
    static func readStateEqual(readState: BookReadState) -> NSPredicate {
        return NSPredicate(fieldName: readStateFieldName, equalTo: String(readState.rawValue))
    }
    
    static func titleContains(substring: String) -> NSPredicate {
        return NSPredicate.searchWithinField(titleFieldName, substring: substring)
    }
    
    static func authorContains(substring: String) -> NSPredicate {
        return NSPredicate.searchWithinField(authorFieldName, substring: substring)
    }
    
    static func titleSort(ascending: Bool) -> NSSortDescriptor {
        return NSSortDescriptor(key: titleFieldName, ascending: ascending)
    }
    
    static func readStateSort(ascending: Bool) -> NSSortDescriptor {
        return NSSortDescriptor(key: readStateFieldName, ascending: ascending)
    }
}