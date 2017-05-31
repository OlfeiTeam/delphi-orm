unit OlfeiUser;

interface

uses
  OlfeiSQL, OlfeiORM, OlfeiImage, System.Classes, OlfeiCollection;

type
  [TOlfeiTable('users')]
  TOlfeiUser = class(TOlfeiORM)
    private
      function GetOlfeiImages(index: integer): TOlfeiCollection<TOlfeiImage>;
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

      [TOlfeiCollectionField('id', 'user_id')]
      property Images: TOlfeiCollection<TOlfeiImage> index 0 read GetOlfeiImages;

      [TOlfeiPivotField('user_friend', 'user_id', 'friend_id')]
      property Friends: TOlfeiCollection<TOlfeiUser> index 1 read GetOlfeiFriends;
  end;

implementation

function TOlfeiUser.GetOlfeiImages(index: Integer): TOlfeiCollection<TOlfeiImage>;
begin
  Result := TOlfeiCollection<TOlfeiImage>(Self.GetForeignCollection(index, TOlfeiImage));
end;

function TOlfeiUser.GetOlfeiFriends(index: Integer): TOlfeiCollection<TOlfeiUser>;
begin
  Result := TOlfeiCollection<TOlfeiUser>(Self.GetPivotCollection(index, TOlfeiUser));
end;

end.
