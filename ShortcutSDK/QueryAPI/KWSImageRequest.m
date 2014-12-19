//
//  KWSImageRequest.m
//  ShortcutSDK
//
//  Created by David Wisti on 3/14/12.
//  Copyright (c) 2012 Shortcut Media AG. All rights reserved.
//

#import "KWSImageRequest.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import "SCMBase64Utils.h"
#import "SCMUUIDUtils.h"


@interface KWSImageRequest ()

@property (nonatomic, strong, readwrite) NSURL *queryURL;
@property (nonatomic, strong, readwrite) NSData *imageData;
@property (nonatomic, strong, readwrite) NSMutableData *bodyData;
@property (nonatomic, strong, readwrite) NSString *boundary;

@end


@implementation KWSImageRequest

- (id)initWithURL:(NSURL *)requestURL imageData:(NSData *)data
{
    self = [super init];
    if (self != nil) {
        self.queryURL = requestURL;
        self.imageData = data;
        self.bodyData = [NSMutableData data];
        self.boundary = [SCMUUIDUtils generateUUID];
    }
    
    return self;
}

- (NSDateFormatter *)httpDateFormatter
{
    static NSDateFormatter *formatter = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        formatter = [[NSDateFormatter alloc] init];
        formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        formatter.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
        
        // always set the US locale because on non-US devices the date string could be formatted incorrectly
        formatter.locale = usLocale;
    });
    
    return formatter;
}

- (NSData *)sha1DigestForString:(NSString *)string
{
    NSData *inputData = [string dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t sha1DigestBytes[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(inputData.bytes, (CC_LONG)inputData.length, sha1DigestBytes);
    NSData *sha1RawDigest = [NSData dataWithBytes:sha1DigestBytes length:CC_SHA1_DIGEST_LENGTH];
    return sha1RawDigest;
}

- (NSData *)sha1DigestForString:(NSString *)string withKey:(NSString *)key
{
    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [string cStringUsingEncoding:NSASCIIStringEncoding];
    
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    
    //NSString *hash = [HMAC base64Encoding];
    return HMAC;
}

- (NSString *)md5DigestForData:(NSData *)data
{
    uint8_t md5result[CC_MD5_DIGEST_LENGTH];
    CC_MD5([data bytes], (CC_LONG)[data length], md5result);
    NSMutableString *hexDigest = [NSMutableString string];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [hexDigest appendFormat:@"%02x", md5result[i]];
    }
    
    return hexDigest;
}

- (void)appendTextValue:(NSString *)text forKey:(NSString *)key
{
    NSMutableString *textString = [NSMutableString string];
    [textString appendFormat:@"--%@\r\n", self.boundary];
    [textString appendFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n", key];
    [textString appendString:@"Content-Type: text/plain; charset=utf-8\r\n"];
    [textString	appendFormat:@"\r\n%@\r\n", text];
    [self.bodyData appendData:[textString dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)appendJSONData:(NSData *)jsonData forKey:(NSString *)key
{
    if (jsonData != nil) {
        NSMutableString *textString = [NSMutableString string];
        [textString appendFormat:@"--%@\r\n", self.boundary];
        [textString appendFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n", key];
        [textString appendString:@"Content-Type: application/json; charset=utf-8\r\n"];
        [textString	appendFormat:@"\r\n"];
        [self.bodyData appendData:[textString dataUsingEncoding:NSUTF8StringEncoding]];
        [self.bodyData appendData:jsonData];
        [self.bodyData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

- (void)appendFileData:(NSData *)fileData forKey:(NSString *)key contentType:(NSString *)contentType name:(NSString *)name filename:(NSString *)filename
{
    NSMutableString *textString = [NSMutableString string];
    [textString appendFormat:@"--%@\r\n", self.boundary];
    [textString appendFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", name, filename];
    [textString appendFormat:@"Content-Type: %@\r\n", contentType];
    [textString appendString:@"Content-Transfer-Encoding: binary\r\n"];
    [textString appendString:@"\r\n"];
    [self.bodyData appendData:[textString dataUsingEncoding:NSUTF8StringEncoding]];
    [self.bodyData appendData:fileData];
    [self.bodyData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
}

- (NSURLRequest *)signedRequestWithAccessKey:(NSString *)accessKey secretKey:(NSString *)secretKey
{
    NSString *imageContentType = @"image/jpeg";
    [self appendTextValue:self.returnedMetadata forKey:@"returned-metadata"];
    if (self.clientData != nil) {
        [self appendJSONData:self.clientData forKey:@"user_data"];
    }
    [self appendFileData:self.imageData forKey:@"image" contentType:imageContentType name:@"image" filename:@"query.jpeg"];
    
    NSString *closingBoundary = [NSString stringWithFormat:@"--%@--\r\n", self.boundary];
    [self.bodyData appendData:[closingBoundary dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSString *httpMethod = @"POST";
    NSString *urlPath = [self.queryURL path];
    NSString *contentType = @"multipart/form-data";
    NSString *dateValue = [self.httpDateFormatter stringFromDate:[NSDate date]];
    
    // calculate KWS authorization signature
    NSAssert(accessKey && secretKey, @"You must specify access key and secret key in the Shortcut SDK config");
    NSString *contentMD5 = [self md5DigestForData:self.bodyData];
    NSString *stringToSign = [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@", httpMethod, contentMD5, contentType, dateValue, urlPath];
    NSData *signatureData = [self sha1DigestForString:stringToSign withKey:secretKey];
    NSString *signature = [SCMBase64Utils encodeBase64WithData:signatureData];
    
    // request header values
    NSString *authorizationValue = [NSString stringWithFormat:@"KA %@:%@", accessKey, signature];
    NSString *contentTypeValue = [NSString stringWithFormat:@"%@; boundary=%@", contentType, self.boundary];
    
    NSMutableURLRequest *signedRequest = [NSMutableURLRequest requestWithURL:self.queryURL];
    [signedRequest setHTTPMethod:httpMethod];
    [signedRequest setHTTPBody:self.bodyData];
    [signedRequest setValue:contentTypeValue forHTTPHeaderField:@"Content-Type"];
    [signedRequest addValue:authorizationValue forHTTPHeaderField:@"Authorization"];
    [signedRequest addValue:dateValue forHTTPHeaderField:@"Date"];
    
    return signedRequest;
}

@end
