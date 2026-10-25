@import UIKit;


@interface APSMessage : NSObject <NSCoding>
-(NSUUID *)guid;
@end

@interface APSIncomingMessage : APSMessage
@end

static NSString *webhookURL; // use on line 105
static BOOL killEmbed;
static NSInteger embedFixerInt;

static void preferencesChanged() {
	NSUserDefaults *const prefs = [[NSUserDefaults alloc] initWithSuiteName:@"cfd.frcoal.notification-test-wprefs"];
	webhookURL = [prefs objectForKey:@"webhookURL"] ? [prefs stringForKey:@"webhookURL"] : @"YOUR WEBHOOK URL HERE"; // PSEditTextCell or PSSecureEditTextCell
	killEmbed = [prefs objectForKey:@"killEmbed"] ? [prefs boolForKey:@"killEmbed"] : NO; // PSSwitchCell
	embedFixerInt = [prefs objectForKey:@"embedFixerInt"] ? [prefs integerForKey:@"embedFixerInt"] : 0;
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
		NSDictionary *notifTweet = (NSDictionary *)[myAPSMessageUserInfo valueForKey:@"tweet"];
		// notifTweetBody = [NSString myAPSMessageUserInfo valueForKey:@"D"] ?: @"(no tweet body)";

		BOOL isRetweet = (NSDictionary *)[notifTweet valueForKey:@"retweeted_tweet"] ? YES : NO;

		NSString *actualSender = notifTweetSender;
		if (isRetweet) {
			NSDictionary *retweetedTweet = (NSDictionary *)[notifTweet valueForKey:@"retweeted_tweet"];
			NSDictionary *retweetedTweetAuthor = (NSDictionary *)[retweetedTweet valueForKey:@"author"];
			actualSender = (NSString *)[retweetedTweetAuthor valueForKey:@"screen_name"]; // not sure which style of handling i like better, i might find a reason to retain the old value here
			notifTweetID = (NSString *)[retweetedTweet valueForKey:@"id"]; // replace retweet id with actual tweet id
			
		}

		NSString *embedFixerDomain = @"x.com";
		//NSLog(@"%@%ld", @"Notification Logger says: The current embed fixer is ", embedFixerInt);
		if (embedFixerInt==1) { // yanderedev save me i don't know how to use switch cases in obj c
			embedFixerDomain = @"fxtwitter.com";
		} else if (embedFixerInt==2) {
			embedFixerDomain = @"vxtwitter.com";
		}

		NSString *tweetURL = [NSString stringWithFormat:@"%@%@%@%@%@%@", @"https://", embedFixerDomain, @"/", actualSender, @"/status/", notifTweetID];

		NSString *newTweetText = isRetweet ? @"**New Retweet from " : @"**New Tweet from ";
		theWebhookMessage = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@", newTweetText, notifTweetSender, @"**: ", openAngleBracket, tweetURL, closeAngleBracket, @"\n", myapsalertbody];

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


