unit OlfeiUser;

interface

uses
  OlfeiSQL, OlfeiORM, OlfeiImage, System.Classes, OlfeiCollection;

type
  [TOlfeiTable('users')]
  TOlfeiUser = class(TOlfeiORM)
    private
      function GetOlfeiImage(index: Integer): TOlfeiImage;
      function GetOlfeiFriends(index: integer): TOlfeiCollection<TOlfeiUser>;
    public
      [TOlfeiField('name')]
      property Name: String index 0 read GetString write SetString;

      [TOlfeiField('count')]
      property Count: Integer index 1 read GetInteger write SetInteger;

      [TOlfeiField('price')]
      property Price: Real index 2 read GetFloat write SetFloat;

      [TOlfeiField('description')]
      property Description: String index 3 read GetString write SetString;

      [TOlfeiField('active')]
      property Active: Boolean index 4 read GetBoolean write SetBoolean;

      [TOlfeiField('birthday')]
      property Birthday: TDate index 5 read GetDate write SetDate;

      [TOlfeiField('last')]
      property Last: TDateTime index 6 read GetDateTime write SetDateTime;

      [TOlfeiBlobField('avatar')]
      property Avatar: TStringStream index 0 read GetBlob;

      [TOlfeiForeignField('id', 'user_id')]
      property Images: TOlfeiImage index 0 read GetOlfeiImage;

      [TOlfeiPivotField('user_friend', 'user_id', 'id', 'friend_id', 'id')]
      property Friends: TOlfeiCollection<TOlfeiUser> index 1 read GetOlfeiFriends;
  end;

implementation

function TOlfeiUser.GetOlfeiImage(index: Integer): TOlfeiImage;
begin
  Result := TOlfeiImage(Self.GetForeignObject(index, TOlfeiImage));
end;

function TOlfeiUser.GetOlfeiFriends(index: Integer): TOlfeiCollection<TOlfeiUser>;
begin
  Result := TOlfeiCollection<TOlfeiUser>(Self.GetPivotCollection(index, TOlfeiUser));
end;

end.
