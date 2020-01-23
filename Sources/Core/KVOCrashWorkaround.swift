// 
// AdvancedOperation
//
// Copyright © 2016-2020 Tinrobots.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

#if swift(<5.1)
/// Workaround to solve some  multithreading bugs in Swift's KVO.
/// This needs to execute before anything can register KVO in the background so the best way to do this is before the application ever runs
///
/// `KVOCrashWorkaround.installFix()`
///
/// - Note: it's not required for Swift 5.1 and above, see this [Swift PR](https://github.com/apple/swift/pull/20103)
public final class KVOCrashWorkaround: NSObject {
  @objc dynamic var test: String = ""
  
  /// Install the workaround: it shoud be done from the **main** thread.
  public static func installFix() {
    assert(Thread.isMainThread)
    let obj = KVOCrashWorkaround()
    let observer = obj.observe(\.test, options: [.new]) { (_, _) in
      fatalError("Shouldn't be called, value doesn't change")
    }
    observer.invalidate()
  }
}
#endif


