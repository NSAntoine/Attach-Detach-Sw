#include <Foundation/Foundation.h>

@interface DIBaseParams : NSObject <NSSecureCoding, NSCoding>
-(id)initWithCoder:(id)arg1 ;
-(NSURL *)inputURL;
-(void)encodeWithCoder:(id)arg1 ;
-(id)description;
-(id)initWithURL:(id)arg1 fileOpenMode:(unsigned short)arg2 error:(id)arg3 ;
@end


@interface DIAttachParams : DIBaseParams {

    BOOL _autoMount;
    BOOL _handleRefCount;
    long long _fileMode;
}
@property (assign) BOOL autoMount;                                         //@synthesize autoMount=_autoMount - In the implementation block
@property (assign,nonatomic) long long fileMode;                           //@synthesize fileMode=_fileMode - In the implementation block
-(id)initWithURL:(id)arg1 error:(id)arg2 ;
-(id)initWithCoder:(id)arg1 ;
-(BOOL)autoMount;
-(long long)fileMode;
-(void)setFileMode:(long long)arg1 ;
-(void)setAutoMount:(BOOL)arg1 ;
@end

@interface DIDeviceHandle : NSObject
-(NSString *)BSDName;
-(unsigned long long)regEntryID;
-(void)setBSDName:(NSString *)arg1 ;
-(BOOL)updateBSDNameWithError:(NSError *)arg1 ;
@end

@interface DiskImages2 : NSObject

+(void)attachWithParams:(DIAttachParams *)param handle:(DIDeviceHandle **)h error:(NSError **)err;

@end
