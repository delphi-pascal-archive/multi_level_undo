unit CommandPatternClasses;

interface

uses
  Classes, SysUtils, Contnrs, Controls, Dialogs;

type
  //The TCommand class wraps the functionality of executing a simple command
  //It is based on the Command design pattern by the gang of four, but allows
  //the ability to undo a command
  TCommand = class
  public
    //Method for executing the command
    procedure Execute; virtual; abstract;
    //Method for the ability to undo an command
    procedure Undo; virtual; abstract;
    //The text that shows up in the undo list
    function ActionText: string; virtual; abstract;
    //Returns whether or not the command can be undone 
    function CanUndo: Boolean; virtual; abstract;
  end;

  //The TCommandManager class manages the current list of commands
  //and provides the ability to perform multiple level undo and redo.
  //The class itself is instantiated with the number of undo level that can
  //be performed. 
  TCommandList = class(TObjectList)
  private
    function GetCommand(Index: integer): TCommand;
  public
    property Commands[Index: integer]: TCommand read GetCommand; default;
  end;

  TCommandManagerClass = class of TCommandManager;
  TCommandManager = class
  protected
    //Hold the number of commands that are stored
    FMaxUndoLevels: integer;
    //Holds the list of commands and position to work out the
    //undo/redo list.
    FCommands: TCommandList;
    FCommandPosition: integer;
    //Event for Notification that an change has occurred.
    FUpdateEvent: TNotifyEvent;
    procedure UndoSingleLevel; virtual;
    procedure RedoSingleLevel; virtual;
    procedure SetMaxUndoLevels(const Value: integer);
  public
    //Constructor and Destructor
    constructor Create; virtual;
    destructor Destroy; override;
    //Functions for working out the position of the Undo/Redo facility
    function AddCommand(ACommand: TCommand; ExecuteCommand: boolean = false): boolean;
    procedure Undo(UndoLevels: integer = 1); virtual;
    procedure Redo(UndoLevels: integer = 1); virtual;
    function CanUndo: boolean; virtual;
    function CanRedo: boolean; virtual;
    function CommandPosition: integer; virtual;
    procedure ClearCommandList; virtual;
    //The function returns the list of Undo/Redo Commands and each item
    //will contain the TCommand object to execute.
    procedure GetUndoList(AList: TStrings); virtual;
    procedure GetRedoList(AList: TStrings); virtual;
    //Methods to control the number of commands that are stored
    property MaxUndoLevels: integer read FMaxUndoLevels write SetMaxUndoLevels;
    //This notifies some object that a change has occurred to the update list
    procedure NotifyOfUpdate; virtual;
    property OnUpdateEvent: TNotifyEvent read FUpdateEvent write FUpdateEvent;
  end;

//The Singleton function to manage the Command class
function CommandManager: TCommandManager;
//Function for Registering descndants of TCommandManager
procedure RegisterCommandManagerClass(AClass: TCommandManagerClass);

implementation

{ TCommandList }

function TCommandList.GetCommand(Index: integer): TCommand;
begin
  Result := Items[Index] as TCommand;
end;

{ TCommandManager }

var
  __CommandManager: TCommandManager = nil;
  __CommandManagerClass: TCommandManagerClass = TCommandManager;

function CommandManager: TCommandManager;
begin
  if __CommandManager = nil then
    __CommandManager := __CommandManagerClass.Create;

  Result := __CommandManager;
end;

procedure RegisterCommandManagerClass(AClass: TCommandManagerClass);
begin
  __CommandManagerClass := AClass;
end;

function TCommandManager.AddCommand(ACommand: TCommand;
  ExecuteCommand: boolean = false): boolean;
var
  i: integer;
  ClearListAfter: boolean;
begin
  Result := false;
  ClearListAfter := false;
  //Adds a command to the list. The usual syntax to call this is
  //CommandManager.AddCommand(TConcreteCommand.Create(SomeParams));
  if ExecuteCommand then
    if not ACommand.CanUndo then
    begin
      if MessageDlg('Executing '+ AnsiQuotedStr(ACommand.ActionText, '''') +
        'cannot be undone. Are you sure you want to execute this command?',
        mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        begin
          ACommand.Execute;
          ClearListAfter := true;
        end
      else begin
        //The command will not be added. We should free the command
        //and the next time the command is executed it should be dynamically
        //created.
        ACommand.Free;
        Exit;
      end;
    end else
      ACommand.Execute;

  //When a new command is executes, it removes the ability for the other
  //commands to be redone.
  for i := FCommands.Count - 1 downto FCommandPosition do
    FCommands.Delete(i);

  //Add the command to the list
  FCommands.Add(ACommand);

  //Make sure that the number of commands does not exceed FUndoLevels
  if FCommands.Count > FMaxUndoLevels then
    FCommands.Delete(0);

  //Set the new cursor position
  FCommandPosition := FCommands.Count;

  //we clear the list after when the command cannot be undone.
  if ClearListAfter then
    ClearCommandList
  else begin
    //Update the component(s) that want to recieve notification.
    NotifyOfUpdate;
  end;

  Result := true;
end;

function TCommandManager.CanRedo: boolean;
begin
  Result := FCommandPosition < FCommands.Count;
end;

function TCommandManager.CanUndo: boolean;
begin
  Result := FCommandPosition > 0;
end;

procedure TCommandManager.ClearCommandList;
begin
  //Clear the list of commands from the list
  FCommandPosition := 0;
  FCommands.Clear;

  //Update the component(s) that want to recieve notification.
  NotifyOfUpdate;
end;

function TCommandManager.CommandPosition: integer;
begin
  Result := FCommandPosition;
end;

constructor TCommandManager.Create;
begin
  FCommands := TCommandList.Create(true);
  FCommandPosition := 0;
  FMaxUndoLevels := 25;
end;

destructor TCommandManager.Destroy;
begin
  FCommands.Free;
  FCommands := nil;

  inherited;
end;

procedure TCommandManager.GetRedoList(AList: TStrings);
var
  i: integer;
begin
  //The Redo List is the list of commands above the current
  //command list position
  AList.Clear;
  for i := FCommandPosition to FCommands.Count - 1 do
    AList.Add(FCommands[i].ActionText);
end;

procedure TCommandManager.GetUndoList(AList: TStrings);
var
  i: integer;
begin
  //The Undo List is the list of commands below the current
  //command list position
  AList.Clear;
  for i := FCommandPosition-1 downto 0 do
    AList.Add(FCommands[i].ActionText);
end;

procedure TCommandManager.NotifyOfUpdate;
begin
  //Send the update to the component interested in listing to it.
  if Assigned(OnUpdateEvent) then
    OnUpdateEvent(Self);
end;

procedure TCommandManager.Redo(UndoLevels: integer = 1);
var
  counter: integer;
begin
  //Redo the commands
  for counter := 1 to UndoLevels do
    RedoSingleLevel;

  //Update the component(s) that want to recieve notification.
  NotifyOfUpdate;
end;

procedure TCommandManager.RedoSingleLevel;
begin
  //Redo the command from the command list
  if FCommandPosition < FCommands.Count then
  begin
    //We can redo this action
    //Lets redo it
    FCommandPosition := FCommandPosition + 1;
    FCommands[FCommandPosition-1].Execute;
  end;
end;

procedure TCommandManager.SetMaxUndoLevels(const Value: integer);
begin
  FMaxUndoLevels := Value;

  //When the new max undo levels are set clear the commands
  ClearCommandList;
end;

procedure TCommandManager.Undo(UndoLevels: integer = 1);
var
  counter: integer;
begin
  //Undo the commands
  for counter := 1 to UndoLevels do
    UndoSingleLevel;

  //Update the component(s) that want to recieve notification.
  NotifyOfUpdate;
end;

procedure TCommandManager.UndoSingleLevel;
begin
  //Undo a single command
  if FCommandPosition > 0 then
  begin
    //We can undo this action
    //Lets undo it
    FCommands[FCommandPosition-1].Undo;
    FCommandPosition := FCommandPosition - 1;
  end;
end;

end.
 