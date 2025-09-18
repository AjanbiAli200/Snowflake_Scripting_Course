-- FIND GIVEN NUMBER IS ODD OR EVEN

SET N=12377;

EXECUTE IMMEDIATE
$$
BEGIN
    IF($N % 2 = 0) THEN
        RETURN 'N IS EVEN';
    ELSE
        RETURN 'N IS ODD';
    END IF;
END;
$$;


-- FIND THE PRIME NUMBERS UPTO GIVEN NUMBER

CREATE OR REPLACE PROCEDURE EMP.PROCS.SP_WHILE_PRIME_NUMBERS("N" INTEGER)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
DECLARE
    i INTEGER DEFAULT 3;
    j INTEGER;
    flag INTEGER;
    prime VARCHAR DEFAULT '2 ';

BEGIN
    WHILE(i <= N)
    DO
        flag := 0;
        for j in 2 to i-1
        do 
            if (i % j = 0) then
                flag := 1;
                -- break;
            end if;
        end for;
        if (flag = 0) then
            prime := prime || ', ' || i;
        end if;
        i := i+1;
    end while;

    return prime;
end;

call EMP.PROCS.SP_WHILE_PRIME_NUMBERS(100);


    