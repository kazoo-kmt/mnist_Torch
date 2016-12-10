//
//  TorchInterface.h
//  mnist_Torch
//
//  Created by Kazu Komoto on 12/8/16.
//  Copyright © 2016 mycompany. All rights reserved.
//
/*
 This is based on Torch.h by Kurt Jacobs.
 */

#ifndef TorchInterface_h
#define TorchInterface_h

#import <UIKit/UIKit.h>

#import <Torch/lua.h>
#import <Torch/TH/TH.h>
#import <Torch/luaT.h>
#import <Torch/lualib.h>
#import <Torch/lauxlib.h>

int luaopen_libtorch(lua_State *L);
int luaopen_libnn(lua_State *L);
int luaopen_libnnx(lua_State *L);
int luaopen_libimage(lua_State *L);

@interface Torch : NSObject
{
  lua_State *L;
}

- (void)initialize;
- (void)runMain:(NSString *)fileName inFolder:(NSString *)folderName;
- (void)loadFileWithName:(NSString *)filename inResourceFolder:(NSString *)folderName andLoadMethodName:(NSString *)methodName;
- (lua_State *)getLuaState;
//- (int)forward:(void *)ptrImage inState:(lua_State *)L;
- (int)forward:(void *)ptrImage;
@end


#endif /* TorchInterface_h */
