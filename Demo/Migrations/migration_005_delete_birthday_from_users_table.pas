unit migration_005_delete_birthday_from_users_table;

interface

uses
  OlfeiSchema;

implementation

begin
  OlfeiTable := UpdateTable('users');

  OlfeiTable.Drop('test');
end.

