module: t

define variable fubar = method() #() end;

define class <foo>(<object>)
  constant slot bar :: <list>, init-function: fubar;
end;
