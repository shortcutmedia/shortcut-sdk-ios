

# Overview

This SDK provides basically two components that allow to interact with the Shortcut Image Recognition Service:
- The first component is a Scanner view that uses the camera to capture image data which then is submitted to the image recognition service. It reports image recognition results back to you.
- The second component is an Item view that displays a simple rendition of a (recognized) item.

You can easily combine these two components by using the Scanner view to get an item and then pass it on to the Item view to display it.

In addition to these two components the SDK also provides a lower-level interface to submit image recognition queries without using the scanner view.

The SDK works with iOS versions 6 to 8.

To see the SDK in action check out this [example app](https://github.com/shortcutmedia/shortcut-sdk-ios-example).


# Installation

The SDK consists of two parts: the code (packaged in a .framework file) and some resources (packaged in a .bundle file). To use it within your project follow these steps:

1. Download the latest SDK from the [SDK repo](https://github.com/shortcutmedia/shortcut-sdk-ios) (just download the file *ShortcutSDK.zip*, you do not need the source code).
2. Add the *ShortcutSDK.framework* and *ShortcutSDK.bundle* files to your project, e.g. by dragging them into your project in Xcode.
3. Within your project's **Build settings** add the `-ObjC` to **Other linker flags**.
4. Within your project's **Build phases** make sure that all following libraries are added in the **Link binary with libraries** section:
  - ShortcutSDK.framework
  - libiconv.dylib
  - libc++.dylib
5. Within your project's **Build phases** make sure that *ShortcutSDK.bundle* is added in the **Copy bundle resources** section.


# Getting started

To get a feeling for the different parts of the SDK this section walks you through the process of building a very simple app that displays the Scanner view on start up. When an item is recognized, the app dismisses the Scanner view and displays the recognized item in an Item view.

First, we have to create a new project in Xcode. Select the most basic of the available templates (In Xcode 6 this would be the *Single view application* template ) and follow the steps in the Installation section above.
You also need access keys, at the moment you have to request them by sending a mail to support@shortcutmedia.com.

We want to display a Scanner view as soon as the app starts; so let's go to the *AppDelegate.m* file and make the following changes:

**Step 1:** Import the ShortcutSDK framework at the top of the file:

```objective-c
#import <ShortcutSDK/ShortcutSDK.h>
```

**Step 2:** Change the implementation of the `application:didFinishLaunchingWithOptions:` method to the following:

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [SCMSDKConfig sharedConfig].accessKey = @"YOUR_ACCESS_KEY";
    [SCMSDKConfig sharedConfig].secretKey = @"YOUR_SECRET_KEY";

    SCMScannerViewController *scannerViewController = [[SCMScannerViewController alloc] init];
    scannerViewController.delegate = self;

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = scannerViewController;
    [self.window makeKeyAndVisible];

    return YES;
}
```

Within this bit of code you set up your access keys and a Scanner view. You then add the Scanner view to the main window and display it.
You get a warning in Xcode and if you run the app and point the scanner at an item that it recognizes then it crashes; so let's fix that.

**Step 3:** The Scanner view "communicates" with you via its delegate. In the code above we set the Scanner view delegate to the AppDelegate instance itself. For this to work correctly, the AppDelegate class must implement the `SCMScannerViewControllerDelegate` protocol. Change the interface of the AppDelegate class to the following:

```objective-c
@interface AppDelegate () <SCMScannerViewControllerDelegate>
```

You also have to add the following method to the class:

```objective-c
- (void)scannerViewController:(SCMScannerViewController *)scannerViewController recognizedQuery:(SCMQueryResponse *)response atLocation:(CLLocation *)location fromImage:(NSData *)imageData
{
    SCMQueryResult *result = [response.results firstObject];
    SCMItemViewController *itemViewController = [[SCMQueryResultViewController alloc] initWithQueryResult:result];

    self.window.rootViewController = itemViewController;
}
```

This method is called by the Scanner view whenever it recognized an item. In it, we grab the first result from the query response, instantiate an Item view with it and display the Item view in the app's main window.
If you run the app now and point the Scanner at an item it recognizes, then it should display this item.


# Reference

## Scanner view

The Scanner view is implemented as a UIKit view controller. You just have to instantiate it and present it somehow. It communicates back to you via a delegate.

#### Instantiating and presenting a Scanner view:

```objective-c
SCMScannerViewController *scannerViewController = [[SCMScannerViewController alloc] init];
scannerViewController.delegate = self;
[self.navigationController presentViewController:self.scannerViewController animated:YES completion:nil];

// additional configuration options
scannerViewController.helpView = someUIViewInstance; // displayed when the help button in the scanner is tapped
```


As soon as the Scanner view is visible it starts scanning and it reports important events to its delegate, i.e. when it recognized an item or when the user tapped the *Done* button.

#### Delegate interface:

```objective-c
@protocol SCMScannerViewControllerDelegate <NSObject>

@required
- (void)scannerViewController:(SCMScannerViewController*)scannerViewController recognizedQuery:(SCMQueryResponse*)response atLocation:(CLLocation*)location fromImage:(NSData*)imageData;

@optional
- (void)scannerViewController:(SCMScannerViewController*)scannerViewController recognizedQRCode:(NSString*)text atLocation:(CLLocation*)location;
- (void)scannerViewController:(SCMScannerViewController*)scannerViewController capturedSingleImageWhileOffline:(NSData*)imageData atLocation:(CLLocation*)location;

- (void)scannerViewControllerDidFinish:(SCMScannerViewController*)controller;

@end
```


You can also use the Scanner view to perform recognition of arbitrary image data that you have already captured somewhere else. This works in exactly the same way as when using the Snapshot mode, i.e. it also communicates back to you via the normal delegate methods.

#### Using a Scanner view to perform recognition of arbitrary image data:

```objective-c
NSData *imageData = ... // get image data from somewhere
[scannerViewController processImage:imageData];
```


## Item view

The Item view(s) are implemented as a UIKit view controller. You just have to instantiate it and present it somehow. You have two different ways to initialize it:
- You can use a SCMQueryResult instance obtained from a Scanner view or a Recognition operation
- You can use an item UUID

#### Instantiating item views

```objective-c
SCMQueryResult *queryResult = ... // obtain from scanner or recognition operation
SCMQueryResultViewController *resultViewController = [[SCMQueryResultViewController alloc] initWithQueryResult:queryResult];

NSString *itemUUID = ... // obtain item UUID
SCMItemViewController *itemViewController = [[SCMItemViewController alloc] initWithItemUUID:itemUUID];
```


## Recognition operation

A NSOperation subclass that does handle requests to the image recognition service is also available. To use it you just have to instantiate it with the image data to submit, provide a completion handler and then schedule it in an NSOperationQueue instance or start it manually.

#### Creating and submitting an image recognition request:

```objective-c
SCMRecognitionOperation* operation = [[SCMRecognitionOperation alloc] initWithImageData:imageData location:someCLLocation];

__weak SCMRecognitionOperation *finishedOperation = operation;
[operation setCompletionBlock:^{
  if (finishedOperation.results.count > 0) {
    NSLog(@"Hooray, recognized something...");
  }
}];

[someOperationQueue addOperation:operation];
```


## Configuration

There is a global configuration object available to customize some aspects of the SDK. However, it needs basically very little configuration.

#### Configuration parameters:

```objective-c

// required:
[SCMSDKConfig sharedConfig].accessKey = @"YOUR_ACCESS_KEY";
[SCMSDKConfig sharedConfig].secretKey = @"YOUR_SECRET_KEY";

// optional:
[SCMSDKConfig sharedConfig].clientID = @"some-unique-id-for-the-current-device";

// for internal/debugging purposes only:
[SCMSDKConfig sharedConfig].queryServerAddress = @"fake.query.server";
[SCMSDKConfig sharedConfig].itemServerAddress = @"fake.item.server";

```



# License
This project is released under the MIT license. See included LICENSE.txt file for details.

This project bundles parts of the zxing v2.0 library (https://github.com/zxing/zxing), which is available under an Apache-2.0 license. For details, see http://www.apache.org/licenses/LICENSE-2.0.
