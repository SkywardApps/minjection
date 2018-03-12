//
//  MinjectionOptions.h
//  Senio
//
//  Created by Nicholas Elliott on 12/29/17.
//  Copyright © 2017 Skyward App Company, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MinjectionContainer;
/**
 * The block types we use as factory methods.
 */
typedef id(^FactoryMethod)(MinjectionContainer*);
typedef id(^FactoryMethodWithDependencies)(MinjectionContainer*, NSDictionary<NSString*,id>*);

/**
 * The block types we use for post-injection notification
 */
typedef void(^PostInjection)(id,MinjectionContainer*);

/**
 * Control how long an instance is used within the container.
 */
typedef enum {
    /**
     * Default value indicating no specific lifetime was provided
     */
    MinjectionLifetimeUnknown = 0,
    /**
     * A new instance of the service should be created every time it is requested.
     */
    MinjectionLifetimeInstance,
    /**
     * A single instance is provided for a dependency chain (ie per top-level resolve call).
     */
    MinjectionLifetimeCycle,
    /**
     * A single instance is provided for all calls within this container.
     */
    MinjectionLifetimeStatic
} MinjectionLifetime;

/**
 * Define all options for more complex registrations
 */
@interface MinjectionOptions : NSObject

#pragma mark - Static factory methods

+ (id)      forClass:(Class)forClass
       registerClass:(Class)registerClass
            selector:(SEL)registerClassSelector
    registerInstance:(id)instance
     registerFactory:(FactoryMethodWithDependencies)factory
 factoryDependencies:(NSDictionary<NSString*, id>*)dependencies
shouldInjectProperties:(BOOL)shouldInjectProperties
            lifetime:(MinjectionLifetime)lifetime
            __deprecated;


+ (id)      forProtocol:(Protocol*)forProtocol
          registerClass:(Class)registerClass
               selector:(SEL)registerClassSelector
       registerInstance:(id)instance
        registerFactory:(FactoryMethodWithDependencies)factory
    factoryDependencies:(NSDictionary<NSString*, id>*)dependencies
 shouldInjectProperties:(BOOL)shouldInjectProperties
               lifetime:(MinjectionLifetime)lifetime
                __deprecated;

#pragma mark - Constructor methods

/**
 * Create an options collection to provide a class
 */
- (id) initForClass:(Class)forClass;

/**
 * Create an options collection to provide a protocol
 */
- (id) initForProtocol:(Protocol*)forProtocol;

#pragma mark - Service description

/**
 * The class service this provides.  Mutually exclusive with forProtocol.
 */
@property Class forClass;

/**
 * The protocol service this provides.  Mutually exclusive with forClass.
 */
@property Protocol* forProtocol;

#pragma mark -- Creation methods

#pragma mark - Class instantiation method

/**
 * The class type this will instantiate for fulfillment of the service.
 * Mutually exclusive with registerInstance and registerFactory.
 */
@property Class registerClass;

/**
 * The class initializer this will use to instantiate the service.
 * Mutually exclusive with registerInstance and registerFactory.
 */
@property SEL registerClassInitializer;

/**
 * Helper method to set up class instantiation fulfillment
 */
- (void) provideWithClass:(Class)cls initializer:(SEL)initializer;

#pragma mark - Pre-existing instance method

/**
 * The single instance this will provide.
 * Mutually exclusive with registerClass and registerFactory.
 */
@property id registerInstance;

#pragma mark - Factory method

/**
 * The factory block method this will use to instantiate the service.
 * Mutually exclusive with registerClass and registerInstance.
 */
@property FactoryMethodWithDependencies registerFactory;

/**
 * Any dependencies to fill and pass into the factory.
 * Only valid with registerFactory
 */
@property NSDictionary<NSString*,id>* factoryDependencies;

/**
 * Helper method to set up factory creation fulfillment
 */
- (void) provideWithFactory:(FactoryMethodWithDependencies)factory dependencies:(NSDictionary<NSString*,id>*)dependencies;

#pragma mark - Post injection behavior

/**
 * A block to perform any post-injection work.
 */
@property PostInjection postInjectionExecutor;

/**
 * Helper methods to set up post-injection executor.
 */
- (void) postInjectWithBlock:(PostInjection)executor;

/**
 * Helper methods to set up post-injection selector to be called on the created object.
 */
- (void) postInjectWithSelector:(SEL)sel;

#pragma mark - Behaviour controls

/**
 * After instantiation, should we attempt to auto-inject dependencies?
 * Not valid with registerInstance.
 */
@property BOOL shouldInjectProperties;

/// The below are on the feature backlog but not used currently; removed so no one thinks they are available yet but kept to record the design planned.
//@property NSArray<NSString*>* whitelistProperties;
//@property NSArray<NSString*>* blacklistProperties;

/**
 * What is the lifetime of a created instance?
 * Not valid with registerInstance.
 */
@property MinjectionLifetime lifetime;

#pragma mark -

@end
