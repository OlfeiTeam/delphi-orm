unit ORMDemoMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.ScrollBox, FMX.Memo,
  FireDAC.UI.Intf, FireDAC.FMXUI.Wait, FireDAC.Stan.Intf, FireDAC.Comp.UI,
  System.IniFiles, FireDac.Comp.Client, System.Generics.Collections, System.Threading;

type
  TfrmMain = class(TForm)
    btnCollection: TButton;
    mmoTest: TMemo;
    fdgxwtcrstTest: TFDGUIxWaitCursor;
    btnSingle: TButton;
    btnNew: TButton;
    procedure btnCollectionClick(Sender: TObject);
    procedure btnSingleClick(Sender: TObject);
    procedure btnNewClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

uses
  OlfeiSQL, OlfeiUser, OlfeiUsers, OlfeiTest,
    OlfeiORM, OlfeiCollection, OlfeiImage;

procedure TfrmMain.btnNewClick(Sender: TObject);
var
  OlfeiDB: TOlfeiDB;
  OlfeiUser, OlfeiFriend: TOlfeiUser;
  OlfeiImage: TOlfeiImage;
begin
  OlfeiDB := TOlfeiDB.Create;

  OlfeiDB.Parameters.Values['driver'] := 'mysql';
  OlfeiDB.Parameters.Values['host'] := '127.0.0.1';
  OlfeiDB.Parameters.Values['database'] := 'test';
  OlfeiDB.Parameters.Values['user'] := 'root';
  OlfeiDB.Parameters.Values['password'] := '';

  //OlfeiDB.Parameters.Values['driver'] := 'sqlite';
  //OlfeiDB.Parameters.Values['database'] := './test.sqlite';

  OlfeiDB.Connect;

  OlfeiUser := TOlfeiUser.Create(OlfeiDB);
  OlfeiUser.Find(1);

  // OlfeiUser.Attach();
  OlfeiUser.Avatar.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'test.txt');

  OlfeiUser.Save;

  mmoTest.Lines.Add(OlfeiUser.Avatar.DataString);
  mmoTest.Lines.Add(OlfeiUser.Avatar.DataString);
  mmoTest.Lines.Add(OlfeiUser.Avatar.DataString);
  mmoTest.Lines.Add(OlfeiUser.Avatar.DataString);

  {for OlfeiImage in OlfeiUser.Images.All do
    mmoTest.Lines.Add(OlfeiImage.Name); }

  for OlfeiFriend in OlfeiUser.Friends.All do
    mmoTest.Lines.Add('Friend: ' + OlfeiFriend.Name);

  OlfeiUser.Name := OlfeiUser.Name;

  OlfeiUser.Save;

  OlfeiUser.Free;

  OlfeiDB.Backup('test.sql');

  OlfeiDB.Free;
end;

procedure TfrmMain.btnSingleClick(Sender: TObject);
begin
  TTask.Run(procedure
  var
    OlfeiDB: TOlfeiDB;
    OlfeiTest: TOlfeiTest;
    OlfeiUsers: TOlfeiUsers;
//    OlfeiImage: TOlfeiImage;

    //OlfeiTest: TOlfeiTest;
    OlfeiTestCollection: TOlfeiCollection<TOlfeiTest>;

    i: integer;
  begin
    OlfeiDB := TOlfeiDB.Create;

    OlfeiDB.Parameters.Values['driver'] := 'sqlite';
    OlfeiDB.Parameters.Values['database'] := './test.sqlite';

    {OlfeiDB.Parameters.Values['driver'] := 'mysql';
    OlfeiDB.Parameters.Values['host'] := '192.168.1.6';
    OlfeiDB.Parameters.Values['database'] := 'menu';
    OlfeiDB.Parameters.Values['user'] := 'hrc';
    OlfeiDB.Parameters.Values['password'] := 'hrc.lan';}

    OlfeiDB.Connect;

    OlfeiTest := TOlfeiTest.Create(OlfeiDB, 1);
    Self.mmoTest.Lines.Add(OlfeiTest.User.Images.ID.ToString);

    {for i := 0 to 10 do
    begin
//      OlfeiUser := OlfeiUsers.Where('id', '=', '1').First;
//      OlfeiTest := OlfeiTestCollection.Where('id', '=', '1').First;
      //for OlfeiImage in OlfeiUser.Images.All do


      {
        OlfeiUser := TOlfeiUser.Create(OlfeiDB, 1);
        OlfeiUser.Free;
      }

      {if OlfeiImage.Exists then
        TThread.Synchronize(nil, procedure
        begin
          mmoTest.Lines.Add(OlfeiImage.Name);
        end);
    end;

    OlfeiTestCollection.Free;
    OlfeiUsers.Free;      }
    OlfeiTest.Free;
    OlfeiDB.Free;
  end);
end;

procedure TfrmMain.btnCollectionClick(Sender: TObject);
begin
  TTask.Run(procedure
  var
    OlfeiDB: TOlfeiDB;
    OlfeiUser: TOlfeiUser;
    OlfeiUsers: TOlfeiUsers;

    Str: string;
    i: Integer;
  begin
    OlfeiDB := TOlfeiDB.Create;

    OlfeiDB.Parameters.Values['driver'] := 'sqlite';
    OlfeiDB.Parameters.Values['database'] := './test.sqlite';

    OlfeiDB.Connect;

    OlfeiUsers := TOlfeiUsers.Create(OlfeiDB);
    str := OlfeiUsers.Where('id', '>', '0').ToJSON().ToJSON;

    mmoTest.Lines.Add(str);

    for i := 0 to 10 do
    begin
      for OlfeiUser in OlfeiUsers.Where('id', '>', '0').All do
      begin
        TThread.Synchronize(nil, procedure
        begin
          mmoTest.Lines.Add(OlfeiUser.Name);
        end);
      end;
    end;

    OlfeiUsers.Free;
    OlfeiDB.Free;
  end);
end;

end.
