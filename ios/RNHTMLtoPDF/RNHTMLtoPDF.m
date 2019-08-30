
//  Created by Christopher on 9/3/15.

#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import <React/RCTConvert.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTView.h>
#import <React/UIView+React.h>
#import <React/RCTUtils.h>
#import "RNHTMLtoPDF.h"

#define PDFSize CGSizeMake(612,792)

@implementation UIPrintPageRenderer (PDF)
- (NSData*) printToPDF:(NSInteger**)_numberOfPages
       backgroundColor:(UIColor*)_bgColor
{
    NSMutableData *pdfData = [NSMutableData data];
    UIGraphicsBeginPDFContextToData( pdfData, self.paperRect, nil );
    
    [self prepareForDrawingPages: NSMakeRange(0, self.numberOfPages)];
    
    CGRect bounds = UIGraphicsGetPDFContextBounds();
    
    for ( int i = 0 ; i < self.numberOfPages ; i++ )
    {
        UIGraphicsBeginPDFPage();
        
        
        CGContextRef currentContext = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(currentContext, _bgColor.CGColor);
        CGContextFillRect(currentContext, self.paperRect);
        
        [self drawPageAtIndex: i inRect: bounds];
    }
    
    *_numberOfPages = self.numberOfPages;
    
    UIGraphicsEndPDFContext();
    return pdfData;
}
@end

@implementation RNHTMLtoPDF {
    RCTEventDispatcher *_eventDispatcher;
    RCTPromiseResolveBlock _resolveBlock;
    RCTPromiseRejectBlock _rejectBlock;
    NSString *_html;
    NSString *_fileName;
    NSString *_filePath;
    UIColor *_bgColor;
    NSInteger *_numberOfPages;
    CGSize _PDFSize;
    UIWebView *_webView;
    float _paddingBottom;
    float _paddingTop;
    float _paddingLeft;
    float _paddingRight;
    BOOL _base64;
    BOOL autoHeight;
}

RCT_EXPORT_MODULE();

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

@synthesize bridge = _bridge;

- (instancetype)init
{
    if (self = [super init]) {
        _webView = [[UIWebView alloc] initWithFrame:self.bounds];
        _webView.delegate = self;
        [self addSubview:_webView];
        autoHeight = false;
    }
    return self;
}

//-(UIImage *)cgUIimage:(CGPDFPageRef)pageRef
//{
//
//
//    return tempImage;
//}

/**add by david  pdf 转图片格式 start  */
RCT_EXPORT_METHOD(pdf_to_img:(NSString *)fromPDFName
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    
    if (fromPDFName == nil || [fromPDFName isEqualToString:@""]) {
        return;
    }
    NSString *imgPath;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [paths objectAtIndex:0];
    NSString *docPath = [documentsDir stringByAppendingPathComponent:fromPDFName];
    
    NSURL *fromPDFURL = [NSURL fileURLWithPath:docPath];
    
    
    CFStringRef path;
    CFURLRef url;
    CGPDFDocumentRef fromPDFDoc;
    path = CFStringCreateWithCString(NULL, [fromPDFName UTF8String], kCFStringEncodingUTF8);
    url = CFURLCreateWithFileSystemPath(NULL, path, kCFURLPOSIXPathStyle, NO);
    fromPDFDoc = CGPDFDocumentCreateWithURL(url);
    //    CGPDFDocumentRef fromPDFDoc = CGPDFDocumentCreateWithURL((CFURLRef) fromPDFURL);
    // Get Total Pages
    float pages = CGPDFDocumentGetNumberOfPages(fromPDFDoc);
    // Create Folder for store under "Documents/"
    
    NSError *error = nil;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSString *folderPath = [documentsDir stringByAppendingPathComponent:[fromPDFName stringByDeletingPathExtension]];
    [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:&error];
    
    int i = 1;
    NSMutableArray *imageArr = [NSMutableArray array];
    CGSize imageSize = CGSizeZero;
    //    UIGraphicsBeginImageContext(CGSizeMake(imageSize.width, imageSize.height * images.count));
    for (i = 1; i <= pages; i++) {
        CGPDFPageRef pageRef = CGPDFDocumentGetPage(fromPDFDoc, i);
        
        CGPDFPageRetain(pageRef);
        // determine the size of the PDF page
        CGRect pageRect = CGPDFPageGetBoxRect(pageRef, kCGPDFMediaBox);
        // renders its content.
        imageSize = pageRect.size;
        
        UIGraphicsBeginImageContext(pageRect.size);
        
        CGContextRef imgContext = UIGraphicsGetCurrentContext();
        
        CGContextSaveGState(imgContext);
        
        //        CGContextTranslateCTM(imgContext,pageRect.size.width, pageRect.size.height);
        CGContextTranslateCTM(imgContext,0.0 ,pageRect.size.height);
        //   CGContextScaleCTM(imgContext, 2, -2);
        CGContextScaleCTM(imgContext,1.0 , - 1.0 );
        
        CGContextSetInterpolationQuality(imgContext, kCGInterpolationHigh);
        //        CGContextSetShouldAntialias(imgContext, YES);
        CGContextSetRenderingIntent(imgContext, kCGRenderingIntentDefault);
        
        CGContextDrawPDFPage(imgContext, pageRef);
        
        CGContextRestoreGState(imgContext);
        
        //PDF Page to image
        
        UIImage *tempImage = UIGraphicsGetImageFromCurrentImageContext();
        
        [imageArr addObject:tempImage];
        
        UIGraphicsEndImageContext();
        
        //Release current source page
        
        CGPDFPageRelease(pageRef);
        // Store IMG
        //
        //        NSString *imgname = [NSString stringWithFormat:@"fromPDFName_%d.png", i];
        //
        //        imgPath = [folderPath stringByAppendingPathComponent:imgname];
        //        [UIImagePNGRepresentation(tempImage) writeToFile:imgPath atomically:YES];
        //
        //         UIImageWriteToSavedPhotosAlbum(tempImage, self, nil, nil);
    }
    /** add by Stephen at2019-08-30 start*/
    // 合并多张图片为一张长图
    UIImage *newImg = [self mergeImages:imageArr imageSize:imageSize];
    
    NSString *imgname = [NSString stringWithFormat:@"fromPDFName.png"];
    imgPath = [folderPath stringByAppendingPathComponent:imgname];
    [UIImagePNGRepresentation(newImg) writeToFile:imgPath atomically:YES];
    /** add by Stephen at2019-08-30 end*/
    
    CGPDFDocumentRelease(fromPDFDoc);
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                          imgPath, @"filePath", nil];
    resolve(data);
}
/**add by david  pdf 转图片格式 end  */

RCT_EXPORT_METHOD(convert:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    
    if (options[@"html"]){
        _html = [RCTConvert NSString:options[@"html"]];
    }
    
    if (options[@"fileName"]){
        _fileName = [RCTConvert NSString:options[@"fileName"]];
    } else {
        _fileName = [[NSProcessInfo processInfo] globallyUniqueString];
    }
    
    // Default Color
    _bgColor = [UIColor colorWithRed: (246.0/255.0) green:(245.0/255.0) blue:(240.0/255.0) alpha:1];
    if (options[@"bgColor"]){
        NSString *hex = [RCTConvert NSString:options[@"bgColor"]];
        hex = [hex uppercaseString];
        NSString *cString = [hex stringByTrimmingCharactersInSet:
                             [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if ((cString.length) == 7) {
            NSScanner *scanner = [NSScanner scannerWithString:cString];
            
            UInt32 rgbValue = 0;
            [scanner setScanLocation:1]; // Bypass '#' character
            [scanner scanHexInt:&rgbValue];
            
            _bgColor = [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
                                       green:((float)((rgbValue & 0x00FF00) >>  8))/255.0 \
                                        blue:((float)((rgbValue & 0x0000FF) >>  0))/255.0 \
                                       alpha:1.0];
        }
    }
    
    if (options[@"directory"] && [options[@"directory"] isEqualToString:@"Documents"]){
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths objectAtIndex:0];
        
        _filePath = [NSString stringWithFormat:@"%@/%@.pdf", documentsPath, _fileName];
    } else {
        _filePath = [NSString stringWithFormat:@"%@%@.pdf", NSTemporaryDirectory(), _fileName];
    }
    
    if (options[@"base64"] && [options[@"base64"] boolValue]) {
        _base64 = true;
    } else {
        _base64 = false;
    }
    
    if (options[@"height"] && options[@"width"]) {
        float width = [RCTConvert float:options[@"width"]];
        float height = [RCTConvert float:options[@"height"]];
        _PDFSize = CGSizeMake(width, height);
    } else {
        _PDFSize = PDFSize;
    }
    
    if (options[@"paddingBottom"]) {
        _paddingBottom = [RCTConvert float:options[@"paddingBottom"]];
    } else {
        _paddingBottom = 10.0f;
    }
    
    if (options[@"paddingLeft"]) {
        _paddingLeft = [RCTConvert float:options[@"paddingLeft"]];
    } else {
        _paddingLeft = 10.0f;
    }
    
    if (options[@"paddingTop"]) {
        _paddingTop = [RCTConvert float:options[@"paddingTop"]];
    } else {
        _paddingTop = 10.0f;
    }
    
    if (options[@"paddingRight"]) {
        _paddingRight = [RCTConvert float:options[@"paddingRight"]];
    } else {
        _paddingRight = 10.0f;
    }
    
    if (options[@"padding"]) {
        _paddingTop = [RCTConvert float:options[@"padding"]];
        _paddingBottom = [RCTConvert float:options[@"padding"]];
        _paddingLeft = [RCTConvert float:options[@"padding"]];
        _paddingRight = [RCTConvert float:options[@"padding"]];
    }
    
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    
    [_webView loadHTMLString:_html baseURL:baseURL];
    
    _resolveBlock = resolve;
    _rejectBlock = reject;
    
}

- (void)webViewDidFinishLoad:(UIWebView *)awebView
{
    if (awebView.isLoading)
    return;
    
    UIPrintPageRenderer *render = [[UIPrintPageRenderer alloc] init];
    [render addPrintFormatter:awebView.viewPrintFormatter startingAtPageAtIndex:0];
    
    // Define the printableRect and paperRect
    // If the printableRect defines the printable area of the page
    CGRect paperRect = CGRectMake(0, 0, _PDFSize.width, _PDFSize.height);
    CGRect printableRect = CGRectMake(_paddingTop, _paddingLeft, _PDFSize.width-(_paddingLeft + _paddingRight), _PDFSize.height-(_paddingBottom + _paddingTop));
    
    
    [render setValue:[NSValue valueWithCGRect:paperRect] forKey:@"paperRect"];
    [render setValue:[NSValue valueWithCGRect:printableRect] forKey:@"printableRect"];
    
    NSData * pdfData = [render printToPDF:&_numberOfPages backgroundColor:_bgColor ];
    
    if (pdfData) {
        NSString *pdfBase64 = @"";
        
        [pdfData writeToFile:_filePath atomically:YES];
        if (_base64) {
            pdfBase64 = [pdfData base64EncodedStringWithOptions:0];
        }
        NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                              pdfBase64, @"base64",
                              [NSString stringWithFormat: @"%ld", (long)_numberOfPages], @"numberOfPages",
                              _filePath, @"filePath", nil];
        _resolveBlock(data);
    } else {
        NSError *error;
        _rejectBlock(RCTErrorUnspecified, nil, RCTErrorWithMessage(error.description));
    }
}

/**add by Stephen at 2019-08-30 start */
// 合并图片
-(UIImage *)mergeImages:(NSMutableArray *)images imageSize:(CGSize)imageSize {
    UIImage *originImg = [UIImage new];
    CGFloat imageWidth = imageSize.width;
    CGFloat imageHeight = imageSize.height * images.count;
    [originImg drawInRect:CGRectMake(0, 0, imageWidth, imageHeight)];
    // [UIScreen mainScreen].scale 可以让图片不失真
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(imageWidth, imageHeight), NO, [UIScreen mainScreen].scale);
    for (int i = 0; i < images.count; i++) {
        UIImage *img = images[i];
        [img drawInRect:CGRectMake(0, imageSize.height * i, imageWidth, imageSize.height)];
    }
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // 压缩图片
    NSData *imgData = [self zipImage:newImage toByte:5 * 1024.0 * 1024.0];
    UIImage *newImg = [UIImage imageWithData:imgData];
    
    return newImg;
    
}

//先尺寸压缩, 在质量压缩
-(NSData *)zipImage:(UIImage *)sourceImage toByte:(NSUInteger)maxLength{
    //进行图像尺寸的压缩
    CGSize imageSize = sourceImage.size;//取出要压缩的image尺寸
    CGFloat width = imageSize.width;    //图片宽度
    CGFloat height = imageSize.height;  //图片高度
    //1.宽高大于1280(宽高比不按照2来算，按照1来算)
    if (width>1280||height>1280) {
        if (width>height) {
            CGFloat scale = height/width;
            width = 1280;
            height = width*scale;
        }else{
            CGFloat scale = width/height;
            height = 1280;
            width = height*scale;
        }
        //2.宽大于1280高小于1280
    }else if(width>1280||height<1280){
        CGFloat scale = height/width;
        width = 1280;
        height = width*scale;
        //3.宽小于1280高大于1280
    }else if(width<1280||height>1280){
        CGFloat scale = width/height;
        height = 1280;
        width = height*scale;
        //4.宽高都小于1280
    }else{
    }
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    [sourceImage drawInRect:CGRectMake(0,0,width,height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //进行图像的画面质量压缩
    CGFloat compression = 1;
    NSData *data = UIImageJPEGRepresentation(newImage, compression);
    if (data.length < maxLength) return data;
    CGFloat max = 1;
    CGFloat min = 0;
    for (int i = 0; i < 6; ++i) {
        compression = (max + min) / 2;
        data = UIImageJPEGRepresentation(sourceImage, compression);
        if (data.length < maxLength * 0.9) {
            min = compression;
        } else if (data.length > maxLength) {
            max = compression;
        } else {
            break;
        }
    }
    return data;
}
/**add by Stephen at 2019-08-30 end */

@end

