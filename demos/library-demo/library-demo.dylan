module: dylan-viscera

write("Hello, World.\n");

define method fact (x :: <integer>) => res :: <integer>;
  for (i :: <integer> from x to 2 by -1,
       result :: <integer> = 1 then result * i)
  finally
    result;
  end;
end;

format("fact(5) = %=\n", fact(5));
format("fact(10) = %=\n", fact(10));
