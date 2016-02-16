unit PosterU;

interface

uses InterfacesU;

{type

  TAsyncPoster = class(TInterfacedObject, IRunnable)
  end;

  TBackgroundPoster = class(TInterfacedObject, IRunnable)
  end;

  TMainThreadPoster = class(TInterfacedObject, IRunnable)
  end;   }

implementation

end.
