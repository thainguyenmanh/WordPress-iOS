#import "ScreenshotSetupCoordinator.h"

#ifdef IS_GENERATING_SCREENSHOTS
    #if IS_GENERATING_SCREENSHOTS
        #import "SDStatusBarManager.h"
    #endif
#endif

@implementation ScreenshotSetupCoordinator

/// `prepare` uses SimulatorStatusBarMagic to properly set the status bar values while
/// generating screenshots. For release builds, this should compile down to a no-op.
+(void)prepare{
    #ifdef IS_GENERATING_SCREENSHOTS
        #if IS_GENERATING_SCREENSHOTS
            [[SDStatusBarManager sharedInstance] enableOverrides];
        #endif
    #endif
}

@end

