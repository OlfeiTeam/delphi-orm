program SchemaGenerator;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, Classes;

var
  i: Integer;
  SL, SLFiles: TStringList;
  SearchResult: TSearchRec;
  
begin
  try
    SL := TStringList.Create;

    for i := 1 to ParamCount do
      SL.Add(ParamStr(i));

    if SL.IndexOfName('project') = -1 then
      SL.Values['project'] := ExtractFilePath(ParamStr(0));

    if SL.IndexOfName('migration') = -1 then
      SL.Values['migration'] := ExtractFilePath(ParamStr(0)) + 'Migrations';

    SLFiles := TStringList.Create;
    if FindFirst(SL.Values['migration'] + '\migration_*.*', faAnyFile, searchResult) = 0 then
    begin
      repeat
        SLFiles.Add(StringReplace(SearchResult.Name, '.pas', '', []) + ',');
      until FindNext(SearchResult) <> 0;
 
      FindClose(searchResult);
    end;

    SLFiles.SaveToFile(SL.Values['project'] + '\schema.inc');

    SLFiles.Free;
    SL.Free;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
