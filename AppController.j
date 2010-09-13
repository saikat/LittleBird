/*
 * AppController.j
 * LittleBird
 *
 * Created by Saikat Chakrabarti on September 12, 2010.
 * Copyright 2010, Some Character, LLC. All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <SCSocket/SCSocket.j>

var MaxRequests = 2000;

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
    CPArray unknownResponses;

    JSObject maxReq;
    CPTextField reqsPerSec;
    CPTextField connPerMin;
    CPTextField timePerReq;
    CPTextField maxTimePerReq;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var host = window.prompt("Host?");
    clients = {};
    requests = [];
    unknownResponses = [];
    maxReq = {"time" : 0, "project" : ""};
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

    clientProjectView = [[CPTableView alloc] initWithFrame:CGRectMake(0, 0, 400, 500)];

    [clientProjectView setBackgroundColor:[CPColor colorWithHexString:"DDDDDD"]];
    clientsColumn = [[CPTableColumn alloc] initWithIdentifier:@"clients"];
    [clientsColumn setMinWidth:190];
    projectsColumn = [[CPTableColumn alloc] initWithIdentifier:@"projects"];
    [projectsColumn setMinWidth:190];
    [clientProjectView setDataSource:self];
    [clientProjectView setAllowsColumnReordering:YES];
    [clientProjectView setAllowsColumnResizing:YES];

    clientProjectScrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(20, 20, 400, 500)];
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
    [request setMinWidth:360];
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
    [openRequestsScrollView setAutohidesScrollers:YES];
    [openRequestsScrollView setHasHorizontalScroller:YES];
    [openRequestsScrollView setDocumentView:openRequestsView];

    reqsPerSec = [CPTextField labelWithTitle:"Reqs/sec: "];
    [reqsPerSec setFont:[CPFont fontWithName:"Helvetica" size:32.0]];
    [reqsPerSec sizeToFit];
    [reqsPerSec setFrameOrigin:CGPointMake(20, 540)];

    timePerReq = [CPTextField labelWithTitle:"Time/req: "];
    [timePerReq setFont:[CPFont fontWithName:"Helvetica" size:32.0]];
    [timePerReq sizeToFit];
    [timePerReq setFrameOrigin:CGPointMake(20, 575)];

    maxTimePerReq = [CPTextField labelWithTitle:"Max time/req: "];
    [maxTimePerReq setFont:[CPFont fontWithName:"Helvetica" size:32.0]];
    [maxTimePerReq sizeToFit];
    [maxTimePerReq setFrameOrigin:CGPointMake(20, 610)];

    connPerMin = [CPTextField labelWithTitle:"Conn/min: "];
    [connPerMin setFont:[CPFont fontWithName:"Helvetica" size:32.0]];
    [connPerMin sizeToFit];
    [connPerMin setFrameOrigin:CGPointMake(20, 545)];

    [contentView addSubview:clientProjectScrollView];
    [contentView addSubview:openRequestsScrollView];
    [contentView addSubview:reqsPerSec];
    //    [contentView addSubview:connPerMin];
    [contentView addSubview:timePerReq];
    [contentView addSubview:maxTimePerReq];
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
    var totalTTR = 0;
    var count = 0;
    if (requests.length) {
        requests.map(function(x, index) {
                var parsedMsg = JSON.parse(x.request);
                if (parsedMsg[1] === "update") {
                    count++;
                    totalTTR = totalTTR + x.ttr;
                    if (x.ttr > maxReq.time) 
                    {
                        maxReq.time = x.ttr;
                        maxReq.project = parsedMsg[2];
                    }
                }
            });
        var avgTTR = totalTTR / count;
        var totalElapsedTime = subtractTimestamps(requests[0].timestamp, requests[requests.length - 1].timestamp);
        [reqsPerSec setStringValue:"Reqs/sec: " + (requests.length / (totalElapsedTime / 1000))];
        [reqsPerSec sizeToFit];
        [timePerReq setStringValue:"Time/req (last 1000): " + avgTTR];
        [timePerReq sizeToFit];
        
        [maxTimePerReq setStringValue:"Max time/req (ever): " + maxReq.time + " (" + maxReq.project + ")"];
        [maxTimePerReq sizeToFit];
    }
    for (key in clients)
        if (clients.hasOwnProperty(key) && clients[key] != nil)
            projectCount++;
    [[clientsColumn headerView] setStringValue:"Clients (" + Object.keys(clients).length + ")"];
    [[projectsColumn headerView] setStringValue:"Projects (" + projectCount + ")"];
    [clientProjectView reloadData];
    [openRequestsView reloadData];
}

- (void)calculateRequestsPerMinute
{
    
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
                var active = YES;
                var response = nil;
                var ttr = nil;
                var responsesLength = unknownResponses.length;
                for (var k = 0; k < responsesLength; ++k)
                {
                    if (unknownResponses[k].id === theAction[3][0])
                    {
                        active = NO;
                        response = unknownResponses[k].response;
                        ttr = subtractTimestamps(theAction[0], unknownResponses[k].timestamp);
                        unknownResponses.splice(k, 1);
                        break;
                    }
                }
                requests.push({
                            "id" : theAction[3][0],
                                "timestamp" : theAction[0],
                                "client" : theAction[2],
                                "active" : active,
                                "request" : JSON.stringify(theAction[3]),
                                "response" : response,
                                "ttr" : ttr});
                            
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
                        requests[j].ttr = subtractTimestamps(requests[j].timestamp, theAction[0]);
                        break;
                    }
                if (j === reqLen) {
                    unknownResponses.push({"id" : theAction[3][0],
                                "timestamp" : theAction[0],
                                "response" : theAction[3][1]});
                    console.log(unknownResponses);
                }

            }
        }
    }
    [self refresh];
}
@end

function dateFromTimestamp(ts) {
    var year = ts.substr(0, 4);
    var month = ts.substr(5, 2);
    var day = ts.substr(8, 2);
    var hour = ts.substr(11, 2);
    var min = ts.substr(14, 2);
    var sec = ts.substr(17, 2);
    var ms = ts.substr(20, 3);
    return new Date(year, month, day, hour, min, sec, ms);
}

function subtractTimestamps(ts1, ts2) {
    return dateFromTimestamp(ts2) - dateFromTimestamp(ts1);
}

