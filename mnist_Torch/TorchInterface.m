//
//  TorchInterface.m
//  mnist_Torch
//
//  Created by Kazu Komoto on 12/8/16.
//  Copyright © 2016 mycompany. All rights reserved.
//
/*
 This is based on Torch.m by Kurt Jacobs.
 */

#import "TorchInterface.h"

#define KBYTES_CLEAN_UP 10000 //10 Megabytes Max Storage Otherwise Force Cleanup (For This Example We Will Probably Never Reach It -- But Good Practice).
#define LUAT_STACK_INDEX_FLOAT_TENSORS 4 //Index of Garbage Collection Stack Value

//static constexpr int kImageSide = 28;
#define kImageSide 28
//static constexpr int kOutputs = 10;
//static constexpr int kInputLength = kImageSide * kImageSide;
#define kInputLength 784

@implementation Torch

- (NSString *)bundleResourcesPathForFolderName:(NSString *)folderName
{
  return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:folderName];
}

- (NSString *)bundleResourcesPathForFrameworkName:(NSString *)frameworkName
{
  return [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:frameworkName] stringByAppendingPathComponent:@"Resources"];
}

- (void)addLuaPackagePathForBundlePath:(NSString *)bundlePath subdirectory:(NSString *)subdirectory
{
  // Add path for finding individual lua files
  NSMutableString *pathToAdd = [NSMutableString stringWithString:bundlePath];
  if (subdirectory.length > 0) {
    [pathToAdd appendString:@"/"];
    [pathToAdd appendString:subdirectory];
  }
  [pathToAdd appendString:@"/?.lua"];
  [self appendLuaPackagePathWithPath:pathToAdd];
  
  // Add path for finding packages that are prepared with init.lua
  pathToAdd = [NSMutableString stringWithString:bundlePath];
  if (subdirectory.length > 0) {
    [pathToAdd appendString:@"/"];
    [pathToAdd appendString:subdirectory];
  }
  [pathToAdd appendString:@"/?/init.lua"];
  [self appendLuaPackagePathWithPath:pathToAdd];
}

- (void)appendLuaPackagePathWithPath:(NSString *)pathToAdd
{
  lua_getglobal(L, "package");
  lua_getfield(L, -1, "path");
  NSString *packagePath = [NSString stringWithUTF8String:lua_tostring(L, -1)];
  
  NSMutableString *updatedPath = [[NSMutableString alloc] initWithString:packagePath];
  if (updatedPath.length > 0) {
    [updatedPath appendString:@";"];
  }
  [updatedPath appendString:pathToAdd];
  
  lua_pop(L, 1);
  lua_pushstring(L, updatedPath.UTF8String);
  lua_setfield(L, -2, "path");
  lua_pop(L, 1);
}

- (void)requireFrameworkPackage:(NSString *)package frameworkResourcesPath:(NSString *)resourcesPath
{
  NSString *path = [[resourcesPath stringByAppendingPathComponent:package] stringByAppendingPathComponent:@"init.lua"];
  int ret = luaL_dofile(L, [path UTF8String]);
  if (ret == 1) {
    NSLog(@"could not load invalid lua resource: %@\n", package);
  }
}

- (void)require:(NSString *)file inFolder:(NSString *)folderName
{
  NSString *path = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:folderName]stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.lua",file]];
  int ret = luaL_dofile(L, [path UTF8String]);
  NSLog(@"%s\\n",lua_tostring(L,-1));
  if (ret == 1) {
    NSLog(@"could not load invalid lua resource: %@\n", file);
  }
}

- (void)initialize
{
  // initialize Lua stack
  lua_executable_dir("./lua");
  L = lua_open();
  luaL_openlibs(L);
  
  [self addLuaPackagePathForBundlePath:[[NSBundle mainBundle] resourcePath] subdirectory:nil];
  NSString *frameworkResourcesPath = [self bundleResourcesPathForFrameworkName:@"Torch.framework"];
  [self addLuaPackagePathForBundlePath:frameworkResourcesPath subdirectory:nil];
  
  // load Torch
  luaopen_libtorch(L);
  [self requireFrameworkPackage:@"torch" frameworkResourcesPath:frameworkResourcesPath];
  
  // load dok
  [self requireFrameworkPackage:@"dok" frameworkResourcesPath:frameworkResourcesPath];
  
  // load nn
  luaopen_libnn(L);
  [self requireFrameworkPackage:@"nn" frameworkResourcesPath:frameworkResourcesPath];
  
  // load nnx
  luaopen_libnnx(L);
  [self requireFrameworkPackage:@"nnx" frameworkResourcesPath:frameworkResourcesPath];
  
  // load image
  luaopen_libimage(L);
  [self requireFrameworkPackage:@"image" frameworkResourcesPath:frameworkResourcesPath];
  
  return;
}

- (void)runMain:(NSString *)fileName inFolder:(NSString *)folderName
{
  NSString *mainFolder = [self bundleResourcesPathForFolderName:folderName];
  [self addLuaPackagePathForBundlePath:mainFolder subdirectory:nil];
  [self require:fileName inFolder:folderName];
}

- (void)loadFileWithName:(NSString *)filename inResourceFolder:(NSString *)folderName andLoadMethodName:(NSString *)methodName
{
  const char *filelocation_c_str = [[[self bundleResourcesPathForFolderName:folderName]stringByAppendingPathComponent:filename] cStringUsingEncoding:NSASCIIStringEncoding];
  const char *method_name_c_str = [methodName cStringUsingEncoding:NSASCIIStringEncoding];
  
  lua_getglobal(L,method_name_c_str);
  lua_pushstring(L,filelocation_c_str);
  int res = lua_pcall(L, 1, 0, 0);
  if (res != 0)
  {
    NSLog(@"error running function `f': %s",lua_tostring(L, -1));
  }
}

- (lua_State *)getLuaState
{
  return L;
}

//- (int)forward:(void *)ptrImage inState:(lua_State *)L

- (int)forward:(void *)ptrImage
{

  NSInteger garbage_size_kbytes = lua_gc(L, LUA_GCCOUNT, LUAT_STACK_INDEX_FLOAT_TENSORS);
  
  if (garbage_size_kbytes >= KBYTES_CLEAN_UP)
  {
    NSLog(@"LUA -> Cleaning Up Garbage");
    lua_gc(L, LUA_GCCOLLECT, LUAT_STACK_INDEX_FLOAT_TENSORS);
  }
  
  int label = 99;
//  NSData *imageData = [NSData dataWithBytes:ptrImage length:kInputLength*sizeof(float)];
  @autoreleasepool {
  NSData *imageData = [NSData dataWithBytes:ptrImage length:kInputLength*sizeof(float)];

//  THFloatTensor *imageInput = THFloatTensor_newWithSize2d(kImageSide, kImageSide);
  THDoubleTensor *imageInput = THDoubleTensor_newWithSize2d(kImageSide, kImageSide);
  
  for (auto i = 0; i < kInputLength; i++) {
    uint8_t pixel;
    [imageData getBytes:&pixel range:NSMakeRange(i, 1)];
//    x.matrix<float>().operator()(i) = pixel / 255.0f;
    THDoubleTensor_set2d(imageInput, i / kImageSide, i % kImageSide, pixel / 255.0f);  // Note: Image tensor's order in Torch is from column to row. Not from row to column.
  }
  
  lua_getglobal(L,"forwardNeuralNetwork");
//  luaT_pushudata(L, imageInput, "torch.FloatTensor");
  luaT_pushudata(L, imageInput, "torch.DoubleTensor");
  
  //p_call -- args, results
  int res = lua_pcall(L, 1, 1, 0);
  if (res != 0)
  {
    NSLog(@"error running function `f': %s",lua_tostring(L, -1));
  }
  
  if (!lua_isnumber(L, -1))
  {
    NSLog(@"function `f' must return a number");
  }
  label = lua_tonumber(L, -1);
  lua_pop(L, 1);  // pop returned value
  }
  return label;
}

@end
