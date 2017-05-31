unit migration_010_create_pivot_user_friend_table;

interface

uses
  OlfeiSchema;

implementation

begin
  OlfeiTable := PivotTable('user_friend');

  OlfeiTable.NewIntegerUnsigned('user_id');
  OlfeiTable.NewIntegerUnsigned('friend_id');

  OlfeiTable.NewForeign('users', 'user_id', 'id');
  OlfeiTable.NewForeign('users', 'friend_id', 'id');
end.
