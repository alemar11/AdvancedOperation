# Changelog

### 0.7.2

-  Resolved an ExclusivityManager bug where a cancelled operation was added the operation list.

### 0.7.1

- Fixed some thread safety isssues.
- Fixed an issue occurring while cancelling a `DelayOperation`.

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
