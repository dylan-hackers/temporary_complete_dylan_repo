module: sniffer
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2005, 2006,  All rights reserved. Free for non-commercial use.

define argument-parser <sniffer-argument-parser> ()
  synopsis print-synopsis,
    usage: "sniffer [options]",
    description: "Capture and display packets from a network interface.";
  option verbose?, "Verbose output, print whole packet",
    short: "v", long: "verbose";
  option interface = "eth0", "Interface to listen on (defaults to eth0)",
    kind: <parameter-option-parser>, long: "interface", short: "i";
  option read-pcap, "Dump packets from given pcap file",
    kind: <parameter-option-parser>, long: "read-pcap", short: "r";
  option filter, "Filter, ~, |, &, and bracketed filters",
    kind: <parameter-option-parser>, long: "filter", short: "f";
end;

define function main()
  let parser = make(<sniffer-argument-parser>);
  unless(parse-arguments(parser, application-arguments()))
    print-synopsis(parser, *standard-output*);
    exit-application(0);
  end;
  let source-name = parser.read-pcap | parser.interface;
  let source = make(if (parser.read-pcap)
                      <pcap-file-reader>
                    else
                      <ethernet-interface>
                    end if, name: source-name);
  let printer = make(if (parser.verbose?)
                       <verbose-printer>
                     else
                       <summary-printer>
                     end,
                     stream: *standard-output*);

  if (parser.filter)
    let frame-filter = make(<frame-filter>, filter-expression: parser.filter);
    connect(source, frame-filter);
    connect(frame-filter, printer);
  else
    connect(source, printer);
  end;

  toplevel(source);
end;

main();
