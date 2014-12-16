# Overview

This SDK provides basically two components that allow to interact with the Shortcut Image Recognition Service:
- The first component is a Scanner view that uses the camera to capture image data which then is submitted to the image recognition service. It reports image recognition results back to you.
- The second component is an Item view that displays a simple rendition of a (recognized) item.

You can easily combine these two components by using the Scanner view to get an item and then pass it on to the Item view to display it.

In addition to these two components the SDK also provides a lower-level interface to submit image recognition queries without using the scanner view.

# Scanner view

The Scanner view is implemented as a UIKit view controller. You just have to instantiate it and present it somehow. It communicates back to you via a delegate.

#### Instantiating and presenting a Scanner view:

```objective-c
SCMCameraViewController *cameraViewController = [[SCMCameraViewController alloc] init];
cameraViewController.delegate = self;
[self.navigationController presentViewController:self.cameraViewController animated:YES completion:nil];

// additional configuration options
cameraViewController.helpView = someUIViewInstance; // displayed when the help button in the scanner is tapped
```


As soon as the Scanner view is visible it starts scanning and it reports important events to its delegate, i.e. when it recognized an item or when the user tapped the *Done* button.

#### Delegate interface:

```objective-c
@protocol SCMCameraViewControllerDelegate <NSObject>

@required
- (void)cameraViewController:(SCMCameraViewController*)cameraViewController recognizedQuery:(SCMQueryResponse*)response atLocation:(CLLocation*)location fromImage:(NSData*)imageData;

@optional
- (void)cameraViewController:(SCMCameraViewController*)cameraViewController recognizedBarcode:(NSString*)text atLocation:(CLLocation*)location;
- (void)cameraViewController:(SCMCameraViewController*)cameraViewController capturedSingleImageWhileOffline:(NSData*)imageData atLocation:(CLLocation*)location;

- (void)cameraViewControllerDidFinish:(SCMCameraViewController*)controller;

@end
```


You can also use the Scanner view to perform recognition of arbitrary image data that you have already captured somewhere else. This works in exactly the same way as when using the Snapshot mode, i.e. it also communicates back to you via the normal delegate methods.

#### Using a Scanner view to perform recognition of arbitrary image data:

```objective-c
NSData *imageData = ... // get image data from somewhere
[cameraViewController processImage:imageData];
```


# Item view

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


# Recognition operation

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


# Configuration

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
