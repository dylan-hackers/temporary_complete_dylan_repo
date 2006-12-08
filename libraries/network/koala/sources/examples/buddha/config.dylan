module: buddha
author: Hannes Mehnert <hannes@mehnert.org>

define method overlaps (network :: <network>) => (res :: <list>)
  overlaps-aux(network, storage(<network>))
end;

define method overlaps (subnet :: <subnet>) => (res :: <list>)
  overlaps-aux(subnet, storage(<subnet>))
end;

define method overlaps-aux (network :: <network>, list :: <collection>)
 => (res :: <list>)
  //checks whether cidr is not used in network yet.
  //each network (network-address and broadcast address)
  //must be both greater than the network-address or
  //both smaller than broadcast-address
  let res = make(<list>);
  for (ele in list)
    let (bigger, smaller)
      = if (ele.cidr.cidr-netmask < network.cidr.cidr-netmask)
          values(ele, network)
        else
          values(network, ele)
        end;
    let same-sized = make(<cidr>,
                          network-address: smaller.cidr.cidr-network-address,
                          netmask: bigger.cidr.cidr-netmask);
    if (base-network-address(same-sized) = network-address(bigger.cidr))
      res := add!(res, ele);
    end;
  end;
  res;
end;

define method check-in-context (parent :: <object>, object :: <object>)
 => (res :: <boolean>)
  check(object);
end;

define method check-in-context (tzone :: <zone>, tcname :: <cname>)
 => (res :: <boolean>)
  if (any?(method(x) x.source = tcname.cname-source end, tzone.cnames))
    signal(make(<web-error>,
                error: "Same A record already exists"));
  elseif (any?(method(x) x.host-name = tcname.cname-source end, tzone.a-records))
    signal(make(<web-error>,
                error: "Same A record already exists"));
  elseif (any?(method(x) x.host-name = tcname.cname-source end,
               choose(method(y) y.zone = tzone end, storage(<host>))))
    signal(make(<web-error>,
                error: "Same A record already exists"));
  else
    #t;
  end;
end;

define method check-in-context (tzone :: <zone>, a-record :: <a-record>) 
 => (res :: <boolean>)
  if (any?(method(x) x.source = a-record.host-name end, tzone.cnames))
    signal(make(<web-error>,
                error: "Same A record already exists"));
  elseif (any?(method(x) x.host-name = a-record.host-name end, tzone.a-records))
    signal(make(<web-error>,
                error: "Same A record already exists"));
  elseif (any?(method(x) x.host-name = a-record.host-name end,
               choose(method(y) y.zone = tzone end, storage(<host>))))
    signal(make(<web-error>,
                error: "Same A record already exists"));
  else
    #t;
  end;
end;

define method check (zone :: <zone>, #key test-result = 0)
 => (res :: <boolean>)
  if (size(choose(method(x) x.zone-name = zone.zone-name end , storage(<zone>))) > test-result)
    signal(make(<web-error>,
                error: "Zone with same name already exists"));
  else
    if (zone.reverse?)
      zone.visible? := #f;
    end;
    #t;
  end;
end;

define method check (host :: <host>, #key test-result = 0)
 => (res :: <boolean>)
  if (size(choose(method(x) x.host-name = host.host-name end,
                  choose(method(x) x.zone = host.zone end, storage(<host>)))) > test-result)
    signal(make(<web-error>,
                error: "Host with same name already exists in zone"));
  elseif (size(choose(method(x) x.host-name = host.host-name end,
                      host.zone.a-records)) > 0)
    signal(make(<web-error>,
                error: "A record for host already exists in zone"));
  elseif (size(choose(method(x) x.cname-target = host.host-name end,
                      host.zone.cnames)) > 0)
    signal(make(<web-error>,
                error: "A record already exists in zone"));
  elseif (size(choose(method(x) x.ipv4-address = host.ipv4-address end,
                      choose(method(x) x.subnet = host.subnet end, storage(<host>)))) > test-result)
    signal(make(<web-error>,
                error: "Host with same IP address already exists in subnet"));
  elseif (host.subnet.dhcp?
            & size(choose(method(x) x.mac-address = host.mac-address end,
                            choose(method(x) x.subnet = host.subnet end,
                                     storage(<host>)))) > test-result)
    signal(make(<web-error>,
                error: "Host with same MAC address already exists in subnet"));
  elseif ((host.ipv4-address = network-address(host.subnet.cidr)) |
            (host.ipv4-address = broadcast-address(host.subnet.cidr)))
    signal(make(<web-error>,
                error: "Host can't have the network or broadcast address as IP"));
  elseif (~ ip-in-net?(host.subnet, host.ipv4-address))
    signal(make(<web-error>,
                error: "Host is not in specified network"))
  else
    #t;
  end;
end;

define method check (vlan :: <vlan>, #key test-result = 0)
 => (res :: <boolean>)
  let vlans = storage(<vlan>);
  if ((vlan.vlan-number < 0) | (vlan.vlan-number > 4095))
    signal(make(<web-error>,
                error: "VLAN not in range 0 - 4095"));
  elseif (size(choose(method(x) x.vlan-number = vlan.vlan-number end , vlans)) > test-result)
    signal(make(<web-error>,
                error: "VLAN with same number already exists"));
  elseif (size(choose(method(x) x.vlan-name = vlan.vlan-name end, vlans)) > test-result)
    signal(make(<web-error>,
                error: "VLAN with same name already exists"));
  else
    #t;
  end;
end;

define method check (network :: <network>, #key test-result = 0)
 => (res :: <boolean>)
  unless (network-address(network.cidr) = base-network-address(network.cidr))
    signal(make(<web-form-warning>,
                warning: "Network address is not the base network address, fixing this!"));
    network.cidr.cidr-network-address := base-network-address(network.cidr);
  end;
  if (every?(method(x) x = network end, overlaps(network)))
    if (get-query-value("reverse-dns?"))
      //add reverse delegated zones...
      add-reverse-zones(network);
    end;
    #t;
  else
    signal(make(<web-error>,
                error: "Network overlaps with another network"));
  end if;
end;

define method check (subnet :: <subnet>, #key test-result = 0)
 => (res :: <boolean>)
  unless (network-address(subnet.cidr) = base-network-address(subnet.cidr))
    signal(make(<web-form-warning>,
                warning: "Network address is not the base network address, fixing this!"));
    subnet.cidr.cidr-network-address := base-network-address(subnet.cidr);
  end;
  if (every?(method(x) x = subnet end, overlaps(subnet)))
    if (subnet-in-network?(subnet))
      if (subnet.dhcp-start > subnet.dhcp-end)
        signal(make(<web-error>,
                    error: "DHCP start greater than DHCP end"));
      elseif (subnet.dhcp-start = broadcast-address(subnet.cidr))
        signal(make(<web-error>,
                    error: "DHCP start can't be broadcast address"))
      elseif (subnet.dhcp-start = network-address(subnet.cidr))
        signal(make(<web-error>,
                    error: "DHCP start can't be network address"))
      elseif (subnet.dhcp-end = broadcast-address(subnet.cidr))
        signal(make(<web-error>,
                    error: "DHCP end can't be broadcast address"))
      elseif (subnet.dhcp-end = network-address(subnet.cidr))
        signal(make(<web-error>,
                    error: "DHCP end can't be network address"))
      elseif (subnet.dhcp-router = broadcast-address(subnet.cidr))
        signal(make(<web-error>,
                    error: "DHCP router can't be broadcast address"))
      elseif (subnet.dhcp-router = network-address(subnet.cidr))
        signal(make(<web-error>,
                    error: "DHCP router can't be network address"))
      end;
      if (ip-in-net?(subnet, subnet.dhcp-start))
        if (ip-in-net?(subnet, subnet.dhcp-end))
          if (ip-in-net?(subnet, subnet.dhcp-router))
            if ((subnet.dhcp-router > subnet.dhcp-start)
                  & (subnet.dhcp-router < subnet.dhcp-end))
              signal(make(<web-error>,
                          error: "Router has to be outside of dhcp-range"));
            else
              #t;
            end if;
          else
            signal(make(<web-error>,
                        error: "DHCP router not in subnet"));
          end
        else
          signal(make(<web-error>,
                      error: "DHCP end not in subnet"));
        end
      else
        signal(make(<web-error>,
                    error: "DHCP start not in subnet"));
      end
    else
      signal(make(<web-error>,
                  error: "Subnet not in a defined network"));
    end
  else
    signal(make(<web-error>,
                error: "Subnet overlaps with another subnet"));
  end if;
end;

define method print-isc-dhcpd-file (config :: <collection>, stream :: <stream>)
 => ()
  for (network in config)
    if (network.dhcp?)
      print-isc-dhcpd-file(network, stream);
    end;
  end;
end;

define method print-bind-zone-file
    (config :: <collection>, stream :: <stream>)
 => ()
  //we need to print named.conf file here
  for (zone in config)
    print-bind-zone-file(zone, stream)
  end;
end;

define method print-tinydns-zone-file
    (config :: <collection>, stream :: <stream>, #key reverse-table)
 => ()
  let reverse-table = make(<string-table>);
  for (zone in config)
    print-tinydns-zone-file(zone, stream, reverse-table: reverse-table)
  end;
end;
