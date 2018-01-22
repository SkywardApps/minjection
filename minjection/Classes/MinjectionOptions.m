//
//  MinjectionOptions.m
//  Senio
//
//  Created by Nicholas Elliott on 12/29/17.
//  Copyright © 2017 Skyward App Company, LLC. All rights reserved.
//

#import "MinjectionOptions.h"

@implementation MinjectionOptions

/**
 * Standard initializer for empty options
 */
- (id) init
{
    if((self = [super init]))
    {
        _forClass = nil;
        _forProtocol = nil;
        
        _registerClass = nil;
        _registerClassInitializer = nil;
        _registerFactory = nil;
        _factoryDependencies = nil;
        _registerInstance = nil;
        
        _shouldInjectProperties = YES;
        _lifetime = MinjectionLifetimeUnknown;
    }
    return self;
}

/**
 * Static factory method exposing all options for providing a class
 */
+ (id) forClass:(Class)forClass
      registerClass:(Class)registerClass
           selector:(SEL)registerClassSelector
   registerInstance:(id)instance
    registerFactory:(FactoryMethodWithDependencies)factory
factoryDependencies:(NSDictionary<NSString*, id>*)dependencies
shouldInjectProperties:(BOOL)shouldInjectProperties
           lifetime:(MinjectionLifetime)lifetime
{
    MinjectionOptions* target;
    if((target = [[MinjectionOptions alloc] init]))
    {
        target->_forClass = forClass;
        
        target->_registerClass = registerClass;
        target->_registerClassInitializer = registerClassSelector;
        target->_registerFactory = factory;
        target->_factoryDependencies = dependencies;
        target->_registerInstance = instance;
        
        target->_shouldInjectProperties = shouldInjectProperties;
        target->_lifetime = lifetime;
    }
    return target;
}

/**
 * Static factory method exposing all options for providing a protocol
 */
+ (id)      forProtocol:(Protocol*)forProtocol
          registerClass:(Class)registerClass
               selector:(SEL)registerClassSelector
       registerInstance:(id)instance
        registerFactory:(FactoryMethodWithDependencies)factory
    factoryDependencies:(NSDictionary<NSString*, id>*)dependencies
 shouldInjectProperties:(BOOL)shouldInjectProperties
               lifetime:(MinjectionLifetime)lifetime
{
    MinjectionOptions* target;
    if((target = [[MinjectionOptions alloc] init]))
    {
        target->_forProtocol = forProtocol;
        
        target->_registerClass = registerClass;
        target->_registerClassInitializer = registerClassSelector;
        target->_registerFactory = factory;
        target->_factoryDependencies = dependencies;
        target->_registerInstance = instance;
        
        target->_shouldInjectProperties = shouldInjectProperties;
        target->_lifetime = lifetime;
    }
    return target;
    
}


@end
