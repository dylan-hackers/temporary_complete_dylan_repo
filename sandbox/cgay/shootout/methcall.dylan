module:     methcall
synopsis:   implementation of "Method Calls" benchmark
author:     Peter Hinely
copyright:  public domain


define sealed domain make (subclass(<toggle>));
define sealed domain initialize (<toggle>);


define class <toggle> (<object>)
  slot value :: <boolean>, required-init-keyword: start-state:;
end class;


define class <nth-toggle> (<toggle>)
  slot counter :: <integer> = 0;
  slot counter-maxiumum :: <integer>, required-init-keyword: counter-maxiumum:;
end class;


define inline method activate (t :: <toggle>) => t :: <toggle>;
  t.value := ~t.value;
  t;
end method;


define inline method activate (t :: <nth-toggle>) => t :: <nth-toggle>;
  t.counter := t.counter + 1;
  if (t.counter >= t.counter-maxiumum)
    t.value := ~t.value;
    t.counter := 0;
  end;
  t;
end method;


begin
  let arg = string-to-integer(element(application-arguments(), 0, default: "1"));

  let val = #t;
  let toggle = make(<toggle>, start-state: val);
    
  for (i from 1 to arg)
    val := toggle.activate.value;
  end;

  format-out("%s\n", if (val) "true" else "false" end);
     
  val := #t;
  let nth-toggle = make(<nth-toggle>, start-state: val, counter-maxiumum: 3);
  
  for (i from 1 to arg)
    val := nth-toggle.activate.value;
  end;

  format-out("%s\n", if (val) "true" else "false" end);
end