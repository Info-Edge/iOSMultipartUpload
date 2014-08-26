iOSMultipartUpload
=================

## Client Side Implementation:

* UIImage is converted into in chunks of NSData i.e., convert the image to binary format
* Data is divided into chunks. i.e., if we have 10MB photo, convert it to a say 10 chunks of size say: 1MB
* Chunks are sent to the server sequentially/parallely(depends on server implementation)
* Check Server acknowledgement for every chunk and store the success chunk locally so that in the event of failure we can reinitiate the upload from the failed chunk.

##Issues with libraries:

* AfNetworking is not solving the problem of acknowledging the response for every chunks from the server, also some headers are missing, crash issues as well

##Things we have done on the server:

* For every chunk being sent to the server - we append the data to the existing chunk on the server and create a <filename>.part file for the first chunk (this keeps getting bigger till the last chunk as we keep appending the image data)
* With the last chunk we create a filename which was given from the fronted form element and we have a backend check to make this name unique in case the filename already exist on the server
*At the end we have a check for file integrity - After all the chunk are combined we check the MIME type and total file size to cross verify there is no corruption in the final file created on the server - we cross check with the last chunk and total file size being sent by the client(this data is sent on every chunk)
* We have a batch job running for cleanup activity of target directory for part chunk files- when a chunk has not been received for a given period time (time can be configurable) it automatically discards the <filename>.part file
 
 
 
 
## Usage Code

 Import by draging the
 `HDMultiPartImageUpload.h` and `HDMultiPartImageUpload.m`
 to your project file
 
 Add the following code to your class (eg `MyDemoVC`) and start uploading.

``` 
#import HDMultiPartImageUpload.h 

@implementation MyDemoVC
@property(nonatomic,strong) NSString * filePath
@end 

@implementation MyDemoVC 
 
-(void)demoupload 
{
   [self setImageFilePath];// Set self.filepath property to read the file path
    
    NSMutableDictionary *postParam = [[NSMutableDictionary alloc]init];
    
    [postParam addEntriesFromDictionary:[self demoPostDict]];
    
    HDMultiPartImageUpload *obj = [[HDMultiPartImageUpload alloc]init]; //intilaize the object and set all the required parameters.
    
    obj.oneChunkSize = 1024 *10;
    
    obj.selectedImageType = eImageTypePNG;
    
    obj.imageFilePath =filePath;
    
    obj.uploadURLString = @"http://example.com/upload";
    
    obj.postParametersDict = postParam;
    
    [obj startUploadImagesToServer];
}

-(NSMutableDictionary*)demoPostDict // Create a dictionary of the parameters needed to be passed at server

{
    NSMutableDictionary *param = [[NSMutableDictionary alloc]init];
    
    #warning - These key values in post dictionary varies according to the server implementation----
    
    UIImage *imageTobeUploaded = [UIImage imageWithContentsOfFile:self.imageFilePath];
    
    NSData *imageData;
    
    NSString *fileType;
    
    if (self.selectedImageType == eImageTypeJPG)
    {
        
        imageData = UIImageJPEGRepresentation(imageTobeUploaded, 1.0);
        
        fileType = @"image/jpg";
        
    }
    
    else if (self.selectedImageType == eImageTypePNG) 
    {
        
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
    
    //- #warning - These key values in post dictionary varies according to the server implementation----
    return param;
    
}

-(void)setImageFilePath {
 NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [paths objectAtIndex:0]; 
    
    documentsDirectory = [NSString stringWithFormat:@"%@/ProfilePic/",documentsDirectory]; // navigate the image dicrectory
    
    NSFileManager*fmanager = [NSFileManager defaultManager]; 
    
    if(![fmanager fileExistsAtPath:documentsDirectory]) // create file path if not there
    {
        [fmanager createDirectoryAtPath:documentsDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        
    }
    
    self.filePath =  [NSString stringWithFormat:@"%@",documentsDirectory];
}

```



## License
iOSMultipartUpload is available under the MIT license. See the LICENSE file for more info.
