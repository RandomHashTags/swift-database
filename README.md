# Swift Database
Swift Database is a standalone database library that enables communication to your favorite databases, using the bare minimum dependencies. We do not lock this library behind using proprietary server implementations.

It utilizes the latest features of the Swift Language like concurrency, Actors, Macros, and memory ownership to push performance to the absolute limits. We will be adopting more Swift features, like `~Copyable`, `~Escapable`, and borrowing array elements upon iteration when they are feature-complete.

## Expected features
- support for the most popular databases ranked by market share (plus others that we find appealing)
- support for memory-only databases (especially useful for testing)
- usage of Swift Macros for migration & type-safe SQL/NoSQL commands, and anywhere else that benefits from compile-time performance
- usage of Swift Memory Ownership features for better performance

## Contributing
Create a PR.
