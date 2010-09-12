/*
 * AppController.j
 * LittleBird
 *
 * Created by Saikat Chakrabarti on September 12, 2010.
 * Copyright 2010, Some Character, LLC. All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <SCSocket/SCSocket.j>

@implementation AppController : CPObject
{
    SCSocket theSocket;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    theSocket = [[SCSocket alloc] initWithURL:[CPURL URLWithString:"http://localhost:8080"] delegate:self];
    [theSocket connect];
}

- (void)socketDidConnect:(SCSocket)aSocket
{
    var token = window.prompt("Secret?");
    lps = [0];
    [theSocket sendMessage:token];
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];
    [theWindow orderFront:self];
}

- (void)socket:(SCSocket)aSocket didReceiveMessage:(CPString)aMessage
{
    console.log(aMessage);
//     if (aMessage[3] && aMessage[3].length == 1) {
//         var theLetter = aMessage[3];
//         var theIndex = theLetter.charCodeAt(0) - 'a'.charCodeAt(0);
//         values[theIndex]++;
//         [barChart reloadData];
//         lps[lps.length - 1]++;
//     }
}
@end
