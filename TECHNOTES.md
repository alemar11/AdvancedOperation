# Tech Notes

### Operation

 - [Quality of Service Inference and Promotion](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/PrioritizeWorkWithQoS.html#//apple_ref/doc/uid/TP40015243-CH39)
 - [Simple and Reliable Threading with NSOperation](https://developer.apple.com/library/archive/technotes/tn2109/_index.html#//apple_ref/doc/uid/DTS40010274-CH1-SUBSECTION11)
 - [wwdc2015 - 706](https://developer.apple.com/videos/play/wwdc2017/706/)

 ### Thread explosion

 - [wwdc2015 - 718](https://developer.apple.com/videos/play/wwdc2015/718/)
 - [Dev forum]( https://forums.developer.apple.com/thread/51952)

### `start()` considerations

Calling `super.start()` causes some KVO issues (the doc says "Your (concurrent) custom implementation must not call super at any time").
The default implementation of this method updates the execution state of the operation and calls the receiver’s `main()` method.

`super.start()` method also performs several checks to ensure that the operation can actually run: 
- For example, if the receiver was cancelled or is already finished, this method simply returns without calling `main()`.
- If the operation is currently executing or is not ready to execute, this method throws an NSInvalidArgumentException exception.

Investigation on how super.start() works:
- If `start()` is called on a not yet ready operation, `super.start()` will throw an exception.
- If `start()` is called multiple times from different threads, `super.start()` will throw an exception.
- If `start()` is called on an already cancelled but noy yet executed operation, `super.start()` will change its state to finished.
-  The isReady value is kept to *true* once the Operation is finished.

The operation readiness is evaluated after checking if the operation is already finished.
(In fact, if a dependency is added once the operation is already finished no exceptions are thrown if we attempt to start the operation again
(silly test, I know):

```swift
let op1 = BlockOperation()
let op2 = BlockOperation()
print(op2.isReady) // true
op2.start()
print(op2.isFinished) // true
op2.addDependency(op1)
print(op2.isReady) // false
op2.start() // Nothing happens (no exceptions either)
```

### `cancel()` considerations

If an operation is finished, calling `cancel()`  won't change its `isCancelled` value to *true*.

