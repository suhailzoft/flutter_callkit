#import "FlutterCallkitPlugin.h"
#if __has_include(<flutter_callkit/flutter_callkit-Swift.h>)
#import <flutter_callkit/flutter_callkit-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_callkit-Swift.h"
#endif

@implementation FlutterCallkitPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    [SwiftFlutterCallkitPlugin registerWithRegistrar:registrar];
}
@end