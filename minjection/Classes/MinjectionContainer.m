//
//  MinjectionContainer.m
//  Senio
//
//  Created by Nicholas Elliott on 12/26/17.
//  Copyright © 2017 Skyward App Company, LLC. All rights reserved.
//

#import "MinjectionContainer.h"
#import <objc/runtime.h>


@interface MinjectionContainer ()
{
    /// Our factories for providing services
    NSMutableDictionary<NSString*, FactoryMethodWithDependencies>* _initializers;
    /// Our cache of services generated for this container
    NSMutableDictionary<NSString*, id>* _staticCache;
    /// Our cache of services generated in this dependency chain
    NSMutableDictionary<NSString*, id>* _chainCache;
}

@end

@implementation MinjectionContainer

- (instancetype) init {
    self = [super init];
    
    _initializers = @{}.mutableCopy;
    _staticCache = @{}.mutableCopy;
    
    // Allow objects to get their spawning container if required.
    [self registerInstance:self forClass:MinjectionContainer.class];
    
    return self;
}

- (void)registerInstance:(NSObject*)instance forClass:(Class)target
{
    [_initializers setValue:[^(){
        return instance;
    } copy] forKey:[self keyForClass:target]];
}

- (void)registerClass:(Class)cls withInitializer:(SEL)selector forClass:(Class)target
{
    [_initializers setValue:[^(){
        id instance = [cls alloc];
        
        IMP imp = [instance methodForSelector:selector];
        void (*func)(id, SEL) = (void *)imp;
        func(instance, selector);
        
        return instance;
    } copy] forKey:[self keyForClass:target]];
    
}

- (void)registerBlock:(FactoryMethod)block forClass:(Class)target
{
    [_initializers setValue:[block copy] forKey:[self keyForClass:target]];
}

- (BOOL) canResolveClass:(Class)target
{
    return _initializers[[self keyForClass:target]] != nil;
}


- (void)registerInstance:(NSObject*)instance forProtocol:(Protocol*)target
{
    [_initializers setValue:[^(){
        return instance;
    } copy] forKey:[self keyForProtocol:target]];
}

- (void)registerClass:(Class)cls withInitializer:(SEL)selector forProtocol:(Protocol*)target
{
    [_initializers setValue:[^(){
        id instance = [cls alloc];
        
        IMP imp = [instance methodForSelector:selector];
        void (*func)(id, SEL) = (void *)imp;
        func(instance, selector);
        
        return instance;
    } copy] forKey:[self keyForProtocol:target]];
}

- (void)registerBlock:(FactoryMethod)block forProtocol:(Protocol*)target
{
    [_initializers setValue:[block copy] forKey:[self keyForProtocol:target]];
}

/**
 * Register a complex service
 */
-(void) registerWithOptions:(MinjectionOptions*)options
{
    NSString* key;
    if(options.forProtocol != nil)
        key = [self keyForProtocol:options.forProtocol];
    else if(options.forClass != nil)
        key = [self keyForClass:options.forClass];
    
    // Remove any pre-existing versions of these items
    if(options.lifetime == MinjectionLifetimeCycle)
    {
        if(_chainCache[key] != nil)
           [_chainCache removeObjectForKey:key];
    }
    else if(options.lifetime == MinjectionLifetimeStatic)
    {
        if(_staticCache[key] != nil)
           [_staticCache removeObjectForKey:key];
    }
    
    // We create a factory method that handles the options requested
    FactoryMethodWithDependencies constructorMethod = [^(MinjectionContainer* container){
        // The simplest case is if an instance is provided.  We do nothing.
        if(options.registerInstance != nil)
            return options.registerInstance;
        
        id createdObject = nil;
        
        // First check our caches.  We have separate stores for cycle and static.
        if(options.lifetime == MinjectionLifetimeCycle)
        {
            createdObject = self->_chainCache[key];
            if(createdObject != nil)
                return createdObject;
        }
        else if(options.lifetime == MinjectionLifetimeStatic)
        {
            createdObject = self->_staticCache[key];
            if(createdObject != nil)
                return createdObject;
        }
        
        // Create the object as requested (factory or class instance)
        if(options.registerFactory != nil)
        {
            NSMutableDictionary* dict = @{}.mutableCopy;
            for(NSString* key in options.factoryDependencies.allKeys)
            {
                if([NSStringFromClass([options.factoryDependencies[key] class]) isEqualToString:@"Protocol"])
                {
                    dict[key] = [self resolveProtocol:options.factoryDependencies[key]];
                }
                else
                {
                    dict[key] = [self resolveClass:options.factoryDependencies[key]];
                }
            }
            createdObject = options.registerFactory(container, dict);
        }
        else if(options.registerClass != nil)
        {
            createdObject = [options.registerClass alloc];
            
            IMP imp = [createdObject methodForSelector:options.registerClassInitializer];
            void (*func)(id, SEL) = (void *)imp;
            func(createdObject, options.registerClassInitializer);
        }
        
        // If there is a specific lifecycle requested, make sure the generated object is stored in the right cache.
        // We do this before we inject any further properties so that common services are re-used (if the scope dictates they should).
        if(options.lifetime == MinjectionLifetimeCycle)
        {
            self->_chainCache[key] = createdObject;
        }
        else if(options.lifetime == MinjectionLifetimeStatic)
        {
            self->_staticCache[key] = createdObject;
        }
        
        // Now take the opportunity to inject into the object if needed.
        if(options.shouldInjectProperties)
        {
            [self injectProperties:createdObject];
        }
        
        if(options.postInjectionExecutor != nil)
        {
            options.postInjectionExecutor(createdObject, self);
        }
        
        return createdObject;
    } copy];
    
    [_initializers setValue:constructorMethod forKey:key];
}

- (BOOL) canResolveProtocol:(Protocol*)target
{
    return _initializers[[self keyForProtocol:target]] != nil;
}

- (id) resolveClass:(Class)target
{
    return [self resolve:[self keyForClass:target]];
}

- (id) resolveProtocol:(Protocol*)target
{
    return [self resolve:[self keyForProtocol:target]];
}

- (id) resolve:(NSString*)key
{
    // We need to handle 'chain' lifecycles here.  Basically this means that down the entire call stack from here,
    // we will re-use these services.
    // So we create the cache if we are at the top of the stack, and then clear it when we leave the stack.
    BOOL removeChainCache = NO;
    if(_chainCache == nil)
    {
        removeChainCache = YES;
        _chainCache = @{}.mutableCopy;
    }
    
    @try
    {
        // Generate the service -- this can take advantage of any chain-lifecycle services now.
        FactoryMethodWithDependencies method =_initializers[key];
        if(method != nil)
        {
            return method(self, nil);
        }
    }
    @finally
    {
        // If we created the cache at this level, clear it (so we don't hold on to any objects past when they are used).
        if(removeChainCache)
        {
            _chainCache = nil;
        }
    }
    
    return nil;
}

- (NSString*) keyForClass:(Class)target
{
    return [NSString stringWithFormat:@"CLASS:%@",NSStringFromClass(target)];
}

- (NSString*) keyForProtocol:(Protocol*)target
{
    return [NSString stringWithFormat:@"PROTOCOL:%@",NSStringFromProtocol(target)];
}

- (id)attemptToResolveProtocolName:(NSString *)typeProtocolName {
    Protocol* typeProtocol = NSProtocolFromString(typeProtocolName);
    if (typeProtocol == nil)
        return nil;
    
    
    if(![self canResolveProtocol:typeProtocol])
        return nil;
    
    return [self resolveProtocol:typeProtocol];
}

- (id)attemptToResolveClassName:(NSString *)typeClassName {
    Class typeClass = NSClassFromString(typeClassName);
    if (typeClass == nil)
        return nil;
    
    if(![self canResolveClass:typeClass])
        return nil;
    
    return [self resolveClass:typeClass];
}

- (void) injectProperties:(id)target
{
    unsigned int numberOfProperties = 0;
    
    objc_property_t *propertyArray = class_copyPropertyList([target class], &numberOfProperties);
    
    for (NSUInteger i = 0; i < numberOfProperties; i++)
    {
        objc_property_t property = propertyArray[i];
        NSString *name = [[NSString alloc] initWithUTF8String:property_getName(property)];
        NSString *attributesString = [[NSString alloc] initWithUTF8String:property_getAttributes(property)];
        
        NSArray *attributes = [attributesString componentsSeparatedByString:@","];
        NSString *typeAttribute = attributes[0];
        
        if (![typeAttribute hasPrefix:@"T@"])
            continue;
        
        if([attributes[1] isEqualToString:@"R"])
            continue;
        
        id resolvedObject = nil;
        
        if([typeAttribute hasPrefix:@"T@\"<"])
        {
            // this is a protocol!
            NSString * typeProtocolName = [typeAttribute substringWithRange:NSMakeRange(4, typeAttribute.length-6)];  //turns @"<NSDate>" into NSDate
            resolvedObject = [self attemptToResolveProtocolName:typeProtocolName];
        }
        else if([typeAttribute rangeOfString:@"<"].location == NSNotFound)
        {
            NSString * typeClassName = [typeAttribute substringWithRange:NSMakeRange(3, typeAttribute.length-4)];  //turns @"NSDate" into NSDate
            resolvedObject = [self attemptToResolveClassName:typeClassName];
        }
        else
        {
            // both cases apply here!
            NSInteger locationOfProtocol = [typeAttribute rangeOfString:@"<"].location;
            NSInteger locationOfProtocolEnd = [typeAttribute rangeOfString:@">"].location;
            NSString* typeProtocolName = [typeAttribute substringWithRange:NSMakeRange(locationOfProtocol+1, locationOfProtocolEnd-locationOfProtocol-1)];
            resolvedObject = [self attemptToResolveProtocolName:typeProtocolName];
            
            if(resolvedObject == nil)
            {
                NSInteger locationOfClass = [typeAttribute rangeOfString:@"\""].location;
                NSString* typeClassName = [typeAttribute substringWithRange:NSMakeRange(locationOfClass+1, locationOfProtocol-locationOfClass-1)];
                resolvedObject = [self attemptToResolveClassName:typeClassName];
            }
            
        }
        
        if(resolvedObject == nil)
            continue;
        
        if([target valueForKey:name] != nil)
            continue;
        
        // Find the setter
        [target setValue:resolvedObject forKey:name];
        
    }
    free(propertyArray);
}

@end
