/* finds the selected word in the texts of procedures and function */
CREATE PROCEDURE `findSQLObject`(str VARCHAR(255))
BEGIN
  SET str = concat('%', str, '%');

  SELECT ROUTINE_SCHEMA, ROUTINE_TYPE, DTD_IDENTIFIER, ROUTINE_NAME  FROM INFORMATION_SCHEMA.ROUTINES
  WHERE ROUTINE_DEFINITION LIKE str;
END


/* formats a string to a date */
CREATE FUNCTION `formatDate`(Dt varchar(20)) RETURNS varchar(20)
BEGIN
  declare D varchar(20) default '';
  declare ln int default char_length(ifnull(Dt,''));
  declare curYear int default YEAR(CURDATE());
  declare n int default 1;
  declare m varchar(1) default '';
  declare flag_digit boolean default false;

  if ln = 0 then
    return '';
  end if;

  while n <= ln do
    set m = mid(Dt, n, 1);
      if m between '0' and '9' then
      set D = concat(D, m),
              flag_digit=true;
    elseif flag_digit then
        set D = concat(D,'-'),
              flag_digit=false;
    end if;
      set n = n + 1;
  end while;

  set Dt=trim(TRAILING '-' FROM D),
      ln=length(Dt);

  if Dt rlike '^[0-9]+$' then
      if Dt>curYear and Dt<44000 then
          set D=DATE_ADD('1900-01-01', INTERVAL Dt-2 DAY);
      else
          set D='';
      end if;
  elseif ln=10 and Dt rlike '^[0-9]{2}.[0-9]{2}.[0-9]{4}' then
    set D=concat_ws('-',mid(Dt,7,4),mid(Dt,4,2),left(Dt,2));
  elseif ln=8  and Dt rlike '^[0-9]{1}.[0-9]{1}.[0-9]{4}' then
    set D=concat(mid(Dt,5,4),'-0',mid(Dt,3,1),'-0',left(Dt,1));
  elseif ln=9  and Dt rlike '^[0-9]{2}.[0-9]{1}.[0-9]{4}' then
    set D=concat(mid(Dt,6,4),'-0',mid(Dt,4,1),'-',left(Dt,2));
  elseif ln=9  and Dt rlike '^[0-9]{1}.[0-9]{2}.[0-9]{4}' then
    set D=concat(mid(Dt,6,4),'-',mid(Dt,3,2),'-0',left(Dt,1));
  elseif ln=8  and Dt rlike '^[0-9]{2}.[0-9]{2}.[0-9]{2}' then
    set D=right(Dt,2);
      if D>curYear-2000 then
      set D=concat('19',D,'-',mid(Dt,4,2),'-',left(Dt,2));
    else
      set D=concat('20',D,'-',mid(Dt,4,2),'-',left(Dt,2));
    end if;
  else
      set D = Dt;
  end if;

  if mid(D, 6, 2)>12 and right(D,2)<=12 then
      set D = concat(left(D, 4), right(D,3), mid(D, 5, 3));
  end if;

  RETURN D;
END


/* splits a string into substrings by separator-selects a substring with the specified index */
CREATE FUNCTION `splitStr`(strVal TEXT, nom INT, delimetr varchar(10)) RETURNS varchar(255)
BEGIN
  RETURN SUBSTRING_INDEX(SUBSTRING_INDEX(concat(strVal,delimetr), delimetr,  nom), delimetr,  -1);
END


/* truncates the string and adds three dots at the end */
CREATE FUNCTION `trim3dots`(str VARCHAR(10240), len INT) RETURNS varchar(2048)
BEGIN
  DECLARE num INT DEFAULT char_length(str);

  IF num > len THEN
      SET num = len - (len DIV 10),
          num = LEAST( locate(' ',str,num)-1, len);
  END IF;

  RETURN concat(
          left(str, num),
          if(char_length(str) > num, '...', '')
      );
END

/* selects unique values from the list */
CREATE FUNCTION `uniqueValueList`(str VARCHAR(2048), sep VARCHAR(10)) RETURNS varchar(2048)
BEGIN
  DECLARE nom INT DEFAULT 1;
  DECLARE s VARCHAR(255) DEFAULT '';
  DECLARE res VARCHAR(2048) DEFAULT '';

  if sep = '' then
      set sep=',';
  end if;

  set str=replace(str, sep, '~');

  DROP TEMPORARY TABLE IF EXISTS U;
  CREATE TEMPORARY TABLE U (
    val VARCHAR(255), 
    UNIQUE INDEX(val)
  ) ENGINE=MEMORY;

  set s=trim(splitStr(str, 1, '~'));
  labS: while s<>'' do
    insert ignore into U values (s);
    set nom=nom+1, 
        s=trim(splitStr(str, nom, '~'));
  end while labS;

  SELECT GROUP_CONCAT(val SEPARATOR '~') INTO res
  FROM U
  ORDER BY val;

  set res=replace(res, '~', sep);

  DROP TEMPORARY TABLE U;

  RETURN res;
END


/* removes double space characters from the string */
CREATE FUNCTION `trimStr`(str VARCHAR(10240)) RETURNS varchar(10240)
BEGIN
  # for MySQL 5...
  # return trim(replace(replace(replace(replace(replace(replace(str,'\t',' '), char(13), ' '), char(10), ' '),'   ',' '),'  ',' '),'  ',' '));
  
  # for MySQL 8.0
  RETURN trim(REGEXP_REPLACE(str,'[:space:]{2,}', ' '));
END
