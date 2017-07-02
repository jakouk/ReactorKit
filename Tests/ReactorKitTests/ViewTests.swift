import XCTest
import ReactorKit
import RxSwift

#if os(iOS) || os(tvOS)
import UIKit
private typealias OSViewController = UIViewController
private typealias OSView = UIView
#elseif os(OSX)
import AppKit
private typealias OSViewController = NSViewController
private typealias OSView = NSView
#endif

#if !os(Linux)
final class ViewTests: XCTestCase {
  func testBindIsInvoked_differentReactor() {
    let view = TestView()
    XCTAssertEqual(view.bindInvokeCount, 0)
    view.reactor = TestReactor()
    XCTAssertEqual(view.bindInvokeCount, 1)
    view.reactor = TestReactor()
    XCTAssertEqual(view.bindInvokeCount, 2)
  }

  func testDisposeBagIsDisposed_differentReactor() {
    let view = TestView()
    let oldHashValue = ObjectIdentifier(view.disposeBag).hashValue
    view.reactor = TestReactor()
    let newHashValue = ObjectIdentifier(view.disposeBag).hashValue
    XCTAssertNotEqual(oldHashValue, newHashValue)
  }

  func testReactor_assign() {
    let reactor = TestReactor()
    let view = TestView()
    view.reactor = reactor
    XCTAssertNotNil(view.reactor)
    XCTAssertTrue(view.reactor === reactor)
  }

  func testReactor_assignNil() {
    let reactor = TestReactor()
    let view = TestView()
    view.reactor = reactor
    view.reactor = nil
    XCTAssertNil(view.reactor)
  }

  func testDeferBinding() {
    let viewController = TestViewController()
    viewController.reactor = TestReactor()
    XCTAssertEqual(viewController.bindInvokeCount, 0) // view is not loaded yet; skip binding
    _ = viewController.view // makes `loadView()` get called

    let expectation = self.expectation(description: "bindInvokeCountExpectation")
    DispatchQueue.main.async(execute: expectation.fulfill)
    self.waitForExpectations(timeout: 0.5) { error in
      XCTAssertNil(error)
      XCTAssertEqual(viewController.bindInvokeCount, 1)
    }
  }

  func testDeferBinding_changeReactorWhileDeferred() {
    let viewController = TestViewController()
    viewController.reactor = TestReactor()
    XCTAssertEqual(viewController.bindInvokeCount, 0)
    viewController.reactor = TestReactor() // assign a new reactor
    _ = viewController.view // makes `loadView()` get called

    let expectation = self.expectation(description: "bindInvokeCountExpectation")
    DispatchQueue.main.async(execute: expectation.fulfill)
    self.waitForExpectations(timeout: 0.5) { error in
      XCTAssertNil(error)
      XCTAssertEqual(viewController.bindInvokeCount, 1)
      viewController.reactor = TestReactor() // assign a new reactor after view is loaded
      XCTAssertEqual(viewController.bindInvokeCount, 2)
    }
  }
}

private final class TestView: View {
  var disposeBag = DisposeBag()
  var bindInvokeCount = 0

  func bind(reactor: TestReactor) {
    self.bindInvokeCount += 1
  }
}

private final class TestViewController: OSViewController, View {
  var disposeBag = DisposeBag()
  var bindInvokeCount = 0

  override func loadView() {
    self.view = OSView()
  }

  func bind(reactor: TestReactor) {
    self.bindInvokeCount += 1
  }
}

private final class TestReactor: Reactor {
  typealias Action = NoAction
  struct State {}
  let initialState = State()
}
#endif
