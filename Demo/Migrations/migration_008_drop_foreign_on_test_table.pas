unit migration_008_drop_foreign_on_test_table;

interface

uses
  OlfeiSchema;

implementation

begin
  OlfeiTable := UpdateTable('test');

  OlfeiTable.DropForeign('user_id');
end.
