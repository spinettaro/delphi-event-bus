{ *******************************************************************************
  Copyright 2016 Daniele Spinetti

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  ******************************************************************************** }

unit EventBus.Interfaces;

interface

type

  IRunnable = Interface(IInterface)
    ['{52602159-1B4C-46C9-9C78-79CE60D2F61A}']
    procedure Run;
  end;

implementation

end.
