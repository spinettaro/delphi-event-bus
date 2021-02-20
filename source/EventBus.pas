{*******************************************************************************
  Copyright 2016-2020 Daniele Spinetti

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  ********************************************************************************}

/// <summary>
///   This unit provides public interfaces and classes for the Delphi Event Bus (DEB) framework.
/// </summary>
unit EventBus;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Provides public interface of event bus implementation. Two types of
  ///   events are allowed:
  ///   <list type="bullet">
  ///     <item>
  ///       Interface-typed event, represented by an user-defined interface.
  ///       An optional Context string can be posted together with the event.
  ///       The event will be routed to proper subsriber methods based on the
  ///       event type as well as the Context string.
  ///     </item>
  ///     <item>
  ///       Named-channel message. A string-typed message will be routed to proper
  ///       subscriber methods based on the name of the channel.
  ///     </item>
  ///   </list>
  ///   Depending on the <i>thread mode</i> of the subscriber method, the
  ///   subscriber method can be invoked in the main thread, the posting thread,
  ///   or a newly spawned background thread.
  /// </summary>
  IEventBus = interface
    ['{7BDF4536-F2BA-4FBA-B186-09E1EE6C7E35}']
    /// <summary>
    ///   Checks if the subscriber object has been registered with the event
    ///   bus for receiving named-channel messages.
    /// </summary>
    /// <param name="ASubscriber">
    ///   The subscriber object to check, which should have methods with Channel attribute.
    /// </param>
    function IsRegisteredForChannels(ASubscriber: TObject): Boolean;

    /// <summary>
    ///   Checks if the subscriber object has been registered with the subject
    ///   event bus for receiving interface-typed events.
    /// </summary>
    /// <param name="ASubscriber">
    ///   The subscriber object to check, which should have methods with Subscribe attribute.
    /// </param>
    function IsRegisteredForEvents(ASubscriber: TObject): Boolean;

    /// <summary>
    ///   Posts a named-channel message to the event bus.
    /// </summary>
    /// <param name="AChannel">
    ///   The name of the channel
    /// </param>
    /// <param name="AMessage">
    ///   The message to be posted
    /// </param>
    procedure Post(const AChannel: string; const AMessage: string); overload;

    /// <summary>
    ///   Posts an interface-typed event to the event bus.
    /// </summary>
    /// <param name="AEvent">
    ///   User defined interface-typed event.
    /// </param>
    /// <param name="AContext">
    ///   Context of the event. It will be jointly used by the event bus
    ///   to route the event to proper subscriber methods.
    /// </param>
    procedure Post(const AEvent: IInterface; const AContext: string = ''); overload;

    /// <summary>
    ///   Registers a new subscriber for named-channel messages.
    /// </summary>
    /// <param name="ASubscriber">
    ///   The subscriber object to register, which should have methods with
    ///   Channel attribute.
    /// </param>
    /// <exception cref="EInvalidSubscriberMethod">
    ///   Throws whenever a subscriber method of the subscriber object has
    ///   invalid number of arguments or invalid argument type.
    /// </exception>
    /// <exception cref="EObjectHasNoSubscriberMethods">
    ///   Throws when the subscriber object does not have any methods with
    ///   Channel attribute defined.
    /// </exception>
    procedure RegisterSubscriberForChannels(ASubscriber: TObject);

    /// <summary>
    ///   Registers a new subscriber for named-channel messages.
    /// </summary>
    /// <param name="ASubscriber">
    ///   The subscriber object to register, which should have methods with
    ///   Channel attribute.
    /// </param>
    /// <exception cref="EInvalidSubscriberMethod">
    ///   Throws whenever a subscriber method of the subscriber object has
    ///   invalid number of arguments or invalid argument type.
    /// </exception>
    /// <remarks>
    ///   There won't be any exception thrown if the subscriber object has no
    ///   subscriber methods defined.
    /// </remarks>
    procedure SilentRegisterSubscriberForChannels(ASubscriber: TObject);

    /// <summary>
    ///   Unregisters a subscriber from receiving named-channel messages.
    /// </summary>
    /// <param name="ASubscriber">
    ///   The subscriber to unregister.
    /// </param>
    procedure UnregisterForChannels(ASubscriber: TObject);

    /// <summary>
    ///   Registers a subscriber for interface-typed events.
    /// </summary>
    /// <param name="ASubscriber">
    ///   The subscriber object to register, which should have methods with
    ///   Subscribe attributes.
    /// </param>
    /// <exception cref="EInvalidSubscriberMethod">
    ///   Throws whenever a subscriber method of the subscriber object has
    ///   invalid number of arguments or invalid argument type.
    /// </exception>
    /// <exception cref="EObjectHasNoSubscriberMethods">
    ///   Throws when the subscriber object does not have any methods with
    ///   Subscribe attribute defined.
    /// </exception>
    procedure RegisterSubscriberForEvents(ASubscriber: TObject);

    /// <summary>
    ///   Registers a subscriber for interface-typed events.
    /// </summary>
    /// <param name="ASubscriber">
    ///   The subscriber object to register, which should have methods with
    ///   Subscribe attributes.
    /// </param>
    /// <exception cref="EInvalidSubscriberMethod">
    ///   Throws whenever a subscriber method of the subscriber object has
    ///   invalid number of arguments or invalid argument type.
    /// </exception>
    /// <remarks>
    ///   There won't be any exception thrown if the subscriber object has no
    ///   subscriber methods defined.
    /// </remarks>
    procedure SilentRegisterSubscriberForEvents(ASubscriber: TObject);

    /// <summary>
    ///   Unregisters a subscriber from receiving interface-typed events.
    /// </summary>
    /// <param name="ASubscriber">
    ///   The subscriber object to unregister.
    /// </param>
    procedure UnregisterForEvents(ASubscriber: TObject);

    /// <summary>
    ///   Register a new context for a given event of a specific subscriber.
    /// </summary>
    /// <param name="ASubscriber">
    ///   The subscriber object who holds the event.
    /// </param>
    /// <param name="AEvent">
    ///   The event you want to change the context.
    /// </param>
    /// <param name="ANewContext">
    ///   The old context value to replace.
    /// </param>
    /// <param name="ANewContext">
    ///   The new context value.
    /// </param>
    procedure RegisterNewContext(ASubscriber: TObject; AEvent: IInterface; const AOldContext: String; const ANewContext: String);
  end;

type
  /// <summary>
  ///   Provides a generic interface for user-defined interface-typed event.
  ///   It wraps up a generic data object that a user-defined interface can
  ///   instantiate.
  /// </summary>
  /// <remarks>
  ///   A user defined interface-typed event can either inherit from
  ///   IDEBEvent&lt;T&gt;, or from IInterface directly. If inherited from the latter,
  ///   the user defined interface-typed event must handle implementation details itself.
  /// </remarks>
  IDEBEvent<T> = interface(IInterface)
  ['{AFDFF9C9-46D8-4663-9535-2BBB1396587C}']
    {$REGION 'Property Gettors and Settors'}
    function Get_Data: T;
    procedure Set_Data(const AValue: T);
    function Get_OwnsData: Boolean;
    procedure Set_OwnsData(const AValue: Boolean);
    {$ENDREGION}
    /// <summary>
    ///   The wrapped data
    /// </summary>
    property Data: T read Get_Data write Set_Data;
    /// <summary>
    ///   Whether the data is owned by the subject event. If so, the data's
    ///   life will be managed by the event.
    /// </summary>
    property OwnsData: Boolean read Get_OwnsData write Set_OwnsData;
  end;

  /// <summary>
  ///   Implements IDEBEvent&lt;T&gt; interface.
  /// </summary>
  TDEBEvent<T> = class(TInterfacedObject, IDEBEvent<T>)
  private
    FData: T;
    FOwnsData: Boolean;
    function Get_Data: T;
    procedure Set_Data(const AValue: T);
    function Get_OwnsData: Boolean;
    procedure Set_OwnsData(const AValue: Boolean);
  public
    constructor Create; overload;
    constructor Create(AData: T); overload;
    destructor Destroy; override;

    property Data: T read FData write Set_Data;
    property OwnsData: Boolean read Get_OwnsData write Set_OwnsData;
  end;

type
  /// <summary>
  ///   Thead mode of the subscriber method.
  /// </summary>
  TThreadMode = (
    /// <summary>
    ///   The subscriber method will be invoked in the same posting thread where
    ///   IEventBus.Post is called.
    /// </summary>
    Posting,

    /// <summary>
    ///   The subscriber method will be invoked in the main thread.
    /// </summary>
    Main,

    /// <summary>
    ///   The subscriber method will be invoked asynchronously in a new thread
    ///   other than the posting thread.
    /// </summary>
    Async,

    /// <summary>
    ///   If the posting thread is the main thread, the subscriber method will
    ///   be invoked asynchronously in a new thread other than the posting
    ///   thread. If the posting thread is NOT the main thread, the subscriber
    ///   method will be invoked synchronously in the same posting thread.
    /// </summary>
    Background
  );

type
  TSubscriberMethodAttribute = class abstract (TCustomAttribute)
  strict private
    FContext: string;
    FThreadMode: TThreadMode;
  strict protected
    function Get_ArgTypeKind: TTypeKind; virtual; abstract;

    /// <param name="AThreadMode">
    ///   Thread mode of the subscriber method.
    /// </param>
    /// <param name="AContext">
    ///   Context of event.
    /// </param>
    /// <seealso cref="TEventBusThreadMode" />
    constructor Create(AThreadMode: TThreadMode; const AContext: string);
  public
    /// <summary>
    ///   Thread mode of the subscriber method.
    /// </summary>
    property ThreadMode: TThreadMode read FThreadMode;

    /// <summary>
    ///   Context of the subscriber method.
    /// </summary>
    property Context: string read FContext;

    /// <summary>
    ///   Required argment type of the subscriber method.
    /// </summary>
    property ArgTypeKind: TTypeKind read Get_ArgTypeKind;
  end;

  /// <summary>
  ///   Subscriber attribute must be specified to subscriber methods in
  ///   order to receive interface-typed events.
  /// </summary>
  SubscribeAttribute = class(TSubscriberMethodAttribute)
  strict protected
    function Get_ArgTypeKind: TTypeKind; override;
  public
    constructor Create(AThreadMode: TThreadMode = TThreadMode.Posting; const AContext: string = '');
  end;

  /// <summary>
  ///   Channel attribute must be specified to subscriber methods in order
  ///   to receive named-channel messages.
  /// </summary>
  ChannelAttribute = class(TSubscriberMethodAttribute)
  strict private
    function Get_Channel: string;
  strict protected
    function Get_ArgTypeKind: TTypeKind; override;
  public
    /// <param name="AChannel">
    ///   Name of the channel
    /// </param>
    /// <param name="AThreadMode">
    ///   Thread mode of the subscriber method
    /// </param>
    constructor Create(const AChannel: string; AThreadMode: TThreadMode = TThreadMode.Posting);

    /// <summary>
    ///   Name of the channel.
    /// </summary>
    property Channel: string read Get_Channel;
  end;

  /// <summary>
  ///   Throws whenever a subscriber method has invalid number of arguments or
  ///   invalid argument type.
  /// </summary>
  EInvalidSubscriberMethod = class(Exception)
  end;

  /// <summary>
  ///   Throws when a subscriber object does not have any methods with Channel
  ///   or Subscribe attribute defined.
  /// </summary>
  EObjectHasNoSubscriberMethods = class(Exception)
  end;

  /// <summary>
  ///   Throws when a user trying to register a method of a subscriber object
  ///   that has been already registered.
  /// </summary>
  ESubscriberMethodAlreadyRegistered = class(Exception)
  end;

  /// <summary>
  ///   Throws when an unknown thread mode is specified.
  /// </summary>
  EUnknownThreadMode = class(Exception)
  end;

  /// <summary>
  ///   Throws when exception occurs during subscriber method invokation.
  /// </summary>
  EInvokeSubscriberError = class(Exception)
  end;

/// <summary>
///   Singleton global event bus.
/// </summary>
function GlobalEventBus: IEventBus;

implementation

uses
  System.Rtti, EventBus.Core;

function GlobalEventBus: IEventBus;
begin
  Result := TEventBusFactory.GlobalEventBus;
end;

constructor TDEBEvent<T>.Create;
begin
  inherited Create;
end;

constructor TDEBEvent<T>.Create(AData: T);
begin
  inherited Create;
  OwnsData := True;
  Data := AData;
end;

destructor TDEBEvent<T>.Destroy;
var
  LValue: TValue;
begin
  LValue := TValue.From<T>(Data);
  if (LValue.IsObject) and OwnsData then LValue.AsObject.Free;
  inherited;
end;

function TDEBEvent<T>.Get_Data: T;
begin
  Result:= FData;
end;

procedure TDEBEvent<T>.Set_Data(const AValue: T);
begin
  FData := AValue;
end;

function TDEBEvent<T>.Get_OwnsData: Boolean;
begin
  Result:= FOwnsData;
end;

procedure TDEBEvent<T>.Set_OwnsData(const AValue: Boolean);
begin
  FOwnsData := AValue;
end;

constructor SubscribeAttribute.Create(AThreadMode: TThreadMode = TThreadMode.Posting; const AContext: string = '');
begin
  inherited Create(AThreadMode, AContext);
end;

function SubscribeAttribute.Get_ArgTypeKind: TTypeKind;
begin
  Result := TTypeKind.tkInterface;
end;

constructor ChannelAttribute.Create(const AChannel: string; AThreadMode: TThreadMode = TThreadMode.Posting);
begin
  inherited Create(AThreadMode, AChannel);
end;

function ChannelAttribute.Get_ArgTypeKind: TTypeKind;
begin
  Result := TTypeKind.tkUString;
end;

function ChannelAttribute.Get_Channel: string;
begin
  Result := Context;
end;

constructor TSubscriberMethodAttribute.Create(AThreadMode: TThreadMode; const AContext: string);
begin
  inherited Create;
  FContext := AContext;
  FThreadMode := AThreadMode;
end;

end.

