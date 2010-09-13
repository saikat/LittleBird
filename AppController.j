/*
 * AppController.j
 * LittleBird
 *
 * Created by Saikat Chakrabarti on September 12, 2010.
 * Copyright 2010, Some Character, LLC. All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <SCSocket/SCSocket.j>

var MaxRequests = 1000;

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
    CPArray requests;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    //    var host = window.prompt("Host?");
    var host = "http://localhost:8080";
    clients = {};
    requests = [];
    theSocket = [[SCSocket alloc] initWithURL:[CPURL URLWithString:host] delegate:self];
    [theSocket connect];
}

- (void)socketDidConnect:(SCSocket)aSocket
{
    //    var token = window.prompt("Secret?");
    var token = 'xyVBQmbUYS4ONWXLuVlPAt7sZdQpNi';
    lps = [0];
    [theSocket sendMessage:token];
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    clientProjectView = [[CPTableView alloc] initWithFrame:CGRectMake(0, 0, 400, 500)];

    [clientProjectView setBackgroundColor:[CPColor colorWithHexString:"DDDDDD"]];
    clientsColumn = [[CPTableColumn alloc] initWithIdentifier:@"clients"];
    [clientsColumn setMinWidth:195];
    projectsColumn = [[CPTableColumn alloc] initWithIdentifier:@"projects"];
    [projectsColumn setMinWidth:195];
    [clientProjectView setDataSource:self];
    [clientProjectView setAllowsColumnReordering:YES];
    [clientProjectView setAllowsColumnResizing:YES];

    clientProjectScrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(20, 20, 400, 500)];
    [clientProjectScrollView setAutoresizingMask:CPViewHeightSizable];
    [clientProjectScrollView setAutohidesScrollers:YES];
    [clientProjectScrollView setHasHorizontalScroller:YES];
    [clientProjectScrollView setDocumentView:clientProjectView];
 
    [clientProjectView addTableColumn:clientsColumn];
    [clientProjectView addTableColumn:projectsColumn];

    openRequestsView = [[CPTableView alloc] initWithFrame:CGRectMake(0, 0, 800, 500)];
    [openRequestsView setBackgroundColor:[CPColor colorWithHexString:"DDDDDD"]];

    timestamp = [[CPTableColumn alloc] initWithIdentifier:@"timestamp"];
    [[timestamp headerView] setStringValue:"Timestamp"];
    [timestamp setMinWidth:150];
    clientColumn = [[CPTableColumn alloc] initWithIdentifier:@"client"];
    [[clientColumn headerView] setStringValue:"Client"];
    [clientColumn setMinWidth:20];
    [clientColumn setWidth:100];
    isActive = [[CPTableColumn alloc] initWithIdentifier:@"active"];
    [[isActive headerView] setStringValue:"Active?"];
    [isActive setMinWidth:20];
    [isActive setWidth:50];
    request = [[CPTableColumn alloc] initWithIdentifier:@"request"];
    [[request headerView] setStringValue:"Request"];
    [request setMinWidth:380];
    response = [[CPTableColumn alloc] initWithIdentifier:@"response"];
    [[response headerView] setStringValue:"Response"];
    [response setMinWidth:20];
    [response setWidth:50];
    ttr = [[CPTableColumn alloc] initWithIdentifier:@"ttr"];
    [[ttr headerView] setStringValue:"TTR"];
    [ttr setMinWidth:20];
    [ttr setWidth:50];

    [openRequestsView setDataSource:self];
    [openRequestsView addTableColumn:timestamp];
    [openRequestsView addTableColumn:clientColumn];
    [openRequestsView addTableColumn:isActive];
    [openRequestsView addTableColumn:request];
    [openRequestsView addTableColumn:response];
    [openRequestsView addTableColumn:ttr];

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
    if (aView === clientProjectView)
        return Object.keys(clients).length;
    else
        return requests.length;
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
    else if (aView === openRequestsView)
    {
        var theObj = requests[aRow];
        return theObj[[aColumn identifier]];
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
    [openRequestsView reloadData];
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
                requests.push({
                            "id" : theAction[3][0],
                                "timestamp" : theAction[0],
                                "client" : theAction[2],
                                "active" : YES,
                                "request" : JSON.stringify(theAction[3]),
                                "response" : nil,
                                "ttr" : nil});
                            
                if (requests.length > MaxRequests)
                    requests.shift();
                requests.sort(function(a, b) {
                        if (a.timestamp < b.timestamp)
                            return -1;
                        else
                            return 1;
                    });
                if (theAction[3][1] == "subscribe" || theAction[3][1] === "update")
                    clients[theAction[2]] = theAction[3][2];
            }
            else if (theAction[1] === "response")
            {
                var reqLen = requests.length;
                var theRequest = nil;
                for (var j = 0; j < reqLen; ++j)
                    if (requests[j].id === theAction[3][0]) {
                        requests[j].response = theAction[3][1];
                        requests[j].active = NO;
                        break;
                    }
                if (j === reqLen)
                    requests.push({"id" : theAction[3][0],
                                "timestamp" : theAction[0],
                                "client" : nil,
                                "active" : NO,
                                "request" : JSON.stringify(theAction[3]),
                                "response" : theAction[3][1],
                                "ttr" : 0});

            }
        }
    }
    [self refresh];
}
@end
