
extension PostgresMessage {
    public enum BackendType: UInt8, Sendable {
        case authentication           = 82  // R
        case backendKeyData           = 75  // K
        case bind                     = 66  // B
        case bindComplete             = 50  // 2
        case close                    = 67  // C
        case closeComplete            = 57  // 3
        case copyData                 = 100 // d
        case copyDone                 = 99  // c
        case copyFail                 = 102 // f
        case copyInResponse           = 71  // G
        case copyOutResponse          = 72  // H
        case copyBothResponse         = 87  // W
        case dataRow                  = 68  // D
        case emptyQueryResponse       = 73  // I
        case errorResponse            = 69  // E
        case functionCallResponse     = 86  // V
        case negotiateProtocolVersion = 118 // v
        case noData                   = 110 // n
        case noticeResponse           = 78  // N
        case notificationResponse     = 65  // A
        case parameterDescription     = 116 // t
        case parseComplete            = 49  // 1
        case parameterStatus          = 83  // S
        case portalSuspend            = 115 // s
        case readyForQuery            = 90  // Z
        case rowDescription           = 84  // T
    }
}