//
//  Plugin.swift
//
//
//  Created by sudo.park.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros


@main
struct SQLiteServiceMacrosPlugin: CompilerPlugin {

    let providingMacros: [Macro.Type] = [
        TableMacro.self,
        ColumnMacro.self
    ]
}
