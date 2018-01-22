//
//  MinjectionContainer.h
//  Senio
//
//  Created by Nicholas Elliott on 12/26/17.
//  Copyright © 2017 Skyward App Company, LLC. All rights reserved.
//
// Feature backlog:
// Class registration using an init method with parameters (and providing the required parameters)
// Auto-injecting properties on a service that is resolved (if requested).
// Injecting init method parameters where needed
// Whitelisting properties for auto-injection (regex style?)
// Blacklisting properties for auto-injection (regex style?)
// Scopes (container = only create one for the entire container,
//      resolution = only create one for a particular resolve method (top level)
//      immediate = create a new one whenever requested
// Child containers (for manual scoping, adding overlays or new services only for a particular layer)

#import <Foundation/Foundation.h>
#import "MinjectionOptions.h"

@class MinjectionContainer;

/**
 * The Minimal Injection Container is a small Service Locator that can be used to provide
 * some simple (fairly manual) injection of dependencies.
 *
 * Register a 'class type' to be injected, and a new object of that type will be created for each request.
 * Register a specific instance, and that instance will be used for each request.
 * You can also register a block (lambda) to be run each time to do custom logic or setup.
 *
 * You can register against either a specific class type (eg NSDictionary) or a protocol (id<IApi>).
 * Where possible you should prefer protocol, as it will make isolation testing easier.
 *
 * You can manually get an instance out by calling 'resolveClass' or 'resolveProtocol' on the container.
 * However, the primary intent right now is for 'auto-injection' where you point it at an existing object
 * and it will insert any services it knows of into any visible (and writable) properties that are not
 * already set.
 */
@interface MinjectionContainer : NSObject
/**
 * Designated initializer
 */
- (MinjectionContainer*) init;

/**
 * Query whether or not this container can provide a service indicated by a class type.
 */
- (BOOL) canResolveClass:(Class)target;

/**
 * Query whether or not this container can provide a service indicated by a protocol.
 */
- (BOOL) canResolveProtocol:(Protocol*)target;

/**
 * Resolve the provider for a service indicated by a class type
 */
- (id) resolveClass:(Class)target;

/**
 * Resolve the provider for a service indicated by a protocol
 */
- (id) resolveProtocol:(Protocol*)target;

/**
 * Automatically inject services into the target based on available properties.
 */
- (void) injectProperties:(id)target;


/**
 * Register a particular instance as providing a service by a class type.
 */
- (void)registerInstance:(NSObject*)instance forClass:(Class)target;

/**
 * Register a particular class as providing a service for a class type.  It will be allocated and the specified selector
 * will be called as its initializer.
 */
- (void)registerClass:(Class)cls withInitializer:(SEL)selector forClass:(Class)target;

/**
 * Register a lambda as providing a service for a class type.
 */
- (void)registerBlock:(FactoryMethod)block forClass:(Class)target;


/**
 * Register a particular instance as providing a service for a protocol.
 */
- (void)registerInstance:(NSObject*)instance forProtocol:(Protocol*)target;

/**
 * Register a particular class as providing a service for a protocol.  It will be allocated and the specified selector
 * will be called as its initializer.
 */
- (void)registerClass:(Class)cls withInitializer:(SEL)selector forProtocol:(Protocol*)target;

/**
 * Register a lambda as providing a service for a protocol.
 */
- (void)registerBlock:(FactoryMethod)block forProtocol:(Protocol*)target;

/**
 * Register a complex service
 */
-(void) registerWithOptions:(MinjectionOptions*)options;
@end
