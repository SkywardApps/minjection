# Minjection

[![CI Status](http://img.shields.io/travis/SkywardApps/minjection.svg?style=flat)](https://travis-ci.org/SkywardApps/minjection)
[![Version](https://img.shields.io/cocoapods/v/minjection.svg?style=flat)](http://cocoapods.org/pods/minjection)
[![License](https://img.shields.io/cocoapods/l/minjection.svg?style=flat)](http://cocoapods.org/pods/minjection)
[![Platform](https://img.shields.io/cocoapods/p/minjection.svg?style=flat)](http://cocoapods.org/pods/minjection)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

None in particular.  This is designed specifically for objective-c.

## Installation

minjection is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'minjection'
```

## Author

Nicholas M T Elliott, nelliott@skywardapps.com

## License

minjection is available under the MIT license. See the LICENSE file for more info.


# Introduction

This project was born out of necessity.  There are a small handful
of existing DI libraries for objective-c, but none quite matched our needs.


We wrote this to fill the gaps because we've been spoiled by good options in other
languages, and hope this will likewise prove useful to others.

If you don't know why you would want dependency injection, there are many good discussions on the web -- for example,
[Java HOW-TO](https://www.javaworld.com/article/2071914/excellent-explanation-of-dependency-injection--inversion-of-control-.html) or [Objective-C discussion]{https://www.objc.io/issues/15-testing/dependency-injection/}.

The short of it is: Using dependency injection, you make your code more maintainable, more transparent, and more testable.  This library just provides a minimal set of objects and methods to get you started.

# Quick Start

See [Installation](#Installation) above to get the pod in your project.  You will need to create at least one container -- a container provides a 'scope' within which it can provide services (any old object, really).  For example, you can drop your root container into the app delegate.

```objc

#import <minjection/MinjectionContainer.h>

...

@property (strong, nonatomic) MinjectionContainer* rootContainer;

...

_rootContainer = [[MinjectionContainer alloc] init];

```

Now you need to register some services this container will provide.  A service is a mapping of either a base class, or a protocol, to a method of resolving the object that fulfills that requirement.

That means you can declare a protocol:

```objc

@protocol Configuration

- (NSString*) serverUrl;
- (NSString*) applicationSecret;
- (int) versionNumber;

@end

```

and then register a variety of classes to fulfil it at runtime.  For example, you may have one version that loads the configuration from a JSON property file, or a plist, for your production build, and another that reads the configuration from environment variables for your test build.  At runtime, you dictate which to use:

```objc

   if(testBuild)
   {
        [_rootContainer registerClass:EnvironmentConfiguration.class
                      withInitializer:@selector(init)
                          forProtocol:@protocol(Configuration)];
   }
   else
   {
        [_rootContainer registerClass:JsonConfiguration.class
                      withInitializer:@selector(init)
                          forProtocol:@protocol(Configuration)];
   }
}
```

Now you can use this to inject these services to other object.  Minjection currently only supports property injection, meaning it can scan an object and attempt to hook up any public writable properties it has a matching service for.

```objc

@interface MyInjectedObject

@property (strong, nonatomic) id<Configuration> config;

@end

...

// Create the object manually
MyInjectedObject* item = [[MyInjectedObject alloc] init];

// inject any properties on it that we can
[_rootContainer injectProperties:item];

// Alternatively we can ask for a service directly
id<Configuration> config = [_rootContainer resolveProtocol:@protocol(Configuration)];

```

# Usage

## simple registration

## complex options

## lifetime

