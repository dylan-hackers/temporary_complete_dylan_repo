module: tk

define class <listbox> (<window>, <editable>) end class;

define-widget(<listbox>, "listbox",
	      #"exportselection", #"font", #"geometry", #"selectbackground",
	      #"selectborderwidth", #"selectforeground", #"setgrid",
	      #"xscrollcommand", #"yscrollcommand");

define method current-selection(listbox :: <listbox>, #rest rest) =>
    (indices :: <sequence>);
  map(curry(tk-as, <integer>),
      parse-tk-list(call-tk-function(listbox.path, " curselection")));
end method;

define method nearest(listbox :: <listbox>, y-coord) => index :: <integer>;
  tk-as(<integer>, call-tk-function(listbox.path, " nearest ",
					tk-as(<string>, y-coord)));
end method nearest;

define method size(listbox :: <listbox>) => result :: <integer>;
  tk-as(<integer>, call-tk-function(listbox.path, " size"));
end method size;

define method xview(listbox :: <listbox>, index) => listbox :: <listbox>;
  put-tk-line(listbox.path, " xview ", tk-as(<string>, index));
  listbox;
end method xview;

define method yview(listbox :: <listbox>, index) => listbox :: <listbox>;
  put-tk-line(listbox.path, " yview ", tk-as(<string>, index));
  listbox;
end method yview;

define method get-elements
    (widget :: <listbox>, index, #key end: last) => (result :: <string>);
  let real-index = tk-as(<integer>, index);
  let real-end
    = if (last) tk-as(<integer>, last) else real-index + 1 end if;

  let buffer :: <stream> = make(<byte-string-output-stream>);
  for (i from real-index below real-end,
       newline = #f then #t)
    if (newline) write("\n", buffer) end if;
    write(tk-unquote(call-tk-function(widget, " get ", i)), buffer);
  end for;
  string-output-stream-string(buffer);
end method get-elements;
  
define method get-all (listbox :: <listbox>) => (result :: <string>);
  get-elements(listbox, 0, end: listbox.size);
end method get-all;

