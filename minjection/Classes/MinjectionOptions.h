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
            lifetime:(MinjectionLifetime)lifetime;


+ (id)      forProtocol:(Protocol*)forProtocol
          registerClass:(Class)registerClass
               selector:(SEL)registerClassSelector
       registerInstance:(id)instance
        registerFactory:(FactoryMethodWithDependencies)factory
    factoryDependencies:(NSDictionary<NSString*, id>*)dependencies
 shouldInjectProperties:(BOOL)shouldInjectProperties
               lifetime:(MinjectionLifetime)lifetime;

#pragma mark - Service description

/**
 * The class service this provides.  Mutually exclusive with forProtocol.
 */
@property Class forClass;

/**
 * The protocol service this provides.  Mutually exclusive with forClass.
 */
@property Protocol* forProtocol;

#pragma mark - Creation methods

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
 * The single instance this will provide.
 * Mutually exclusive with registerClass and registerFactory.
 */
@property id registerInstance;

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
