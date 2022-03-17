![alt text](/docs/DEB_Logo.png "DEB Logo")

# DEB an Event Bus framework for Delphi
Delphi Event Bus (for short DEB) is a publish/subscribe Event Bus framework for the Delphi platform.

DEB is designed to decouple different parts/layers of your application while still allowing them to communicate efficiently.
It was inspired by EventBus framework for the Android platform.

![alt text](/docs/DelphiEventBusArchitecture.png "Delphi Event Bus Architecture")

## Give it a star
Please "star" this project in GitHub! It costs nothing but helps to reference the code

![alt text](/docs/star_project.png "Give it a star")

## Features
* __Easy and clean:__ DelphiEventBus is super easy to learn and use because it respects KISS and "Convention over configuration" design principles. By using default TEventBus instance, you can start immediately to delivery and receive events 
* __Designed to decouple different parts/layers of your application__
* __Event Driven__
* __Attributes based API:__ Simply put the Subscribe attribute on your subscriber method you are able to receive a specific event
* __Support different delivery mode:__ Specifying the TThreadMode in Subscribe attribute, you can choose to delivery the event in the Main Thread or in a Background ones, regardless where an event was posted. The EventBus will manage Thread synchronization     
* __Unit Tested__
* __Thread Safe__

## Show me the code

### Events

1.Define events:

```delphi
IEvent = interface(IInterface)
['{3522E1C5-547F-4AB6-A799-5B3D3574D2FA}']
// additional information here
end;
```

2.Prepare subscribers:

 * Declare your subscribing method:
```delphi
[Subscribe]
procedure OnEvent(AEvent: IAnyTypeOfEvent);
begin
  // manage the event 	
end;
```

 * Register your subscriber:
```delphi
GlobalEventBus.RegisterSubscriberForEvents(Self);
```

3.Post events:
```delphi
GlobalEventBus.post(LEvent);
```

### Channels

1.Define channel:

```delphi
const MY_CHANNEL = 'MYCHANNEL'
```

2.Prepare subscribers:

 * Declare your subscribing method:
```delphi
[Channel(MY_CHANNEL)]
procedure OnMessage(AMsg: string);
begin
  // manage the message 	
end;
```

 * Register your subscriber:
```delphi
GlobalEventBus.RegisterSubscriberForChannels(Self);
```

3.Post event on channel:
```delphi
GlobalEventBus.post(MY_CHANNEL, 'My Message');
```



---

## Support
* DEB is a 100% ObjectPascal framework so it works on VCL and Firemonkey
* It works with Delphi2010 and major
* It works with latest version Alexandria

## Release Notes

### DEB 2.1

* NEW! Introduced dedicated thread pool for DEB threading 

### DEB 2.0

* NEW! Added new Interface based mechanism to declare and handle events!
* NEW! Added channels for simple string-based events
* NEW! Removed internal CloneEvent because now events are interface based! 

#### Breaking Changes

* A subscriber method can only have 1 parameter that is an IInterface or descendants
* EventBus.Post method can accept only an interface as parameter now


## License
  Copyright 2016-2022 Daniele Spinetti

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
