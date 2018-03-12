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
        _postInjectionExecutor = nil;
        
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

- (id)initForClass:(Class)forClass
{
    if((self = [self init]))
    {
        _forClass = forClass;
    }
    return self;
}

- (id)initForProtocol:(Protocol *)forProtocol
{
    if((self = [self init]))
    {
        _forProtocol = forProtocol;
    }
    return self;
}

- (void)provideWithClass:(Class)cls initializer:(SEL)initializer
{
    _registerClass = cls;
    _registerClassInitializer = initializer;
}

- (void)provideWithFactory:(FactoryMethodWithDependencies)factory dependencies:(NSDictionary<NSString *,id> *)dependencies
{
    _registerFactory = factory;
    _factoryDependencies = dependencies;
}

/**
 * Helper methods to set up post-injection executor.
 */
- (void) postInjectWithBlock:(PostInjection)executor
{
    self.postInjectionExecutor = [executor copy];
}

/**
 * Helper methods to set up post-injection selector to be called on the created object.
 */
- (void) postInjectWithSelector:(SEL)sel
{
    self.postInjectionExecutor = [^(id target, MinjectionContainer * container) {
        if([target respondsToSelector:sel])
        {
            IMP imp = [target methodForSelector:sel];
            void (*func)(id, SEL) = (void *)imp;
            func(target, sel);
        }
        else
        {
            NSLog(@"Warning: Set up for post injection selector %@ but it was not found on the target object.", NSStringFromSelector(sel));
        }
    } copy];
    
}

@end
