# delphi-orm

Подкиньте в папку с проектом SchemaGenerator.exe. и в настройках проекта пропишите project-options-build events-prebuild events-command
$(PROJECTDIR)\SchemaGenerator migration="$(PROJECTDIR)\Classes\DataBase\Migrations\" , где "$(PROJECTDIR)\Classes\DataBase\Migrations\" путь к файлам для миграций

# Миграция

unit migration_001_create_users_table;

interface

uses
  OlfeiSchema;

implementation

begin
  OlfeiTable := NewTable('users'); // название таблицы

  OlfeiTable.NewString('name'); 
  OlfeiTable.NewString('password');
  OlfeiTable.NewString('login');
  OlfeiTable.NewTimestamps(); // created_at, update_at - как в ларавеле

end.

# Сид

unit migration_002_add_user_seed;

interface

uses
  OlfeiSchema;

implementation

begin
  OlfeiSeed := OlfeiTable.Seed;
  OlfeiSeed.Values['login'] := 'admin';
  OlfeiSeed.Values['password'] := '123';
  OlfeiSeed.Values['name'] := 'Администратор';
end.

# Модель

unit UserModel;

interface

uses
  OlfeiSQL, OlfeiORM, ApplicationModel, OlfeiCollection;

type
  [TOlfeiTable('users')]
  TUserModel = class(TOlfeiORM)
    public
      [TOlfeiField('login')]
      property Login: String index 0 read GetString write SetString;

      [TOlfeiField('password')]
      property Password: String index 1 read GetString write SetString;

      [TOlfeiField('name')]
      property Name: String index 2 read GetString write SetString;
  end;

  TUsersModels = class(TOlfeiCollection<TUserModel>)
    public
      constructor Create(FDB: TOlfeiDB); overload;
  end;

implementation

constructor TUsersModels.Create(FDB: TOlfeiDB);
begin
  inherited Create(FDB, TUserModel);
end;

end.

# Работа с моделями и коллекциями

    DB := initDB;// пример в коде найдёте
    Users := TUsersModels.Create(Db); //коллекция юзеров

    User := Users.Where('login', '=', Login).Where('password', '=', Pass).First;
    Result := User.Exists;

    Users.Free;// оичщаем коллекцию( саму модель не нужно)
    DB.Free;// после этого базу

# циклы

Users := TUsersModels.Create(Db);
for User in Users.All do
//

# Удаление записи
User.Delete;

#Очистка таблицы

Users.Truncate;


# Методы для коллекций
.Where('field', 'value)  // '='  // выборка
.where('field', '>', 'value')
.where('field, 'in', DB.Raw('(1, 2, 3)'))

.orderby('field', 'ASC/DESC') // сортировка

.limit('offset', 'limit') // лимит
.count // количество
.sum('field')// cумма
.all // все записи


список будет пополнятся






