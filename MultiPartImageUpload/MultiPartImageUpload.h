//
//  HDMultiPartImageUpload.h
//  HDMultiPartImageUpload
//
//  Created by HarshDuggal on 13/08/14.
//  Copyright (c) 2014 Infoedge. All rights reserved.
//
//
//This program is free software: you can redistribute it and/or modify
//it under the terms of the GNU General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.
//
//This program is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU General Public License
//along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
 
 
 
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
 
 
 
//static const int oneChunkSize = (1024 * 4);
 
#define BOUNDARY @"--ARCFormBoundaryb6kap934u6jemi"
 
#define uploadingImageMappingKeyOnServer @"file" //Use Same key string which your read as input for image filename at your server implementation
 
typedef enum : NSUInteger {
    eImageTypePNG,
    eImageTypeJPG,
} eImageType;
 
 
 
@interface HDMultiPartImageUpload : NSObject
 
@property (nonatomic,assign) int                  oneChunkSize;
@property (nonatomic,assign) eImageType           selectedImageType;
@property (nonatomic,strong) NSString            *imageFilePath;
@property (nonatomic,strong) NSString            *uploadURLString;
@property (nonatomic,strong) NSMutableDictionary *postParametersDict;
 
-(void)startUploadImagesToServer;
 
@end
