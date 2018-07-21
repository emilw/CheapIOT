var http = require('http');
var url = require('url');
var fs = require('fs');
var wifi = require('node-wifi');

var writeSuccessfulResponse = function(res, data) {
    res.writeHead(200);
    res.write(data);
    res.end();
}

var writeBadRequestResponse = function(res, errorMessage) {
    res.writeHead(400);
    res.write(errorMessage);
    res.end();
}

var serveLandingPage = function(res) {
    const path = __dirname + '/index.html';
    console.log(path);
    serveAsset(path, res);
}

var serveAsset = function(path, res) {
    fs.readFile(path, function(err, data){
        if(err) {
            writeBadRequestResponse(res, `Failed to read ${path}`);
        } else{
            writeSuccessfulResponse(res, data);
        }
    });
}

var currentWifi = function(res) {
    wifi.getCurrentConnections(function(err, currentConnections) {
        if (err) {
            console.log(err);
        }
        console.log(currentConnections);
        let ssid = JSON.stringify(null);
        if(currentConnections.length > 0) {
            ssid = JSON.stringify(currentConnections[0].ssid);
        }
        writeSuccessfulResponse(res, ssid);
    });
}

var scanWifi = function(res) {
    console.log("Scanning for WiFi");
    
    wifi.scan(function(err, networks) {
        if (err) {
            console.log(err);
        } else {
            console.log(networks);
            writeSuccessfulResponse(res, JSON.stringify(networks));
        }
    });
}

wifi.init({
    iface : "wlan0"
});

var server = http.createServer(function(req, res) {
    pathName= url.parse(req.url).pathname
    console.log(req.method);
    console.log(pathName);

    if(pathName.endsWith('.js') || pathName.endsWith('.html')
        || pathName.endsWith('.css')) {
        console.log(pathName[0]);
        pathName = pathName.replace(/^\/+/g, '');
        
        console.log(pathName);
        serveAsset(pathName, res);
    } else if(req.method == "POST" && pathName.endsWith("api/updatewifi")) {
        console.log("Updating Wifi");
    } else if(req.method == "GET" && pathName.endsWith("api/scan")) {
        scanWifi(res);
    } else if(req.method == "GET" && pathName.endsWith("api/current")) {
        currentWifi(res);
    } else {
        serveLandingPage(res);
    }
}).listen(8081);