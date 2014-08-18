//
//  MultiPartImageUpload.m
//  MultiPartImageUpload
//
//  Created by HarshDuggal on 13/08/14.
//  Copyright (c) 2014 HDDev. All rights reserved.
//

#import "MultiPartImageUpload.h"




@interface MultiPartImageUpload ()
{
    int totalChunksTobeUploaded;
    int chunksUploadedSuccessfully;
}
-(void)uploadImageChunkToServerFullImageData:(NSData*)imageData withParam:(NSMutableDictionary*)param withOffset:(NSUInteger)offset;

@end

@implementation MultiPartImageUpload


- (NSData*)getPostDataFromDictionary:(NSDictionary*)dict
{
    NSArray* keys = [dict allKeys];// Create array of key
    NSMutableData* result = [NSMutableData data];
    
    // add params (all params are strings)
    [result appendData:[[NSString stringWithFormat:@"\n--%@\r\n", BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];

    for (int i = 0; i < [keys count]; i++) {
        id tmpKey = [keys objectAtIndex:i];// Get current key
        id tmpValue = [dict valueForKey: tmpKey]; // Get current value for the key
        
        [result appendData: [[NSString stringWithFormat:@"Content-Disposition: form-data; name=%@\r\n\r\n \n%@", tmpKey,tmpValue] dataUsingEncoding:NSUTF8StringEncoding]];

		
        // Append boundary after every key-value
        [result appendData:[[NSString stringWithFormat:@"\n--%@\r\n", BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
    }

    return result;
}



-(void)startUploadImagesToServer
{
    
#warning these variable shud be set properly before starting upload
//    // Set the following parameter and start upload---
//    self.oneChunkSize;
//    self.selectedImageType;
//    self.imageFilePath;
//    self.uploadURLString;
//    self.postParametersDict;
#warning these variable shud be set properly before starting upload
    
    UIImage *imageTobeUploaded = [UIImage imageWithContentsOfFile:self.imageFilePath];
    
    NSData *imageData;
    NSString *fileType;
    
    if (self.selectedImageType == eImageTypeJPG){
        imageData = UIImageJPEGRepresentation(imageTobeUploaded, 1.0);
        fileType = @"image/jpg";
    }
    else if (self.selectedImageType == eImageTypePNG) {
        imageData = UIImagePNGRepresentation(imageTobeUploaded);
        fileType = @"image/png";
    }
    
//    // get size using NSFilemanager
//    unsigned long long totalFileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize];
    
    
    NSUInteger totalFileSize = [imageData length];
    //    int totalChunks = ceil(totalFileSize/oneChunkSize);
    int totalChunks = round((totalFileSize/self.oneChunkSize)+0.5);//round-off to nearest  largest valua 1.01 is considered as 2
    

    // Start multipart upload chunk sequentially-
    NSUInteger offset = 0;
    totalChunksTobeUploaded = totalChunks;
    chunksUploadedSuccessfully = 0;
    [self uploadImageChunkToServerFullImageData:imageData withParam:self.postParametersDict withOffset:offset];
    
}







-(void)uploadImageChunkToServerFullImageData:(NSData*)imageData withParam:(NSMutableDictionary*)param withOffset:(NSUInteger)offset
{
    
    //    NSData* myBlob = imageData;
    NSUInteger totalBlobLength = [imageData length];
    NSUInteger chunkSize = self.oneChunkSize;
    NSUInteger thisChunkSize = totalBlobLength - offset > chunkSize ? chunkSize : totalBlobLength - offset;
    NSData* chunk = [NSData dataWithBytesNoCopy:(char *)[imageData bytes] + offset
                                         length:thisChunkSize
                                   freeWhenDone:NO];
    // upload the chunk
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.uploadURLString]];
    
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPShouldHandleCookies:NO];
    [request setTimeoutInterval:60];
    [request setHTTPMethod:@"POST"];
    
    //
    //    // set Content-Type in HTTP header
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", BOUNDARY];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    //
    // post body
    NSMutableData *body = [[NSMutableData alloc]init];
    
    // add params (all params are strings)
    [body appendData:[self getPostDataFromDictionary:param]];
    
    // add image data
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=%@; filename=blob\r\n", @"file"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:chunk];
    [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
    

    // setting the body of the post to the reqeust
    NSString * bodyString =[[NSString alloc]initWithData:body encoding:NSASCIIStringEncoding];
    NSLog(@"body sent to server: \n %@ \n",bodyString);
    
    [request setHTTPBody:body];
    
    // set the content-length
    //    NSString *postLength = [NSString stringWithFormat:@"%d", [body length]];
    //    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        NSLog(@"response:\n %@, \n error = %@",response,error.localizedDescription);
        if (error) { // Failed
            NSLog(@"error = %@",error.localizedDescription);
            
            // Retry resending same chuck
            [self uploadImageChunkToServerFullImageData:imageData withParam:param withOffset:offset];
            return;
        }
        else if(data.length > 0) {// Data recieved from server
            
#warning parse the revieved data from server accordingly
                NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSLog(@"MsgFromServer:%@ \n Response: %@ \n ",newStr,response);
                // Convert String to dict
                NSError* parsingError;
                NSDictionary *responseRxDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&parsingError];
                
                if (parsingError) {
                    NSLog(@"%@",parsingError.localizedDescription);
                    // Retry resending same chuck
                    [self uploadImageChunkToServerFullImageData:imageData withParam:param withOffset:offset];
                    return;
                }
#warning parse the revieved data from server accordingly
            
            //check success
            NSLog(@"Offset:%lu totalLenght:%lu",(unsigned long)offset,(unsigned long)totalBlobLength);
            NSLog(@"Chunk:%d Total Chunks:%d",chunksUploadedSuccessfully,totalChunksTobeUploaded);
            
            BOOL successfulUpload = YES; // Check success msg from server in "responseRxDict" .
            if (successfulUpload) {
                chunksUploadedSuccessfully += 1;

#warning update your post param dict if needed, accoording to server implementation
                [param setObject:[NSString stringWithFormat:@"%d",chunksUploadedSuccessfully] forKey:@"chunk"];
// above line is example should altered according to the server key in needed
#warning update your post param dict if needed, accoording to server implementation
                
                
                    NSUInteger thisChunkSize = totalBlobLength - offset > chunkSize ? chunkSize : totalBlobLength - offset;
                    NSUInteger newOffset= offset + thisChunkSize;
                    
                    // stop no more data to upload
                    if(offset >= totalBlobLength){
                        NSLog(@"offset >= totalBlobLength");
                        return;
                    }
                    if (chunksUploadedSuccessfully > totalChunksTobeUploaded-1) {
                        NSLog(@"chunk > chunks-1");
                        return;
                    }
                    
                    // send next Chunck To server
                    [self uploadImageChunkToServerFullImageData:imageData withParam:param withOffset:newOffset];
                }
                else { // Retry resending same chuck
                    [self uploadImageChunkToServerFullImageData:imageData withParam:param withOffset:offset];
                    return;
                }
            }
            else { // Retry resending same chuck
                [self uploadImageChunkToServerFullImageData:imageData withParam:param withOffset:offset];
                return;
            }
    }];
}



-(void)demoupload
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    documentsDirectory = [NSString stringWithFormat:@"%@/ProfilePic/",documentsDirectory];
    NSFileManager*fmanager = [NSFileManager defaultManager];
    if(![fmanager fileExistsAtPath:documentsDirectory])
    {
        [fmanager createDirectoryAtPath:documentsDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString * filePath =  [NSString stringWithFormat:@"%@",documentsDirectory];

    NSMutableDictionary *postParam = [[NSMutableDictionary alloc]init];
    [postParam addEntriesFromDictionary:[self demoPostDict]];
    
    MultiPartImageUpload *obj = [[MultiPartImageUpload alloc]init];

    obj.oneChunkSize = 1024 *10;
    obj.selectedImageType = eImageTypePNG;
    obj.imageFilePath =filePath;
    obj.uploadURLString = @"http://example.com/upload";
    obj.postParametersDict = postParam;
    
    [obj startUploadImagesToServer];
    
}

-(NSMutableDictionary*)demoPostDict
{
    NSMutableDictionary *param = [[NSMutableDictionary alloc]init];
    
#warning - These key values in post dictionary varies according to the server implementation----
    UIImage *imageTobeUploaded = [UIImage imageWithContentsOfFile:self.imageFilePath];
    
    NSData *imageData;
    NSString *fileType;
    
    if (self.selectedImageType == eImageTypeJPG){
        imageData = UIImageJPEGRepresentation(imageTobeUploaded, 1.0);
        fileType = @"image/jpg";
    }
    else if (self.selectedImageType == eImageTypePNG) {
        imageData = UIImagePNGRepresentation(imageTobeUploaded);
        fileType = @"image/png";
    }
    
    NSUInteger totalFileSize = [imageData length];
    //    int totalChunks = ceil(totalFileSize/oneChunkSize);
    int totalChunks = round((totalFileSize/self.oneChunkSize)+0.5);//round-off to nearest  largest valua 1.01 is considered as 2
    
    // Create your Post parameter dict according to server
    NSString* originalFilename = @"tmpImageToUpload.png";//uniqueFileName;
    
    //Creating a unique file to upload to server
    NSString *prefixString = @"Album";
    //    This method generates a new string each time it is invoked, so it also uses a counter to guarantee that strings created from the same process are unique.
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString] ;//
    NSString *uniqueFileName = [NSString stringWithFormat:@"%@_%@", prefixString, guid];
    
    //Add key values your post param Dict
    [param setObject:uniqueFileName
              forKey:@"uniqueFilename"];
    [param setObject:[NSString stringWithFormat:@"%lu",(unsigned long)totalFileSize]
              forKey:@"totalFileSize"];
    [param setObject:@"0" forKey:@"chunk"];
    [param setObject:[NSString stringWithFormat:@"%d",totalChunks]
              forKey:@"chunks"];
    [param setObject:fileType
              forKey:@"fileType"];
    [param setObject:originalFilename
              forKey:@"originalFilename"];
    
#warning - These key values in post dictionary varies according to the server implementation----
    return param;
    
}

@end
