# Changelog

### 5.1.0

- Added `GroupOperation`.
- Added `ResultOperation`
- Added `GeneratorOperation` protocol.
- Operations conforming to `OutputProducingOperation` now needs to implement  `onOutputProduced`.
- `FailableOperation` is now generic over its Error type.
- Improved logs for operations conforming to `FailableOperation`.

### 5.0.0 ⭐

- Added `AsynchronousOperation`.
- Added `AsynchronousBlockOperation`.
- renamed `inject` into `injectOutput`.
- Removed `AdvancedOperation`
- Removed conditions.

### 4.0.0 ⭐

- An `AdvancedOperation` can now be cancelled or finished with only one single `Error`.
- Injection doesn't require an *adapter* operation anymore.
- `OperationConditionResult` has beed replaced by the Swift `Result` type.
- Removed `AdvancedOperationQueue`.
- New `ExclusivityManager` implementation.
- Removed `then` operator.
- Added `Operation.addDependencies(_:)` method.

### 3.2.0

- Added  `OperationDidExecuteObserving` protocol.

### 3.1.0

- Improved `GroupOperation`.
- `OperationInputHaving` deprecated, use `InputRequiring` instead.
- `OperationOutputHaving` deprecated, use `OutputProducing` instead.
-  Bugfixes.

### 3.0.0 ⭐

- AdvancedOperation is now completely migrated to **Swift 5.0**.
- Bugfixes.

### 2.3.0

- Improved produced operations.
- Bugfixes.

### 2.2.2

- GroupOperation Bugfixes.

### 2.2.1

- Bugfixes.

### 2.2.0

- Added `duration` (in seconds) to `AdvancedOperation`.
- Added `MutualExclusivityCondition`. 
- Bugfixes.

### 2.1.0

- `AdvancedBlockOperation` supports `ProgressReporting`.
- Bugfixes.

### 2.0.0 ⭐

- Added `BlockCondition`. 
- Added `TimeoutObserver`.
- Added support for `isAsynchronous`  \ `isCondurrent` operation.
- Fixed KVO for the `isCancelled` property in `AdvancedOperation`.
- A `GroupOperation` can be cancelled correctly even if it's not yet started.
- The property `failed` in `AdvancedOperation` has been renamed `hasErrors` to better reflect its intent.
- Removed `ExclusivityManager`.
- Conditions are evaluated as a dependency operation.
- Bugfixes.

### 1.1.0

- Added a `UIBackgroundObserver` to let an `AdvancedOperation` run in background (for a small amount of time) on `iOS` and `tvOS`.
- The main phases of an `AdvancedOperation` can now be monitored via `OSLog`.
- `ExclusivityManager` improvements.
- Better `OperationCondition` errors.
- Bugfixes.

### 1.0.0 ⭐

- AdvancedOperation is now completely migrated to **Swift 4.2**.

### 0.7.5

- The  `main` function in  `GroupOperation` is now overridable.

### 0.7.4

- An Injectable operation now has a  `transform` closure.

### 0.7.3

- Fixed access levels.

### 0.7.2

-  Resolved an ExclusivityManager bug where a cancelled operation was added the operation list.

### 0.7.1

- Fixed some thread safety isssues.
- Fixed an issue occurring while cancelling a  `DelayOperation`.

### 0.7.0

- Injectable operations.
- Now an operation cancelled while evaluating its conditions, will be flagged as cancelled only after the evaluation.
- Bugfixes.
- More tests.

### 0.6.0

- The mutual exclusivity now can be enabled in *enqueue* or *cancel* mode.

### 0.5.1

- Added more public APIs.

### 0.5.0

- Improved GroupOperation.
- Improved cancel command.
- Bugfixes.

### 0.4.1

- Bugfixes.
- More tests.

### 0.4.0

- Conditions can generate dependencies.
- Bugfixes.

### 0.3.0

- Swift 4.1
- Added Operation conditions.

### 0.2.0

- Refinements.

### 0.1.0

- First release. ⭐
