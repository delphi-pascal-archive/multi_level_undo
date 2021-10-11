unit unitMainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, ComCtrls, ToolWin, StdCtrls, ImgList, Menus;

type
  TfrmMain = class(TForm)
    ToolBar1: TToolBar;
    btnUndo: TToolButton;
    btnRedo: TToolButton;
    imgGarbageBin: TImage;
    ImageList1: TImageList;
    lblGarbageBin: TLabel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    Button9: TButton;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    CheckBox5: TCheckBox;
    CheckBox6: TCheckBox;
    CheckBox7: TCheckBox;
    TrackBar1: TTrackBar;
    ProgressBar1: TProgressBar;
    Label2: TLabel;
    pmnuUndo: TPopupMenu;
    pmnuRedo: TPopupMenu;
    ToolButton1: TToolButton;
    procedure imgGarbageBinDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure imgGarbageBinDragDrop(Sender, Source: TObject; X,
      Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure btnUndoClick(Sender: TObject);
    procedure btnRedoClick(Sender: TObject);
  private
    procedure CommandViewUpdate(Sender: TObject);
    procedure PopulatePopupMenus(PopupMenu: TPopupMenu; ACommands: TStrings;
      Handler: TNotifyEvent);
    procedure RedoLevels(Sender: TObject);
    procedure UndoLevels(Sender: TObject);
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

uses CommandPatternClasses, HideControlCommand;

{$R *.dfm}

procedure TfrmMain.imgGarbageBinDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
begin
  Accept := true;
end;

procedure TfrmMain.imgGarbageBinDragDrop(Sender, Source: TObject; X,
  Y: Integer);
begin
  CommandManager.AddCommand(
    THideControlCommand.Create(Source as TControl), true);
end;

procedure TfrmMain.CommandViewUpdate(Sender: TObject);
var
  CommandStrings: TStrings;
begin
  //Update the visual components

  //Change the display of the buttons
  btnUndo.Enabled := CommandManager.CanUndo;
  btnRedo.Enabled := CommandManager.CanRedo;

  //Populate the Popup Menus
  CommandStrings := TStringList.Create;
  try
    CommandManager.GetUndoList(CommandStrings);
    PopulatePopupMenus(pmnuUndo, CommandStrings, UndoLevels);

    CommandManager.GetRedoList(CommandStrings);
    PopulatePopupMenus(pmnuRedo, CommandStrings, RedoLevels);
  finally
    CommandStrings.Free;
  end; 
end;

procedure TfrmMain.PopulatePopupMenus(PopupMenu: TPopupMenu;
  ACommands: TStrings; Handler: TNotifyEvent);
var
  counter: integer;
  Item: TMenuItem;
begin
  //Remove the items
  while PopupMenu.Items.Count > 0 do
    PopupMenu.Items.Delete(0);

  for counter := 0 to ACommands.Count - 1 do
  begin
    //Add the item to the Menu Item
    Item := TMenuItem.Create(Self);
    Item.Caption := ACommands[counter];
    Item.Tag := counter + 1;
    Item.OnClick := Handler;
    PopupMenu.Items.Add(Item);
  end;
end;

procedure TfrmMain.RedoLevels(Sender: TObject);
var
  LevelsToRedo: integer;
begin
  LevelsToRedo := (Sender as TMenuItem).Tag;
  CommandManager.Redo(LevelsToRedo);
end;

procedure TfrmMain.UndoLevels(Sender: TObject);
var
  LevelsToUndo: integer;
begin
  LevelsToUndo := (Sender as TMenuItem).Tag;
  CommandManager.Undo(LevelsToUndo);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  CommandManager.OnUpdateEvent := CommandViewUpdate;

  //At most we will be able to undo eight operations
  CommandManager.MaxUndoLevels := 8;
end;

procedure TfrmMain.btnUndoClick(Sender: TObject);
begin
  CommandManager.Undo;
end;

procedure TfrmMain.btnRedoClick(Sender: TObject);
begin
  CommandManager.Redo;
end;

end.
