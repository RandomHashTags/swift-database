//
//  PostgresPseudoTypes.swift
//
//
//  Created by Evan Anderson on 11/7/24.
//

public enum PostgresPseudoTypes : String {
    case any
    case anyelement
    case anyarray
    case anynonarray
    case anyenum
    case anyrange
    case anymultirange
    case anycompatible
    case anycompatiblearray
    case anycompatiblenonarray
    case anycompatiblemultirange
    case cstring
    case `internal`
    case language_handler
    case fdw_handler
    case table_am_handler
    case index_am_handler
    case tsm_handler
    case record
    case trigger
    case event_trigger
    case pg_ddl_command
    case void
    case unknown
}