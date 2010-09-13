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
    CPTableView clientProjectView;
    CPTableView openRequestsView;
    CPTableColumn clientsColumn;
    CPTableColumn projectsColumn; 
    CPScrollView scrollView;
    JSObject clients;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var host = window.prompt("Host?");
    clients = {};
    theSocket = [[SCSocket alloc] initWithURL:[CPURL URLWithString:host] delegate:self];
    [theSocket connect];
}

- (void)socketDidConnect:(SCSocket)aSocket
{
    //    var token = window.prompt("Secret?");
    var token = "jOQwLOzOajxhy9DwgVnFpzyUXIg9jc";
    lps = [0];
    [theSocket sendMessage:token];
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    clientProjectView = [[CPTableView alloc] initWithFrame:CGRectMake(0, 0, 200, 300)];

    clientsColumn = [[CPTableColumn alloc] initWithIdentifier:@"clients"];
    projectsColumn = [[CPTableColumn alloc] initWithIdentifier:@"projects"];
    [clientProjectView setDataSource:self];
    [clientProjectView setAllowsColumnReordering:YES];
    [clientProjectView setAllowsColumnResizing:YES];

    clientProjectScrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(20, 20, 300, 400)];
    [clientProjectScrollView setAutoresizingMask:CPViewHeightSizable];
    [clientProjectScrollView setAutohidesScrollers:YES];
    [clientProjectScrollView setHasHorizontalScroller:YES];
    [clientProjectScrollView setDocumentView:clientProjectView];
 
    [clientProjectView addTableColumn:clientsColumn];
    [clientProjectView addTableColumn:projectsColumn];
    [contentView addSubview:clientProjectScrollView];
    [theWindow orderFront:self];
}

- (void)numberOfRowsInTableView:(CPTableView)aView
{
    return Object.keys(clients).length;
}

- (void)tableView:(CPTableView)aView objectValueForTableColumn:(unsigned)aColumn row:(unsigned)aRow
{
    var count = 0;
    var obj = nil;
    for (key in clients)
        if (clients.hasOwnProperty(key))
        {
            if (count != aRow) 
                count++;
            else 
            {
                obj = {"client" : key,
                       "project" : clients[key]};
                break;
            }
        };

    if ([aColumn identifier] === 'clients') 
        return obj.client;

    if ([aColumn identifier] === 'projects')
        return obj.project;
}

- (void)refresh
{
    var projectCount = 0;
    for (key in clients)
        if (clients.hasOwnProperty(key) && clients[key] != nil)
            projectCount++;
    [[clientsColumn headerView] setStringValue:"Clients (" + Object.keys(clients).length + ")"];
    [[projectsColumn headerView] setStringValue:"Projects (" + projectCount + ")"];
    [clientProjectView reloadData];
    setTimeout(function() {[self refresh]}, 500);
}

- (void)socket:(SCSocket)aSocket didReceiveMessage:(CPString)aMessage
{
    if (aMessage.init)
    {
        var allClients = aMessage.clients;
        var count = allClients.length;
        for (var i = 0; i < count; ++i)
            clients[allClients[i]] = nil;
        [self refresh];
    }
    else
    {
        if (aMessage[1] === "connect")
            clients[aMessage[2]] = nil;
        else if (aMessage[1] === "disconnect")
        {
            for (key in clients) 
            {
                if (clients.hasOwnProperty(key) && key === aMessage[2])
                    delete clients[key];
            }
        }
        else if (aMessage[1] === "message")
        {
            if (aMessage[3][1] == "subscribe" || aMessage[3][1] === "update")
                clients[aMessage[2]] = aMessage[3][2];
        }
    }
}
@end
