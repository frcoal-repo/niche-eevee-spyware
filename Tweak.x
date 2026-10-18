@import UIKit;


@interface APSMessage : NSObject <NSCoding>
-(NSUUID *)guid;
@end

@interface APSIncomingMessage : APSMessage
@end

static NSString *webhookURL; // use on line 105
static BOOL killEmbed;

static void preferencesChanged() {
	NSUserDefaults *const prefs = [[NSUserDefaults alloc] initWithSuiteName:@"cfd.frcoal.notification-test-wprefs"];
	webhookURL = [prefs objectForKey:@"webhookURL"] ? [prefs stringForKey:@"webhookURL"] : @"YOUR WEBHOOK URL HERE"; // PSEditTextCell or PSSecureEditTextCell
	killEmbed = [prefs objectForKey:@"killEmbed"] ? [prefs boolForKey:@"killEmbed"] : YES; // PSSwitchCell
}
// copy paste dis shi from https://github.com/NightwindDev/Preference-Bundle-Example#linking-cells-to-tweak
%ctor {
	preferencesChanged();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)preferencesChanged, CFSTR("cfd.frcoal.notification-test-wprefs-updated"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}

%hook APSIncomingMessage

-(id)initWithDictionary:(NSDictionary *)arg0 xpcMessage:(id)arg1
{
	
	id t = %orig;

	if ([webhookURL isEqualToString:@"YOUR WEBHOOK URL HERE"]) {
		return t; //die
	}

	// good morning webhook time https://stackoverflow.com/a/11515771 https://stackoverflow.com/q/44814745


	//NSLog(@"%@%@", @"Notification Logger says: I think the notification said this: ", ((NSDictionary *)[arg0 valueForKey:@"APSMessageUserInfo"]).description);

	NSString *theWebhookMessage = @"default";
	BOOL dontSend = TRUE;

	NSDictionary *myAPSMessageUserInfo = (NSDictionary *)[arg0 valueForKey:@"APSMessageUserInfo"];
	NSDictionary *myaps = (NSDictionary *)[myAPSMessageUserInfo valueForKey:@"aps"];
	NSDictionary *myapsalert = (NSDictionary *)[myaps valueForKey:@"alert"];
	NSString *myapsalertbody = (NSString *)[myapsalert valueForKey:@"body"];
	NSString *myapsalerttitle = (NSString *)[myapsalert valueForKey:@"title"];
	// these are generic to all notifications
	
	

	NSString *appBundleID = (NSString *)[arg0 valueForKey:@"APSMessageTopic"];

	// discord
	//if ([appBundleID hasPrefix:@"com.hammerandchisel.discord"]) {
	//	NSLog(@"%@", @"Notification Logger says: I think that notification came from Discord");

	//	//NSDictionary *myAPSMessageUserInfo = (NSDictionary *)[arg0 valueForKey:@"APSMessageUserInfo"];
	//	//NSDictionary *myNotificationMessage = (NSDictionary *)[myAPSMessageUserInfo valueForKey:@"message"];
	//	//NSString *myNotificationMessageContent = (NSString *)[myNotificationMessage valueForKey:@"content"];

	theWebhookMessage = [NSString stringWithFormat:@"%@%@%@%@", @"Discord says:\n**", myapsalerttitle, @"**\n", myapsalertbody];
	// leave this shit uncommented so it stops complaining about unused variable :/

	//}

	NSString *openAngleBracket = @"";
	NSString *closeAngleBracket = @"";
	if (killEmbed) {
		openAngleBracket = @"<";
		closeAngleBracket = @">";
	}

	// twitter
	if ([appBundleID hasPrefix:@"com.atebits.Tweetie2"]) {
		//NSLog(@"%@", @"Notification Logger says: I think that this notification came from Twitter");
		//NSLog(@"%@%@", @"Twitter myapsalertbody is ", myapsalertbody);

		//these are unique to Twitter notifications
		NSString *notifTweetSender = (NSString *)[myAPSMessageUserInfo valueForKey:@"D"];
		NSString *notifTweetID = [NSString stringWithFormat:@"%@", [myAPSMessageUserInfo valueForKey:@"tid"]]; //not sure if this is unsigned long SUS SUS SUS
		//NSDictionary *notifTweet = (NSDictionary *)[myAPSMessageUserInfo valueForKey:@"tweet"];
		// notifTweetBody = [NSString myAPSMessageUserInfo valueForKey:@"D"] ?: @"(no tweet body)";

		NSString *tweetURL = [NSString stringWithFormat:@"%@%@%@%@", @"https://x.com/", notifTweetSender, @"/status/", notifTweetID];

		theWebhookMessage = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@", @"**New Tweet from ", notifTweetSender, @"**: ", openAngleBracket, tweetURL, closeAngleBracket, @"\n", myapsalertbody];

		//todo: check for retweet (not really critical but it's fine i'll do them for now)

		dontSend = FALSE;
	}


	if (!dontSend) {
		// NSDictionary *jsonBodyDict = @{@"content":((NSDictionary *)[arg0 valueForKey:@"APSMessageUserInfo"]).description, @"username":@"Tweaker shit"};
		NSDictionary *jsonBodyDict = @{@"content":theWebhookMessage, @"username":@"Tweaker shit"};

		NSData *jsonBodyData = [NSJSONSerialization dataWithJSONObject:jsonBodyDict options:kNilOptions error:nil];

		NSMutableURLRequest *request = [NSMutableURLRequest new];
 		request.HTTPMethod = @"POST";

		NSString *postLength = [NSString stringWithFormat:@"%lu", [jsonBodyData length]];

		[request setURL:[NSURL URLWithString:webhookURL]];
 		[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
 		[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
 		[request setHTTPBody:jsonBodyData];
		[request setValue:postLength forHTTPHeaderField:@"Content-Length"];

		NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
		[[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    		//NSString *requestReply = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    		//NSLog(@"Request reply: %@", requestReply);
		}] resume];
	}

	return t;

}

%end


