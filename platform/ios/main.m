#define SDL_MAIN_HANDLED
#include "SDL.h"
#include "SDL_main.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <stdio.h>
#include <dirent.h>
#include <stddef.h>
#include <TargetConditionals.h>
#include <unistd.h>

extern int SRGameMain(int argc, char **argv, char **envp);
extern char **environ;

#if TARGET_OS_SIMULATOR && defined(__x86_64__)
// This pinned FPC RTL imports the macOS inode64 alias on Intel simulators.
// iOS exposes the same directory record through the unversioned entry point.
_Static_assert(offsetof(struct dirent, d_name) == 21, "FPC dirent layout mismatch");
struct dirent *SRReadDirectory(DIR *directory) __asm("_readdir$INODE64");
struct dirent *SRReadDirectory(DIR *directory) { return readdir(directory); }
#endif

static int RunGame(int argc, char **argv) {
    @autoreleasepool {
        NSFileManager *files = NSFileManager.defaultManager;
        NSString *documents =
            NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)
                .firstObject;
        NSString *game = [documents stringByAppendingPathComponent:@"Game"];
        NSString *profile = [NSHomeDirectory()
            stringByAppendingPathComponent:@"Library/Application Support/SpaceRangersHD"];
        [files createDirectoryAtPath:game withIntermediateDirectories:YES attributes:nil error:nil];
        [files createDirectoryAtPath:profile
            withIntermediateDirectories:YES
                             attributes:nil
                                  error:nil];
        // Establish the sandbox paths before FPC initializes any game units.
        if (chdir(game.fileSystemRepresentation) != 0) {
            SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Space Rangers HD",
                                     "Cannot open the Game folder.", NULL);
            return 1;
        }
        BOOL hasInstall = NO;
        for (NSString *name in [files contentsOfDirectoryAtPath:game error:nil]) {
            if ([name caseInsensitiveCompare:@"INSTALL.TXT"] == NSOrderedSame)
                hasInstall = YES;
        }
        if (!hasInstall) {
            SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_INFORMATION, "Space Rangers HD",
                                     "Copy your Space Rangers HD game files into the Game folder "
                                     "inside this app in Files, then restart the app.",
                                     NULL);
            return 0;
        }
        freopen([[profile stringByAppendingPathComponent:@"launcher.log"] fileSystemRepresentation],
                "a", stderr);
        char density[32];
        snprintf(density, sizeof(density), "%.4g", UIScreen.mainScreen.scale);
        SDL_SetHint("SRHD_UI_DENSITY", density);
        char slop[32];
        snprintf(slop, sizeof(slop), "%d", (int)(8 * UIScreen.mainScreen.scale));
        SDL_SetHint("SRHD_TOUCH_SLOP", slop);
        return SRGameMain(argc, argv, environ);
    }
}

int main(int argc, char **argv) { return SDL_UIKitRunApp(argc, argv, RunGame); }
