Module:    dylan-user
Synopsis:  A brief description of the project.
Author:    Andreas Bogk, Hannes Mehnert
Copyright: (C) 2006,  All rights reserved.

define module network-flow
  use common-dylan;
  use threads;
  use format;
  use streams;
  use standard-io;
  use flow;
  use packetizer;
  use packet-filter;

  export <summary-printer>, <verbose-printer>,
    <decapsulator>, <demultiplexer>,
    create-output-for-filter,
    <frame-filter>,
    <pcap-file-reader>,
    <pcap-file-writer>,
    <fan-out>, <fan-in>;
end module network-flow;