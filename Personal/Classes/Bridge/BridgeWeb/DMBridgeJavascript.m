//
//  DMBridgeJavascript.m
//  Deck
//
//  Created by 杨涵 on 16/8/9.
//  Copyright © 2016年 yanghan. All rights reserved.
//

#import "DMBridgeJavascript.h"

NSString * DMBridgeJavascript() {
#define __js_func__(x) #x
    
    static NSString *jsCode = @__js_func__(
                                           ;(function(){
        
        if("undefined" == typeof galleon){
            galleon = {};
        }
        
        galleon.Bridge = {
            
            _sendToNative: function(url,async,message){
                
                var deckRequest = new XMLHttpRequest();
                deckRequest.open('POST',url,async);
                deckRequest.setRequestHeader('content-type','application/x-www-form-urlencoded');
                deckRequest.send(JSON.stringify(message));
                
                if (async) {
                    return null;
                }
                var result = deckRequest.responseText;
                return result;
            }
            
        };
        
        galleon.anchor = {
            reload: function() { },
            back: function() {
                var message = {'handlerName':'galleon.anchor.back'};
                galleon.Bridge._sendToNative('https://galleon.dmall.com/bridge/navigator',true,message);
            }
        };
        
        galleon.Navigator = {
            currentUrl: null,
            currentPos:-1,
            prevUrl:null,
            prevPos:-1,
                
            forward: function(url,context) {
                if (typeof url == 'undefined') {
                    return;
                }
                if (typeof context == 'undefined') {
                    context = null;
                }
                
                var message = {'handlerName':'galleon.navigator.forward','data':{'url':url,'context':context}};
                galleon.Bridge._sendToNative('https://galleon.dmall.com/bridge/navigator',true,message);
            },
                
            backward: function(param,count,context) {
                if (typeof param == 'undefined') {
                    param = null;
                }
                if (typeof count == 'undefined') {
                    count = 1;
                }
                if (typeof context == 'undefined') {
                    context = null;
                }
            
                var message = {'handlerName':'galleon.navigator.backward','data':{'param':param,'backCount':String(count),'context':context}};
                galleon.Bridge._sendToNative('https://galleon.dmall.com/bridge/navigator',true,message);
            },
                
            replace: function(url,context) {
                if (typeof url == 'undefined') {
                    return;
                }
                if (typeof context == 'undefined') {
                    context = null;
                }
                
                var message = {'handlerName':'galleon.navigator.replace','data':{'url':url,'context':context}};
                galleon.Bridge._sendToNative('https://galleon.dmall.com/bridge/navigator',true,message);
            },
                
            pushFlow: function() {
                var message = {'handlerName':'galleon.navigator.pushFlow'};
                galleon.Bridge._sendToNative('https://galleon.dmall.com/bridge/navigator',true,message);
            },
                
            popFlow: function(param,context) {
                if (typeof context == 'undefined') {
                    context == null;
                }
        
                var message = {'handlerName':'galleon.navigator.popFlow','data':{'param':param,'context':context}};
                galleon.Bridge._sendToNative('https://galleon.dmall.com/bridge/navigator',true,message);
            },
                
            replaceState: function (path) {
                if (typeof path == 'undefined') {
                    return;
                }
                
                var message = {'handlerName':'galleon.navigator.replaceState','data':{'url':path}};
                galleon.Bridge._sendToNative('https://galleon.dmall.com/bridge/navigator',true,message);
            }
            
        };
        
        galleon.Storage = {
            
            set: function(value,key) {
                var message = {'handlerName':'galleon.storage.set','data':{'keyName':key,'valueData':value}};
                return galleon.Bridge._sendToNative('https://galleon.dmall.com/bridge/storage',false,message);
            },
                
            setContext: function(context) {
                var message = {'handlerName':'galleon.storage.setContext','data':{'valueData':context}};
                return galleon.Bridge._sendToNative('https://galleon.dmall.com/bridge/storage',false,message);
            },
                
            get: function(key) {
                var message = {'handlerName':'galleon.storage.get','data':{'keyName':key}};
                return galleon.Bridge._sendToNative('https://galleon.dmall.com/bridge/storage',false,message);
            },
                
            getContext: function() {
                var message = {'handlerName':'galleon.storage.getContext'};
                return galleon.Bridge._sendToNative('https://galleon.dmall.com/bridge/storage',false,message);
            },
                
            remove: function(key) {
                var message = {'handlerName':'galleon.storage.remove','data':{'keyName':key}};
                return galleon.Bridge._sendToNative('https://galleon.dmall.com/bridge/storage',false,message);
            }
        };
    })();
                                           );
#undef __js_func__
    return jsCode;
}
