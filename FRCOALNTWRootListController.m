#import <Foundation/Foundation.h>
#import "FRCOALNTWRootListController.h"

@implementation FRCOALNTWRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

@end
