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

@class NSString, DIClient2IODaemonXPCHandler, NSXPCListenerEndpoint;

@interface DIDeviceHandle : NSObject <NSSecureCoding, NSCoding> {

    BOOL _handleRefCount;
    unsigned _ioMedia;
    NSString* _BSDName;
    DIClient2IODaemonXPCHandler* _client2IOhandler;
    unsigned long long _regEntryID;
    NSXPCListenerEndpoint* _xpcEndpoint;

}

@property (assign,nonatomic) unsigned ioMedia;                                            //@synthesize ioMedia=_ioMedia - In the implementation block
@property (nonatomic,readonly) unsigned long long regEntryID;                             //@synthesize regEntryID=_regEntryID - In the implementation block
@property (nonatomic,retain) NSString * BSDName;                                          //@synthesize BSDName=_BSDName - In the implementation block
-(NSString *)BSDName;
-(unsigned)ioMedia;
-(void)dealloc;
-(unsigned long long)regEntryID;
-(BOOL)waitForDeviceWithError:(id*)arg1 ;
@end

@interface DiskImages2 : NSObject
+(bool)attachWithParams:(DIAttachParams *)param handle:(DIDeviceHandle **)h error:(NSError **)err;

@end
