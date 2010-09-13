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
    CPScrollView clientProjectScrollView;
    CPScrollView openRequestsScrollView;
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
    var token = window.prompt("Secret?");
    lps = [0];
    [theSocket sendMessage:token];
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    clientProjectView = [[CPTableView alloc] initWithFrame:CGRectMake(0, 0, 400, 300)];

    [clientProjectView setBackgroundColor:[CPColor colorWithHexString:"DDDDDD"]];
    clientsColumn = [[CPTableColumn alloc] initWithIdentifier:@"clients"];
    projectsColumn = [[CPTableColumn alloc] initWithIdentifier:@"projects"];
    [clientProjectView setDataSource:self];
    [clientProjectView setAllowsColumnReordering:YES];
    [clientProjectView setAllowsColumnResizing:YES];

    clientProjectScrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(20, 20, 400, 400)];
    [clientProjectScrollView setAutoresizingMask:CPViewHeightSizable];
    [clientProjectScrollView setAutohidesScrollers:YES];
    [clientProjectScrollView setHasHorizontalScroller:YES];
    [clientProjectScrollView setDocumentView:clientProjectView];
 
    [clientProjectView addTableColumn:clientsColumn];
    [clientProjectView addTableColumn:projectsColumn];

    openRequestsView = [[CPTableView alloc] initWithFrame:CGRectMake(0, 0, 800, 500)];
    [openRequestsView setBackgroundColor:[CPColor colorWithHexString:"DDDDDD"]];
    openRequestsScrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(440, 20, 800, 500)];
    [openRequestsScrollView setAutoresizingMask:CPViewHeightSizable];
    [openRequestsScrollView setAutohidesScrollers:YES];
    [openRequestsScrollView setHasHorizontalScroller:YES];
    [openRequestsScrollView setDocumentView:openRequestsView];
    
    [contentView addSubview:clientProjectScrollView];
    [contentView addSubview:openRequestsScrollView];
    [theWindow orderFront:self];
}

- (void)numberOfRowsInTableView:(CPTableView)aView
{
    return Object.keys(clients).length;
}

- (void)tableView:(CPTableView)aView objectValueForTableColumn:(unsigned)aColumn row:(unsigned)aRow
{
    if (aView === clientProjectView)
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
}

- (void)socket:(SCSocket)aSocket didReceiveMessage:(JSObject)aMessage
{
    var count = aMessage.length;
    for (var i = 0; i < count; ++i) 
    {
        var theAction = aMessage[i];
        if (theAction.init)
        {
            var allClients = theAction.clients;
            var count = allClients.length;
            for (var i = 0; i < count; ++i)
                clients[allClients[i]] = nil;
            [self refresh];
        }
        else
        {
            if (theAction[1] === "connect")
                clients[theAction[2]] = nil;
            else if (theAction[1] === "disconnect")
            {
                for (key in clients) 
                {
                    if (clients.hasOwnProperty(key) && key === theAction[2])
                        delete clients[key];
                }
            }
            else if (theAction[1] === "message")
            {
                if (theAction[3][1] == "subscribe" || theAction[3][1] === "update")
                    clients[theAction[2]] = theAction[3][2];
            }
        }
    }
    [self refresh];
}
@end
