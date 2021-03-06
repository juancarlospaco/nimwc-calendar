import strutils
when defined(postgres): import db_postgres
else:                   import db_sqlite
include "calendar.tmpl"

const
  sql_now =
    when defined(postgres): "(extract(epoch from now()))"
    else:                   "(strftime('%s', 'now'))"

  sql_timestamp =
    when defined(postgres): "integer"
    else:                   "timestamp"

  sql_id =
    when defined(postgres): "integer generated by default as identity"
    else:                   "integer"

  sql_bool =
    when defined(postgres): "boolean"  # 0 / 1  |  true / false
    else:                   "integer"  # 0 / 1

  calendarTable = sql("""
    create table if not exists calendar(
      id           $3            primary key,
      title        varchar(25)   not null,
      description  varchar(300)  not null,
      color        varchar(9)    not null,
      email        varchar(254)  not null,
      web          varchar(300)  not null,
      location     varchar(300)  not null,
      maxPeople    integer       not null   default 2,
      eventDate    $2            not null   default $1,
      creation     $2            not null   default $1,
      isRemote     $4            not null   default 0,
      isFree       $4            not null   default 0,
      isMinorsOk   $4            not null   default 0,
      hasA11y      $4            not null   default 0,
      hasBikePark  $4            not null   default 0,
      hasCarPark   $4            not null   default 0,
      hasFood      $4            not null   default 0,
      hasDrink     $4            not null   default 0,
      hasBTC       $4            not null   default 0,
      needNotebook $4            not null   default 0,
      isWeatherOk  $4            not null   default 1,
      hasPower     $4            not null   default 1,
      hasWifi      $4            not null   default 1,
      hasAC        $4            not null   default 1,
      hasBathroom  $4            not null   default 1,
      hasSit       $4            not null   default 1
    );""".format(sql_now, sql_timestamp, sql_id, sql_bool))

proc calendarStart*(db: DbConn) =
  exec(db, calendarTable)
