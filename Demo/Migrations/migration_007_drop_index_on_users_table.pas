unit migration_007_drop_index_on_users_table;

interface

uses
  OlfeiSchema;

implementation

begin
  OlfeiTable := UpdateTable('users');

  OlfeiTable.DropIndex('name');
end.
