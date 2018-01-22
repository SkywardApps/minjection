//
//  TestMinjection.m
//  SenioTests
//
//  Created by Nicholas Elliott on 12/29/17.
//  Copyright © 2017 Skyward App Company, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <minjection/MinjectionContainer.h>
#import <minjection/MinjectionOptions.h>

#pragma mark - Test Classes

@interface AutoInjectable : NSObject

@property (atomic, strong) NSDictionary* injectDictionaryByClass;
@property (atomic, strong, readonly) NSDictionary* dontInjectReadOnly;
@property (atomic, strong) id<NSCopying> injectDictionaryByProtocol;
@property (atomic, strong, getter=_customGetter, setter=_customSetter:) NSDictionary* injectCustomSetter;
@property (atomic, strong) NSDictionary* dontInjectAlreadyHasAValue;
@property (atomic, strong) NSObject* dontInjectUnknownType;
@property (atomic, strong) NSArray* blockCanAlsoInject;
@property (atomic, strong) AutoInjectable* selfReferencingProperty;

@end

@implementation AutoInjectable
@end


@interface TestMinjection : XCTestCase

@end

@implementation TestMinjection

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - Tests for resolving

// Make sure querying a service that doesn't exist returns nil (no exception)
- (void)testEmptyContainerResolvesNil {
    MinjectionContainer* container = [[MinjectionContainer alloc] init];
    
    NSDictionary* service = [container resolveClass:[NSDictionary class]];
    XCTAssertNil(service, @"Somehow got a service out of an empty container");
}

// Make sure that a request for a class doesn't resolve to a subclass
- (void)testParentClassResolvesNil {
    MinjectionContainer* container = [[MinjectionContainer alloc] init];
    [container registerClass:[NSDictionary class] withInitializer:@selector(init) forClass:[NSDictionary class]];
    
    NSDictionary* service = [container resolveClass:[NSObject class]];
    XCTAssertNil(service, @"Somehow got a service out for the wrong type");
}

// Make sure that a request for a class doesn't resolve to a superclass
- (void)testChildClassResolvesNil {
    MinjectionContainer* container = [[MinjectionContainer alloc] init];
    [container registerClass:[NSObject class] withInitializer:@selector(init) forClass:[NSObject class]];
    
    NSDictionary* service = [container resolveClass:[NSDictionary class]];
    XCTAssertNil(service, @"Somehow got a service out for the wrong type");
}

// Make sure that a request for a class will resolve a new object specified by class
- (void)testSpecificClassResolvesClass {
    MinjectionContainer* container = [[MinjectionContainer alloc] init];
    [container registerClass:[NSDictionary class] withInitializer:@selector(init) forClass:[NSDictionary class]];
    
    NSDictionary* service = [container resolveClass:[NSDictionary class]];
    XCTAssertNotNil(service, @"No result resolving NSDictionary from class");
    
    XCTAssertTrue([service isKindOfClass: [NSDictionary class]], @"Service for an NSDictionary was not an NSDictionary");
}

// Make sure that a request for a class will resolve to a specific instance object when specified
- (void)testSpecificClassResolvesInstance {
    MinjectionContainer* container = [[MinjectionContainer alloc] init];
    NSDictionary* exampleDictionary = [NSDictionary dictionaryWithObject:@"OK" forKey:@"Status"];
    [container registerInstance:exampleDictionary forClass:[NSDictionary class]];
    
    NSDictionary* service = [container resolveClass:[NSDictionary class]];
    XCTAssertNotNil(service, @"No result resolving NSDictionary from class");
    
    XCTAssertTrue([service isKindOfClass: [NSDictionary class]], @"Service for an NSDictionary was not an NSDictionary");
    
    XCTAssertEqual(service, exampleDictionary, @"Service for an NSDictionary was not the same instance as provided");
    
    XCTAssertEqualObjects(service[@"Status"], @"OK", @"Service for an NSDictionary did not contain the expected key-value pair.");
}

// Make sure that a request for a class will resolve via a block when specified
- (void)testSpecificClassResolvesBlock {
    MinjectionContainer* container = [[MinjectionContainer alloc] init];
    [container registerBlock:^id(MinjectionContainer* container){
        return [NSDictionary dictionaryWithObject:@"OK" forKey:@"Status"];
    } forClass:[NSDictionary class]];
    
    NSDictionary* service = [container resolveClass:[NSDictionary class]];
    XCTAssertNotNil(service, @"No result resolving NSDictionary from class");
    
    XCTAssertTrue([service isKindOfClass: [NSDictionary class]], @"Service for an NSDictionary was not an NSDictionary");
    
    XCTAssertEqualObjects(service[@"Status"], @"OK", @"Service for an NSDictionary did not contain the expected key-value pair.");
}

// Make sure that you can't resolve a class by a protocol if it was registered for a class
- (void)testProtocolForClassResolvesNil {
    MinjectionContainer* container = [[MinjectionContainer alloc] init];
    [container registerClass:[NSDictionary class] withInitializer:@selector(init) forClass:[NSDictionary class]];
    
    NSDictionary* service = [container resolveProtocol:@protocol(NSCopying)];
    XCTAssertNil(service, @"Got a service for a protocol where none was expected");
}

// Make sure that a request for a class will resolve a new object specified by protocol
- (void)testSpecificProtocolResolvesClass {
    MinjectionContainer* container = [[MinjectionContainer alloc] init];
    [container registerClass:[NSDictionary class] withInitializer:@selector(init) forProtocol:@protocol(NSCopying)];
    
    NSDictionary* service = [container resolveProtocol:@protocol(NSCopying)];
    XCTAssertNotNil(service, @"No result resolving NSCopying from class");
    
    XCTAssertTrue([service isKindOfClass: [NSDictionary class]], @"Service for an NSCopying was not an NSDictionary");
}

// Make sure that a request for a class will resolve to an instance of an object when specified
- (void)testSpecificProtocolResolvesInstance {
    
    MinjectionContainer* container = [[MinjectionContainer alloc] init];
    NSDictionary* exampleDictionary = [NSDictionary dictionaryWithObject:@"OK" forKey:@"Status"];
    [container registerInstance:exampleDictionary  forProtocol:@protocol(NSCopying)];
    
    NSDictionary* service = [container resolveProtocol:@protocol(NSCopying)];
    XCTAssertNotNil(service, @"No result resolving NSDictionary from class");
    
    XCTAssertTrue([service isKindOfClass: [NSDictionary class]], @"Service for an NSDictionary was not an NSDictionary");
    
    XCTAssertEqual(service, exampleDictionary, @"Service for an NSDictionary was not the same instance as provided");
    
    XCTAssertEqualObjects(service[@"Status"], @"OK", @"Service for an NSDictionary did not contain the expected key-value pair.");
}

// Make sure that a request for a class will resolve with a block when specified 
- (void)testSpecificProtocolResolvesBlock {
    MinjectionContainer* container = [[MinjectionContainer alloc] init];
    [container registerBlock:^id(MinjectionContainer* container){
        return [NSDictionary dictionaryWithObject:@"OK" forKey:@"Status"];
    } forProtocol:@protocol(NSCopying)];
    
    NSDictionary* service = [container resolveProtocol:@protocol(NSCopying)];
    XCTAssertNotNil(service, @"No result resolving NSDictionary from class");
    
    XCTAssertTrue([service isKindOfClass: [NSDictionary class]], @"Service for an NSDictionary was not an NSDictionary");
    
    XCTAssertEqualObjects(service[@"Status"], @"OK", @"Service for an NSDictionary did not contain the expected key-value pair.");
}

#pragma mark - Tests for injecting

- (void) testAutoInjection {
    MinjectionContainer* container = [[MinjectionContainer alloc] init];
    
    NSDictionary* classDictionary = [NSDictionary dictionaryWithObject:@"Class" forKey:@"Type"];
    [container registerInstance:classDictionary forClass:[NSDictionary class]];
    
    NSDictionary* protocolDictionary = [NSDictionary dictionaryWithObject:@"Protocol" forKey:@"Type"];
    [container registerInstance:protocolDictionary forProtocol:@protocol(NSCopying)];
    
    
    [container registerBlock:^id(MinjectionContainer *container) {
        return @[
                    [container resolveClass:[NSDictionary class]],
                    [container resolveProtocol:@protocol(NSCopying)]
        ];
    } forClass:[NSArray class]];
    
    AutoInjectable* subject = [[AutoInjectable alloc] init];
    subject.dontInjectAlreadyHasAValue = [NSDictionary dictionaryWithObject:@"AlreadyAssigned" forKey:@"Type"];
    
    [container injectProperties:subject];
    
    
    //@property (atomic, strong) NSDictionary* injectDictionaryByClass;
    XCTAssertNotNil(subject.injectDictionaryByClass);
    XCTAssertEqualObjects(subject.injectDictionaryByClass[@"Type"], @"Class");
    
    //@property (atomic, strong, readonly) NSDictionary* dontInjectReadOnly;
    XCTAssertNil(subject.dontInjectReadOnly);
    
    //@property (atomic, strong) id<NSCopying> injectDictionaryByProtocol;
    XCTAssertNotNil(subject.injectDictionaryByProtocol);
    XCTAssertEqualObjects(subject.injectDictionaryByProtocol[@"Type"], @"Protocol");
    
    //@property (atomic, strong, getter=_customGetter, setter=_customSetter:) NSDictionary* injectCustomSetter;
    XCTAssertNotNil(subject.injectCustomSetter);
    XCTAssertEqualObjects(subject.injectCustomSetter[@"Type"], @"Class");
    
    //@property (atomic, strong) NSDictionary* dontInjectAlreadyHasAValue;
    XCTAssertNotNil(subject.dontInjectAlreadyHasAValue);
    XCTAssertEqualObjects(subject.dontInjectAlreadyHasAValue[@"Type"], @"AlreadyAssigned");
    
    //@property (atomic, strong) NSObject* dontInjectUnknownType;
    XCTAssertNil(subject.dontInjectUnknownType);
    
    //blockCanAlsoInject
    XCTAssertNotNil(subject.blockCanAlsoInject);
    XCTAssertEqual(subject.blockCanAlsoInject.count, 2);
    XCTAssertEqualObjects(subject.blockCanAlsoInject[0][@"Type"], @"Class");
    XCTAssertEqualObjects(subject.blockCanAlsoInject[1][@"Type"], @"Protocol");
    
}

- (void) testInjectWithCreation
{
    MinjectionContainer* container = [[MinjectionContainer alloc] init];
    [container registerWithOptions:[MinjectionOptions forClass:AutoInjectable.class
                                                 registerClass:[AutoInjectable class]
                                                      selector:@selector(init)
                                              registerInstance:nil
                                               registerFactory:nil
                                        shouldInjectProperties:YES
                                                      lifetime:MinjectionLifetimeCycle]];
    NSDictionary* classDictionary = [NSDictionary dictionaryWithObject:@"Class" forKey:@"Type"];
    [container registerInstance:classDictionary forClass:[NSDictionary class]];
    
    NSDictionary* protocolDictionary = [NSDictionary dictionaryWithObject:@"Protocol" forKey:@"Type"];
    [container registerInstance:protocolDictionary forProtocol:@protocol(NSCopying)];
    
    
    [container registerBlock:^id(MinjectionContainer *container) {
        return @[
                 [container resolveClass:[NSDictionary class]],
                 [container resolveProtocol:@protocol(NSCopying)]
                 ];
    } forClass:[NSArray class]];
    
    AutoInjectable* subject = [container resolveClass:AutoInjectable.class];
    
    //@property (atomic, strong) NSDictionary* injectDictionaryByClass;
    XCTAssertNotNil(subject.injectDictionaryByClass);
    XCTAssertEqualObjects(subject.injectDictionaryByClass[@"Type"], @"Class");
    
    //@property (atomic, strong, readonly) NSDictionary* dontInjectReadOnly;
    XCTAssertNil(subject.dontInjectReadOnly);
    
    //@property (atomic, strong) id<NSCopying> injectDictionaryByProtocol;
    XCTAssertNotNil(subject.injectDictionaryByProtocol);
    XCTAssertEqualObjects(subject.injectDictionaryByProtocol[@"Type"], @"Protocol");
    
    //@property (atomic, strong, getter=_customGetter, setter=_customSetter:) NSDictionary* injectCustomSetter;
    XCTAssertNotNil(subject.injectCustomSetter);
    XCTAssertEqualObjects(subject.injectCustomSetter[@"Type"], @"Class");
}

#pragma mark - Lifetime tests

// Make sure that a request for a class will resolve with a block when specified
- (void)testStaticLifetime
{
    MinjectionContainer* container = [[MinjectionContainer alloc] init];
    [container registerWithOptions:[MinjectionOptions forClass:AutoInjectable.class
                                                    registerClass:[AutoInjectable class]
                                                         selector:@selector(init)
                                                 registerInstance:nil
                                                  registerFactory:nil
                                           shouldInjectProperties:YES
                                                         lifetime:MinjectionLifetimeStatic]];
    
    AutoInjectable* service1 = [container resolveClass:AutoInjectable.class];
    AutoInjectable* service2 =  [container resolveClass:AutoInjectable.class];
    XCTAssertEqual(service1, service2, @"Service was not statically scoped");
    XCTAssertEqual(service1, service1.selfReferencingProperty, @"Service was not statically scoped");
}

- (void)testInstanceLifetime
{
    MinjectionContainer* container = [[MinjectionContainer alloc] init];
    [container registerWithOptions:[MinjectionOptions forClass:AutoInjectable.class
                                                    registerClass:[AutoInjectable class]
                                                         selector:@selector(init)
                                                 registerInstance:nil
                                                  registerFactory:nil
                                           shouldInjectProperties:NO
                                                         lifetime:MinjectionLifetimeInstance]];
    
    id service1 = [container resolveClass:AutoInjectable.class];
    id service2 =  [container resolveClass:AutoInjectable.class];
    XCTAssertNotEqual(service1, service2, @"Service was not instance scoped");
}

- (void)testCycleLifetime
{
    MinjectionContainer* container = [[MinjectionContainer alloc] init];
    [container registerWithOptions:[MinjectionOptions forClass:AutoInjectable.class
                                                 registerClass:[AutoInjectable class]
                                                      selector:@selector(init)
                                              registerInstance:nil
                                               registerFactory:nil
                                        shouldInjectProperties:YES
                                                      lifetime:MinjectionLifetimeCycle]];
    
    AutoInjectable* service1 = [container resolveClass:AutoInjectable.class];
    AutoInjectable* service2 =  [container resolveClass:AutoInjectable.class];
    XCTAssertNotEqual(service1, service2, @"Service was not cycle scoped");
    XCTAssertEqual(service1, service1.selfReferencingProperty, @"Service was not cycle scoped");
}


@end
