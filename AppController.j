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
    CPTableColumn transportColumn; 
    CPScrollView clientProjectScrollView;
    CPScrollView openRequestsScrollView;
    JSObject clients;
    CPArray requests;
    CPArray unknownResponses;

    JSObject maxReq;
    CPTextField reqsPerMin;
    CPTextField connPerMin;
    CPTextField timePerReq;
    CPTextField maxTimePerReq;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    //    var host = window.prompt("Host?");
    var host = 'http://localhost:8080';
    clients = {};
    requests = [];
    unknownResponses = [];
    maxReq = {"time" : 0, "project" : ""};
    theSocket = [[SCSocket alloc] initWithURL:[CPURL URLWithString:host] delegate:self];
    [theSocket connect];
}

- (void)socketDidConnect:(SCSocket)aSocket
{
    //    var token = window.prompt("Secret?");
    var token = 'yNO6sPkCfiHUCXZDzpjCAMGIPP8lvD';
    lps = [0];
    [theSocket sendMessage:token];
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView];

    clientProjectView = [[CPTableView alloc] initWithFrame:CGRectMake(0, 0, 400, 500)];

    [clientProjectView setBackgroundColor:[CPColor colorWithHexString:"DDDDDD"]];

    clientsColumn = [[CPTableColumn alloc] initWithIdentifier:@"client"];
    [clientsColumn setMinWidth:25];
    [clientsColumn setWidth:100];

    transportColumn = [[CPTableColumn alloc] initWithIdentifier:@"transport"];
    [[transportColumn headerView] setStringValue:"Transport"];
    [transportColumn setMinWidth:25];
    [transportColumn setWidth:100];

    projectsColumn = [[CPTableColumn alloc] initWithIdentifier:@"project"];
    [projectsColumn setMinWidth:25];
    [projectsColumn setWidth:190];

    [clientProjectView setDataSource:self];
    [clientProjectView setAllowsColumnReordering:YES];
    [clientProjectView setAllowsColumnResizing:YES];

    clientProjectScrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(20, 20, 400, 500)];
    [clientProjectScrollView setAutohidesScrollers:YES];
    [clientProjectScrollView setHasHorizontalScroller:YES];
    [clientProjectScrollView setDocumentView:clientProjectView];
 
    [clientProjectView addTableColumn:clientsColumn];
    [clientProjectView addTableColumn:transportColumn];
    [clientProjectView addTableColumn:projectsColumn];

    openRequestsView = [[CPTableView alloc] initWithFrame:CGRectMake(0, 0, 800, 500)];
    [openRequestsView setBackgroundColor:[CPColor colorWithHexString:"DDDDDD"]];

    timestamp = [[CPTableColumn alloc] initWithIdentifier:@"timestamp"];
    [[timestamp headerView] setStringValue:"Timestamp"];
    [timestamp setMinWidth:150];
    clientColumn = [[CPTableColumn alloc] initWithIdentifier:@"client"];
    [[clientColumn headerView] setStringValue:"Client"];
    [clientColumn setMinWidth:20];
    [clientColumn setWidth:50];
    projectColumn = [[CPTableColumn alloc] initWithIdentifier:@"project"];
    [[projectColumn headerView] setStringValue:"Project"];
    [projectColumn setMinWidth:20];
    [projectColumn setWidth:100];
    isActive = [[CPTableColumn alloc] initWithIdentifier:@"active"];
    [[isActive headerView] setStringValue:"Active?"];
    [isActive setMinWidth:20];
    [isActive setWidth:50];
    versionColumn = [[CPTableColumn alloc] initWithIdentifier:@"version"];
    [[versionColumn headerView] setStringValue:"Version"];
    [versionColumn setMinWidth:20];
    [versionColumn setWidth:50];
    msgCount = [[CPTableColumn alloc] initWithIdentifier:@"msgCount"];
    [[msgCount headerView] setStringValue:"Msg Ct"];
    [msgCount setMinWidth:20];
    [msgCount setWidth:50];
    request = [[CPTableColumn alloc] initWithIdentifier:@"request"];
    [[request headerView] setStringValue:"Request"];
    [request setMinWidth:360];
    [request setWidth:4000];
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
    [openRequestsView addTableColumn:projectColumn];
    [openRequestsView addTableColumn:versionColumn];
    [openRequestsView addTableColumn:msgCount];
    [openRequestsView addTableColumn:isActive];
    [openRequestsView addTableColumn:response];
    [openRequestsView addTableColumn:ttr];
    [openRequestsView addTableColumn:request];

    openRequestsScrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(440, 20, 800, 500)];
    [openRequestsScrollView setAutohidesScrollers:YES];
    [openRequestsScrollView setHasHorizontalScroller:YES];
    [openRequestsScrollView setDocumentView:openRequestsView];

    reqsPerMin = [CPTextField labelWithTitle:"Reqs/min: "];
    [reqsPerMin setFont:[CPFont fontWithName:"Helvetica" size:32.0]];
    [reqsPerMin sizeToFit];
    [reqsPerMin setFrameOrigin:CGPointMake(20, 540)];

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
    [contentView addSubview:reqsPerMin];
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
                           "transport" : clients[key].transport,
                           "project" : clients[key].project};
                    break;
                }
            };

        if (obj)
            return obj[[aColumn identifier]];
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
                if (parsedMsg.cmd === "update") {
                    count++;
                    totalTTR = totalTTR + x.ttr;
                    if (x.ttr > maxReq.time) 
                    {
                        maxReq.time = x.ttr;
                        maxReq.project = parsedMsg.project;
                    }
                }
            });
        var avgTTR = totalTTR / count;
        var count = requests.length;
        var latesttime = requests[count-1].timestamp;
        var requestsInLastMinute = 0;
        while (count--) {
            if (subtractTimestamps(requests[count].timestamp, requests[requests.length - 1].timestamp) < 60000)
                requestsInLastMinute++;
            else
                break;
        }
            
        [reqsPerMin setStringValue:"Reqs/min: " + requestsInLastMinute];
        [reqsPerMin sizeToFit];
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
                clients[allClients[i].client] = {'project' : nil,
                                                 'transport' : allClients[i].transport};
            [self refresh];
        }
        else
        {
            var actionTimestamp = theAction[0];
            var requestType = theAction[1];
            var theClient = theAction[2];
            
            if (requestType === "connect") {
                if (!clients[theClient])
                    clients[theClient] = {};
                clients[theClient].transport = theAction[3];
            }
            else if (requestType === "disconnect")
            {
                for (key in clients) 
                {
                    if (clients.hasOwnProperty(key) && key === theClient)
                        delete clients[key];
                }
            }
            else if (requestType === "message")
            {
                var active = YES;
                var response = nil;
                var ttr = nil;
                var responsesLength = unknownResponses.length;
                var actionId = theAction[3].id;
                var cmd = theAction[3].cmd;
                var project = theAction[3].project;
                if (theAction[3].body)
                {
                    var version = theAction[3].body.version;
                    var theMsgCount = theAction[3].body.msgCount;
                }
                else
                {
                    var version = "-----";
                    var theMsgCount = "---";
                }
                for (var k = 0; k < responsesLength; ++k)
                {
                    if (unknownResponses[k].id === actionId)
                    {
                        active = NO;
                        response = unknownResponses[k].response;
                        ttr = subtractTimestamps(actionTimestamp, unknownResponses[k].timestamp);
                        unknownResponses.splice(k, 1);
                        break;
                    }
                }
                requests.push({
                            "id" : actionId,
                                "timestamp" : actionTimestamp,
                                "client" : theClient,
                                "project" : project,
                                "version" : version,
                                "msgCount" : theMsgCount,
                                "active" : active,
                                "response" : response,
                                "ttr" : ttr,
                                "request" : JSON.stringify(theAction[3])});
                            
                if (requests.length > MaxRequests)
                    requests.shift();
                requests.sort(function(a, b) {
                        if (a.timestamp < b.timestamp)
                            return -1;
                        else
                            return 1;
                    });
                if (cmd == "subscribe" || cmd === "update") {
                    clients[theClient].project = project;
                }
            }
            else if (requestType === "response")
            {
                var reqLen = requests.length;
                var theRequest = nil;
                var actionId = theAction[3].id;
                for (var j = 0; j < reqLen; ++j)
                    if (requests[j].id === actionId) {
                        requests[j].response = theAction[3].status;
                        requests[j].active = NO;
                        requests[j].ttr = subtractTimestamps(requests[j].timestamp, theAction[0]);
                        break;
                    }
                if (j === reqLen) {
                    unknownResponses.push({"id" : theAction[3].id,
                                "timestamp" : theAction[0],
                                "response" : theAction[3].status});
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

