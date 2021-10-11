unit HideControlCommand;

interface

uses
  SysUtils, Classes, Controls, CommandPatternClasses;

type
  THideControlCommand = class (TCommand)
  protected
    FControl: TControl;
  public
    constructor Create(AControl: TControl);
    function ActionText: string; override;
    function CanUndo: Boolean; override;
    procedure Execute; override;
    procedure Undo; override;
  end;
  
implementation

{ THideControlCommand }

{
***************************** THideControlCommand ******************************
}
constructor THideControlCommand.Create(AControl: TControl);
begin
  FControl := AControl;
end;

function THideControlCommand.ActionText: string;
begin
  Result := 'hide '+AnsiQuotedStr(FControl.Name, '"');
end;

function THideControlCommand.CanUndo: Boolean;
begin
  Result := true;
end;

procedure THideControlCommand.Execute;
begin
  FControl.Hide;
end;

procedure THideControlCommand.Undo;
begin
  FControl.Show;
end;

end.

