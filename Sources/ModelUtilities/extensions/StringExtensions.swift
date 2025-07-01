
extension String {
    public static func sqlEpoch() -> String {
        "'epoch()'"
    }
    public static func sqlInfinity() -> String {
        "'infinity()'"
    }
    public static func sqlNegativeInfinity() -> String {
        "'-infinity()'"
    }
    public static func sqlNow() -> String {
        "'now()'"
    }
    public static func sqlToday() -> String {
        "'today()'"
    }
    public static func sqlTomorrow() -> String {
        "'tomorrow()'"
    }
    public static func sqlYesterday() -> String {
        "'yesterday()'"
    }
    public static func allballs() -> String {
        "'allballs()'"
    }
}