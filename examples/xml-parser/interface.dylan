module: interface
author: Andreas Bogk, Chris Double
copyright: (c) 2001, LGPL
translated-into-its-own-module-by: Douglas M. Auclair

// --- CHRIS'S DEF'S --  with additions by Doug
// now modified to conform a bit to Andreas' XML-syntax fns

define class <xml> (<object>)
  constant slot name :: <symbol>, required-init-keyword: name:;
end class <xml>;

define class <node> (<xml>)
  constant slot node-children = #[], init-keyword: children:;    
end class <node>;

define class <attribute> (<xml>)
  constant slot attribute-value :: <string> = "", init-keyword: value:;
end class <attribute>;

define class <element> (<node>)
  constant slot element-attributes :: <vector> = #[], init-keyword: attributes:;
end class <element>;

define class <document> (<node>)
end class <document>;

define class <char-string> (<xml>)
  inherited slot name, init-value: #"chars";
  constant slot text :: <string>, required-init-keyword: text:;
end class <char-string>;

define class <entity-reference> (<xml>)
end class <entity-reference>;

define class <char-reference> (<xml>)
  constant slot char :: <character>, required-init-keyword: char:;
end class <char-reference>;

// and constants as classes
define constant <letter> = 
    one-of('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
           'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
           'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
           'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z');

define constant <digit> = 
    one-of('0', '1', '2', '3', '4', '5', '6', '7', '8', '9');

define constant <hex-digit> = 
    one-of('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'A',
           'b', 'B', 'c', 'C', 'd', 'D', 'e', 'E', 'f', 'F');

define constant <version-number> =
  type-union(<letter>, <digit>, one-of('_', '.', ':'));

