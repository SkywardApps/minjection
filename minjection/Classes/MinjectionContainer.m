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
    NSMutableDictionary<NSString*, FactoryMethod>* _initializers;
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
        [instance performSelector:selector];
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
        [instance performSelector:selector];
        return instance;
    } copy]forKey:[self keyForProtocol:target]];
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
    
    // We create a factory method that handles the options requested
    FactoryMethod constructorMethod = [^(MinjectionContainer* container){
        // The simplest case is if an instance is provided.  We do nothing.
        if(options.registerInstance != nil)
            return options.registerInstance;
        
        id createdObject = nil;
        
        // First check our caches.  We have separate stores for cycle and static.
        if(options.lifetime == MinjectionLifetimeCycle)
        {
            createdObject = _chainCache[key];
            if(createdObject != nil)
                return createdObject;
        }
        else if(options.lifetime == MinjectionLifetimeStatic)
        {
            createdObject = _staticCache[key];
            if(createdObject != nil)
                return createdObject;
        }
        
        // Create the object as requested (factory or class instance)
        if(options.registerFactory != nil)
        {
            createdObject = options.registerFactory(container);
        }
        else if(options.registerClass != nil)
        {
            createdObject = [options.registerClass alloc];
            [createdObject performSelector:options.registerClassInitializer];
        }
        
        // If there is a specific lifecycle requested, make sure the generated object is stored in the right cache.
        // We do this before we inject any further properties so that common services are re-used (if the scope dictates they should).
        if(options.lifetime == MinjectionLifetimeCycle)
        {
            _chainCache[key] = createdObject;
        }
        else if(options.lifetime == MinjectionLifetimeStatic)
        {
            _staticCache[key] = createdObject;
        }
        
        // Now take the opportunity to inject into the object if needed.
        if(options.shouldInjectProperties)
        {
            [self injectProperties:createdObject];
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
        FactoryMethod method =_initializers[key];
        if(method != nil)
        {
            return method(self);
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

- (void) injectProperties:(id)target
{
    unsigned int numberOfProperties = 0;
    
    objc_property_t *propertyArray = class_copyPropertyList([target class], &numberOfProperties);
    
    for (NSUInteger i = 0; i < numberOfProperties; i++)
    {
        objc_property_t property = propertyArray[i];
        NSString *name = [[NSString alloc] initWithUTF8String:property_getName(property)];
        NSString *attributesString = [[NSString alloc] initWithUTF8String:property_getAttributes(property)];
        NSLog(@"Property %@ attributes: %@", name, attributesString);
        
        NSArray * attributes = [attributesString componentsSeparatedByString:@","];
        NSString * typeAttribute = attributes[0];
        NSString * propertyType = [typeAttribute substringFromIndex:1];
        
        if (![typeAttribute hasPrefix:@"T@"])
            continue;
        
        if([attributes[1] isEqualToString:@"R"])
            continue;
        
        NSLog(@"And can write to");
        
        id resolvedObject = nil;
        
        if([typeAttribute hasPrefix:@"T@\"<"])
        {
            // this is a protocol!
            NSLog(@"Appears to be a protocol!");
            NSString * typeProtocolName = [typeAttribute substringWithRange:NSMakeRange(4, typeAttribute.length-6)];  //turns @"<NSDate>" into NSDate
            Protocol* typeProtocol = NSProtocolFromString(typeProtocolName);
            if (typeProtocol == nil)
                continue;
            
            NSLog(@"Which we understood");
            
            if(![self canResolveProtocol:typeProtocol])
                continue;
            
            NSLog(@"And can resolve!");
            resolvedObject = [self resolveProtocol:typeProtocol];
        }
        else
        {
            NSLog(@"Appears to be a class");
            NSString * typeClassName = [typeAttribute substringWithRange:NSMakeRange(3, typeAttribute.length-4)];  //turns @"NSDate" into NSDate
            Class typeClass = NSClassFromString(typeClassName);
            if (typeClass == nil)
                continue;
            
            NSLog(@"Which we understood");
            
            if(![self canResolveClass:typeClass])
                continue;
        
            NSLog(@"And can resolve!");
            
            resolvedObject = [self resolveClass:typeClass];
        }
        
        if([target valueForKey:name] != nil)
            continue;
        
        // Find the setter
        NSLog(@"Was not already set, so injecting!");
        [target setValue:resolvedObject forKey:name];
        
    }
    free(propertyArray);
}

@end