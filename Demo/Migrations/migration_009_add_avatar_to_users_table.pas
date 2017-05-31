unit migration_009_add_avatar_to_users_table;

interface

uses
  OlfeiSchema;

implementation

begin
  OlfeiTable := UpdateTable('users');

  OlfeiTable.NewBlob('avatar');
end.
