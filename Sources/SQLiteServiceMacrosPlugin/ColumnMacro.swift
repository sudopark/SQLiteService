//
//  ColumnMacro.swift
//
//
//  Created by sudo.park.
//

import SwiftSyntax
import SwiftSyntaxMacros


/// `@Column` only carries column metadata to `@Table` and expands to nothing.
public struct ColumnMacro: PeerMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}
