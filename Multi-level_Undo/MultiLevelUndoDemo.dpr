program MultiLevelUndoDemo;

uses
  Forms,
  unitMainForm in 'unitMainForm.pas' {frmMain},
  CommandPatternClasses in 'CommandPatternClasses.pas',
  HideControlCommand in 'HideControlCommand.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
