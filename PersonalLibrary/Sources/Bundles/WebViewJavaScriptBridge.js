 (function() {
	  if(window.WebViewJavaScriptBridge) {
	        return;
	  }

	  if (!window.onerror) {
	  		window.onerror = function(msg, url, line) {
	  			console.log("WebViewJavaScriptBridge:error:" + msg + "@" + 
	  				url + ":" + line);
	  		}
	  }
	  window.WebViewJavaScriptBridge = {
	  		registerHandler: registerHandler,
	  		callHandler: callHandler,
	  		disableJavaScriptAlertBoxSafetyTimeout: disableJavaScriptAlertBoxSafetyTimeout,
	  		_fetchQueue: _fetchQueue,
	  		_handleMessageFromObjc: _handleMessageFromObjc
	  };

	  var messagingIframe;
	  var sendMessageQuieue = [];
	  var messageHandlers = {};

	  var responseCallbacks = {};
	  var uniqueId = 1;
	  var dispatchMessagesWithTimeoutSafety = true;

	  function registerHandler (handlerName, handler) {
	  	messageHandlers[handlerName] = handler;
	  }

	  function callHandler (handlerName, data, responseCallback) {
	  	if (arguments.length == 2 && typeof data == 'function') {
	  		responseCallback = data;
	  		data = null;
	  	}
	  	_doSend({handlerName:handlerName, data:data}, responseCallback);
	  }

	  function disableJavaScriptAlertBoxSafetyTimeout () {
	  	dispatchMessagesWithTimeoutSafety = false;
	  }

	  function _doSend (message, responseCallback) {
	  	if (responseCallback) {
	  		var callbackId = 'cb_' + (uniqueId++) + '_' + new Date().getTime();
	  		responseCallbacks[callbackId] = responseCallback;
	  		message['callbackId'] = callbackId;
	  	};
	  	sendMessageQuieue.push(message);
	  	messagingIframe.src = 'personal://__queue_message__';
	  }

	  function _fetchQueue () {
	  	var messageQueueString = JSON.stringify(sendMessageQuieue);
	  	sendMessageQuieue = [];
	  	return messageQueueString;
	  }

	  function _dispatchMessageFromObjc (messageJSON) {
	  	if (dispatchMessagesWithTimeoutSafety) {
	  		setTimeout(_doDispatchMessageFromObjc);
	  	}else {
	  		_doDispatchMessageFromObjc();
	  	}

	  	function _doDispatchMessageFromObjc () {
	  		var message = JSON.parse(messageJSON);
	  		var messageHandler;
	  		var responseCallback;

	  		if (message.responseId) {
	  			responseCallback = responseCallbacks[message.responseId];
	  			if (!responseCallback) {
	  				return;
	  			}
	  			responseCallback(message.responseData);
	  			delete responseCallbacks[message.responseId];
	  		}else {
	  			if (message.callbackId) {
	  				var callbackResponseId = message.callbackId;
	  				responseCallback = function(responseData) {
	  					_doSend({handlerName:message.handlerName, responseId:callbackResponseId,
	  						responseData:responseData});
	  				};
	  			}

	  			var handler = messageHandlers[message.handlerName];
	  			if (!handler) {
	  				console.log("WebViewJavaScriptBridge:warning:no handler for message from objc",
	  					message);
	  			}else {
	  				handler(message.data, responseCallback);
	  			}
	  		}
	  	}
	  }

	  function _handleMessageFromObjc (messageJSON) {
	  	_dispatchMessageFromObjc(messageJSON);
	  }

	  messagingIframe = document.createElement('iframe');
	  messagingIframe.style.display = 'none';
	  messagingIframe.src = 'personal://__queue_message__';
	  document.documentElement.appendChild(messagingIframe);

	  registerHandler("_disableJavaScriptAlertBoxSafetyTimeout",disableJavaScriptAlertBoxSafetyTimeout);

	  setTimeout(_callCallbacks,0);
	  function _callCallbacks () {
	  	var callbacks = window.callbacks;
	  	delete window.callbacks;
	  	for (var i = 0; i < callbacks.length; i++) {
	  		callbacks[i](WebViewJavaScriptBridge);
	  	}
	  }
  })();