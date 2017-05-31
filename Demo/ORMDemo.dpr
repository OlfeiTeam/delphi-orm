program ORMDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  ORMDemoMain in 'ORMDemoMain.pas' {frmMain},
  OlfeiUsers in 'Collections\OlfeiUsers.pas',
  migration_001_create_users_table in 'Migrations\migration_001_create_users_table.pas',
  migration_002_create_test_table in 'Migrations\migration_002_create_test_table.pas',
  migration_003_add_seeds_to_test_table in 'Migrations\migration_003_add_seeds_to_test_table.pas',
  OlfeiTest in 'Models\OlfeiTest.pas',
  OlfeiUser in 'Models\OlfeiUser.pas',
  migration_004_update_price_in_users_table in 'Migrations\migration_004_update_price_in_users_table.pas',
  migration_005_delete_birthday_from_users_table in 'Migrations\migration_005_delete_birthday_from_users_table.pas',
  migration_006_create_images_table in 'Migrations\migration_006_create_images_table.pas',
  OlfeiImages in 'Collections\OlfeiImages.pas',
  OlfeiImage in 'Models\OlfeiImage.pas',
  migration_007_drop_index_on_users_table in 'Migrations\migration_007_drop_index_on_users_table.pas',
  migration_008_drop_foreign_on_test_table in 'Migrations\migration_008_drop_foreign_on_test_table.pas',
  migration_009_add_avatar_to_users_table in 'Migrations\migration_009_add_avatar_to_users_table.pas',
  migration_010_create_pivot_user_friend_table in 'Migrations\migration_010_create_pivot_user_friend_table.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
