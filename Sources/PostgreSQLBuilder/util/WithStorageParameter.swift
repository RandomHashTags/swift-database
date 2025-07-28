
extension PostgresSQLBuilder {
    public enum WithStorageParameter: PostgresSQLBuilderComponent {
        case fillfactor(Int)
        case toastTupleTarget(Int)
        case parallelWorkers(Int)
        case autovacuumEnabled(Bool)
        case toastAutovacuumEnabled(Bool)
        case vacuumIndexCleanup(VacuumIndexCleanup)
        case toastVacuumIndexCleanup(VacuumIndexCleanup)
        case vacuumTruncate(Bool)
        case toastVacuumTruncate(Bool)
        case autovacuumVacuumThreshold(Int)
        case toastAutovacuumVacuumThreshold(Int)
        case autovacuumVacuumScaleFactor(Float)
        case toastAutovacuumVacuumScaleFactor(Float)
        case autovacuumVacuumInsertThreshold(Int)
        case toastAutovacuumVacuumInsertThreshold(Int)
        case autovacuumVacuumInsertScaleFactor(Float)
        case toastAutovacuumVacuumInsertScaleFactor(Float)
        case autovacuumAnalyzeThreshold(Int)
        case autovacuumAnalyzeScaleFactor(Float)
        case autovacuumVacuumCostDelay(Float)
        case toastAutovacuumVacuumCostDelay(Float)
        case autovacuumVacuumCostLimit(Int)
        case toastAutovacuumVacuumCostLimit(Int)
        case autovacuumFreezeMinAge(Int)
        case toastAutovacuumFreezeMinAge(Int)
        case autovacuumFreezeMaxAge(Int)
        case toastAutovacuumFreezeMaxAge(Int)
        case autovacuumFreezeTableAge(Int)
        case toastAutovacuumFreezeTableAge(Int)
        case autovacuumMultixactFreezeMinAge(Int)
        case toastAutovacuumMultixactFreezeMinAge(Int)
        case autovacuumMultixactFreezeMaxAge(Int)
        case toastAutovacuumMultixactFreezeMaxAge(Int)
        case autovacuumMultixactFreezeTableAge(Int)
        case toastAutovacuumMultixactFreezeTableAge(Int)
        case logAutovacuumMinDuration(Int)
        case toastLogAutovacuumMinDuration(Int)
        case userCatalogTable(Bool)

        public var sql: String {
            switch self {
            case .fillfactor(let i): "fillfactor=\(i)"
            case .toastTupleTarget(let i): "toast_tuple_target=\(i)"
            case .parallelWorkers(let i): "parallel_workers=\(i)"
            case .autovacuumEnabled(let b): "autovacuum_enabled=\(b)"
            case .toastAutovacuumEnabled(let b): "toast.autovacuum_enabled=\(b)"
            case .vacuumIndexCleanup(let e): "vacuum_index_cleanup=\(e.sql)"
            case .toastVacuumIndexCleanup(let e): "toast.vacuum_index_cleanup=\(e.sql)"
            case .vacuumTruncate(let b): "vacuum_truncate=\(b)"
            case .toastVacuumTruncate(let b): "toast.vacuum_truncate=\(b)"
            case .autovacuumVacuumThreshold(let i): "autovacuum_vacuum_threshold=\(i)"
            case .toastAutovacuumVacuumThreshold(let i): "toast.autovacuum_vacuum_threshold=\(i)"
            case .autovacuumVacuumScaleFactor(let f): "autovacuum_vacuum_scale_factor=\(f)"
            case .toastAutovacuumVacuumScaleFactor(let f): "toast.autovacuum_vacuum_scale_factor=\(f)"
            case .autovacuumVacuumInsertThreshold(let i): "autovacuum_vacuum_insert_threshold=\(i)"
            case .toastAutovacuumVacuumInsertThreshold(let i): "toast.autovacuum_vacuum_insert_threshold=\(i)"
            case .autovacuumVacuumInsertScaleFactor(let f): "autovacuum_vacuum_insert_scale_factor=\(f)"
            case .toastAutovacuumVacuumInsertScaleFactor(let f): "toast.autovacuum_vacuum_insert_scale_factor=\(f)"
            case .autovacuumAnalyzeThreshold(let i): "autovacuum_analyze_threshold=\(i)"
            case .autovacuumAnalyzeScaleFactor(let i): "autovacuum_analyze_scale_factor=\(i)"
            case .autovacuumVacuumCostDelay(let f): "autovacuum_vacuum_cost_delay=\(f)"
            case .toastAutovacuumVacuumCostDelay(let f): "toast.autovacuum_vacuum_cost_delay=\(f)"
            case .autovacuumVacuumCostLimit(let i): "autovacuum_vacuum_cost_limit=\(i)"
            case .toastAutovacuumVacuumCostLimit(let i): "toast.autovacuum_vacuum_cost_limit=\(i)"
            case .autovacuumFreezeMinAge(let i): "autovacuum_freeze_min_age=\(i)"
            case .toastAutovacuumFreezeMinAge(let i): "toast.autovacuum_freeze_min_age=\(i)"
            case .autovacuumFreezeMaxAge(let i): "autovacuum_freeze_max_age=\(i)"
            case .toastAutovacuumFreezeMaxAge(let i): "toast.autovacuum_freeze_max_age=\(i)"
            case .autovacuumFreezeTableAge(let i): "autovacuum_freeze_table_age=\(i)"
            case .toastAutovacuumFreezeTableAge(let i): "toast.autovacuum_freeze_table_age=\(i)"
            case .autovacuumMultixactFreezeMinAge(let i): "autovacuum_multixact_freeze_min_age=\(i)"
            case .toastAutovacuumMultixactFreezeMinAge(let i): "toast.autovacuum_multixact_freeze_min_age=\(i)"
            case .autovacuumMultixactFreezeMaxAge(let i): "autovacuum_multixact_freeze_max_age=\(i)"
            case .toastAutovacuumMultixactFreezeMaxAge(let i): "toast.autovacuum_multixact_freeze_max_age=\(i)"
            case .autovacuumMultixactFreezeTableAge(let i): "autovacuum_multixact_freeze_table_age=\(i)"
            case .toastAutovacuumMultixactFreezeTableAge(let i): "toast.autovacuum_multixact_freeze_table_age=\(i)"
            case .logAutovacuumMinDuration(let i): "log_autovacuum_min_duration=\(i)"
            case .toastLogAutovacuumMinDuration(let i): "toast.log_autovacuum_min_duration=\(i)"
            case .userCatalogTable(let b): "user_catalog_table=\(b)"
            }
        }
    }
}

// MARK: VacuumIndexCleanup
extension PostgresSQLBuilder.WithStorageParameter {
    public enum VacuumIndexCleanup: String, PostgresSQLBuilderComponent {
        case auto
        case off
        case on

        public var sql: String {
            switch self {
            case .auto: "AUTO"
            case .off:  "OFF"
            case .on:   "ON"
            }
        }
    }
}