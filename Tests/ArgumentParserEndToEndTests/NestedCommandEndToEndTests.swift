//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest
import ArgumentParserTestHelpers
import ArgumentParser

final class NestedCommandEndToEndTests: XCTestCase {
}

// MARK: Single value String

fileprivate struct Foo: ParsableCommand {
  static var configuration =
    CommandConfiguration(subcommands: [Build.self, Package.self])
  
  @Flag(name: .short)
  var verbose: Bool
  
  struct Build: ParsableCommand {
    @OptionGroup() var foo: Foo
    
    @Argument()
    var input: String
  }
  
  struct Package: ParsableCommand {
    static var configuration =
      CommandConfiguration(subcommands: [Clean.self, Config.self])
    
    @Flag(name: .short)
    var force: Bool
    
    struct Clean: ParsableCommand {
      @OptionGroup() var foo: Foo
      @OptionGroup() var package: Package
    }
    
    struct Config: ParsableCommand {
      @OptionGroup() var foo: Foo
      @OptionGroup() var package: Package
    }
  }
}

fileprivate func AssertParseFooCommand<A>(_ type: A.Type, _ arguments: [String], file: StaticString = #file, line: UInt = #line, closure: (A) throws -> Void) where A: ParsableCommand {
  AssertParseCommand(Foo.self, type, arguments, file: file, line: line, closure: closure)
}


extension NestedCommandEndToEndTests {
  func testParsing_package() throws {
    AssertParseFooCommand(Foo.Package.Clean.self, ["package", "clean"]) { clean in
      XCTAssertEqual(clean.foo.verbose, false)
      XCTAssertEqual(clean.package.force, false)
    }
    
    AssertParseFooCommand(Foo.Package.Clean.self, ["-f", "package", "clean"]) { clean in
      XCTAssertEqual(clean.foo.verbose, false)
      XCTAssertEqual(clean.package.force, true)
    }
    
    AssertParseFooCommand(Foo.Package.Clean.self, ["package", "-f", "clean"]) { clean in
      XCTAssertEqual(clean.foo.verbose, false)
      XCTAssertEqual(clean.package.force, true)
    }
    
    AssertParseFooCommand(Foo.Package.Config.self, ["package", "-v", "config"]) { config in
      XCTAssertEqual(config.foo.verbose, true)
      XCTAssertEqual(config.package.force, false)
    }
    
    AssertParseFooCommand(Foo.Package.Config.self, ["package", "config", "-v"]) { config in
      XCTAssertEqual(config.foo.verbose, true)
      XCTAssertEqual(config.package.force, false)
    }
    
    AssertParseFooCommand(Foo.Package.Config.self, ["-v", "package", "config"]) { config in
      XCTAssertEqual(config.foo.verbose, true)
      XCTAssertEqual(config.package.force, false)
    }
    
    AssertParseFooCommand(Foo.Package.Config.self, ["package", "-f", "config"]) { config in
      XCTAssertEqual(config.foo.verbose, false)
      XCTAssertEqual(config.package.force, true)
    }
    
    AssertParseFooCommand(Foo.Package.Config.self, ["package", "config", "-f"]) { config in
      XCTAssertEqual(config.foo.verbose, false)
      XCTAssertEqual(config.package.force, true)
    }
    
    AssertParseFooCommand(Foo.Package.Config.self, ["-f", "package", "config"]) { config in
      XCTAssertEqual(config.foo.verbose, false)
      XCTAssertEqual(config.package.force, true)
    }
    
    AssertParseFooCommand(Foo.Package.Config.self, ["package", "-v", "config", "-f"]) { config in
      XCTAssertEqual(config.foo.verbose, true)
      XCTAssertEqual(config.package.force, true)
    }
    
    AssertParseFooCommand(Foo.Package.Config.self, ["package", "-f", "config", "-v"]) { config in
      XCTAssertEqual(config.foo.verbose, true)
      XCTAssertEqual(config.package.force, true)
    }
    
    AssertParseFooCommand(Foo.Package.Config.self, ["package", "-vf", "config"]) { config in
      XCTAssertEqual(config.foo.verbose, true)
      XCTAssertEqual(config.package.force, true)
    }
    
    AssertParseFooCommand(Foo.Package.Config.self, ["package", "-fv", "config"]) { config in
      XCTAssertEqual(config.foo.verbose, true)
      XCTAssertEqual(config.package.force, true)
    }
  }
  
  func testParsing_build() throws {
    AssertParseFooCommand(Foo.Build.self, ["build", "file"]) { build in
      XCTAssertEqual(build.foo.verbose, false)
      XCTAssertEqual(build.input, "file")
    }
  }
  
  func testParsing_fails() throws {
    XCTAssertThrowsError(try Foo.parse(["package"]))
    XCTAssertThrowsError(try Foo.parse(["clean", "package"]))
    XCTAssertThrowsError(try Foo.parse(["config", "package"]))
    XCTAssertThrowsError(try Foo.parse(["package", "c"]))
    XCTAssertThrowsError(try Foo.parse(["package", "build"]))
    XCTAssertThrowsError(try Foo.parse(["package", "build", "clean"]))
    XCTAssertThrowsError(try Foo.parse(["package", "clean", "foo"]))
    XCTAssertThrowsError(try Foo.parse(["package", "config", "bar"]))
    XCTAssertThrowsError(try Foo.parse(["package", "clean", "build"]))
    XCTAssertThrowsError(try Foo.parse(["build"]))
    XCTAssertThrowsError(try Foo.parse(["build", "-f"]))
    XCTAssertThrowsError(try Foo.parse(["build", "--build"]))
    XCTAssertThrowsError(try Foo.parse(["build", "--build", "12"]))
  }
}
