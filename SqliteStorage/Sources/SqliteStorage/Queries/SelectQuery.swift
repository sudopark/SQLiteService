//
//  SelectQuery.swift
//  
//
//  Created by sudo.park on 2021/06/13.
//

import Foundation


// MARK: - SelectQuery

public struct SelectQuery {
    
    public indirect enum SelectionType {
        case all(from: TableName)
        case some(_ keys: [ColumnName], from: TableName)
        case someAt(_ pairs: [SelectionType], from: TableName)
    }
    
    let selection: SelectionType
    let conditions: QueryStatement.ConditionSet
    let ascendings: Set<ColumnName>
    let descendings: Set<ColumnName>
    let limit: Int?
}
