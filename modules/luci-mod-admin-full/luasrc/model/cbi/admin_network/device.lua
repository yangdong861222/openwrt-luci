local ut = require "luci.util"

m = Map('network', _('Device'))

local sid = arg[1]
local isNew = arg[2]

s = m:section(NamedSection, sid, 'device')
s.anonymous = true
s.addremove   = false

s:tab('devgeneral', _('General device options'))
s:tab('devadvanced', _('Advanced device options'))
s:tab('brport', _('Bridge port specific options'))
s:tab('bridgevlan', _('Bridge VLAN filtering'))

o = s:taboption('devgeneral', ListValue, 'type', _('Device type'))
o:value('', _('Network device'))
o:value('bridge', _('Bridge device'))
o:value('8021q', _('VLAN (802.1q)'))
o:value('8021ad', _('VLAN (802.1ad)'))
o:value('macvlan', _('MAC VLAN'))
o:value('veth', _('Virtual Ethernet'))

-- To Do
o = s:taboption('devgeneral', Value, 'name_simple', _('Existing device'))
o.readonly = isNew
o.rmempty = false
o.cfgvalue = function(self, s)
    return m:get(s, 'name')
end
o.write = function(self, s, val)
    return m:set(s, 'name', val)
end
o:depends('type', '')

-- To Do
ifname_single = s:taboption('devgeneral', Value, 'ifname_single', _('Base device'))
ifname_single.template = 'cbi/network_ifacelist'
ifname_single.widget = 'radio'
ifname_single.nobridges = true
ifname_single.rmempty = false
ifname_single.network = arg[1]
ifname_single.uciType = 'device'
ifname_single:depends('type', '8021q')
ifname_single:depends('type', '8021ad')
ifname_single:depends('type', 'macvlan')

function ifname_single.cfgvalue(self, s)
    -- let the template figure out the related ifaces through the network model
    return nil
end

function ifname_single.write(self, s, val)
    ut.exec('uci delete network.' .. s .. '.ports')
    for i in ut.imatch(val) do
        ut.exec('uci add_list network.' .. s .. '.ports="' .. i .. '"')
    end
    ut.exec('uci commit network')
    return
end

-- To Do
o = s:taboption('devgeneral', Value, 'vid', _('VLAN ID'))
o:depends('type', '8021q')
o:depends('type', '8021ad')

-- To Do
o = s:taboption('devgeneral', Value, 'mode', _('Mode'))
o:value('vepa', _('VEPA (Virtual Ethernet Port Aggregator)', 'MACVLAN mode'))
o:value('private', _('Private (Prevent communication between MAC VLANs)', 'MACVLAN mode'))
o:value('bridge', _('Bridge (Support direct communication between MAC VLANs)', 'MACVLAN mode'))
o:value('passthru', _('Pass-through (Mirror physical device to single MAC VLAN)', 'MACVLAN mode'))
o:depends('type', 'macvlan')

-- To Do
o = s:taboption('devgeneral', Value, 'name_complex', _('Device name'))
o.rmempty = false
o.datatype = 'maxlength(15)'
o.readonly = isNew
o.cfgvalue = function(self, s)
    return m:get(s, 'name')
end
o.write = function(self, s, val)
    return m:set(s, 'name', val)
end
o:depends({ type = '', ['!reverse'] = true })

-- To Do
o = s:taboption('devadvanced', Value, 'ingress_qos_mapping', _('Ingress QoS mapping'), _('Defines a mapping of VLAN header priority to the Linux internal packet priority on incoming frames'))
o.rmempty = true
o:depends('type', '8021q')
o:depends('type', '8021ad')

-- To Do
o = s:taboption('devadvanced', Value, 'egress_qos_mapping', _('Egress QoS mapping'), _('Defines a mapping of Linux internal packet priority to VLAN header priority but for outgoing frames'))
o.rmempty = true
o:depends('type', '8021q')
o:depends('type', '8021ad')

-- To Do
ifname_multi = s:taboption('devgeneral', Value, 'ifname_multi', _('Bridge ports'))
ifname_multi.template = 'cbi/network_ifacelist'
ifname_multi.widget = 'checkbox'
ifname_multi.nobridges = true
ifname_multi.rmempty = false
ifname_multi.network = arg[1]
ifname_multi.uciType = 'device'
ifname_multi:depends('type', 'bridge')
ifname_multi.cfgvalue = ifname_single.cfgvalue
ifname_multi.write = ifname_single.write

o = s:taboption('devgeneral', Flag, 'bridge_empty', _('Bring up empty bridge'), _('Bring up the bridge interface even if no ports are attached'))
o.default = o.disabled
o:depends('type', 'bridge')

-- To Do
o = s:taboption('devadvanced', Value, 'priority', _('Priority'))
o.placeholder = '32767'
o.datatype = 'range(0, 65535)'
o:depends('type', 'bridge')

o = s:taboption('devadvanced', Value, 'ageing_time', _('Ageing time'), _('Timeout in seconds for learned MAC addresses in the forwarding database'))
o.placeholder = '30'
o.datatype = 'uinteger'
o:depends('type', 'bridge')

o = s:taboption('devadvanced', Flag, 'stp', _('Enable <abbr title="Spanning Tree Protocol">STP</abbr>'), _('Enables the Spanning Tree Protocol on this bridge'))
o.default = o.disabled
o:depends('type', 'bridge')

-- To Do
o = s:taboption('devadvanced', Value, 'hello_time', _('Hello interval'), _('Interval in seconds for STP hello packets'))
o.placeholder = '2'
o.datatype = 'range(1, 10)'
o:depends({ type = 'bridge', stp = '1'})

-- To Do
o = s:taboption('devadvanced', Value, 'forward_delay', _('Forward delay'), _('Time in seconds to spend in listening and learning states'))
o.placeholder = '15'
o.datatype = 'range(2, 30)'
o:depends({ type = 'bridge', stp = '1'})

-- To Do
o = s:taboption('devadvanced', Value, 'max_age', _('Maximum age'), _('Timeout in seconds until topology updates on link loss'))
o.placeholder = '20'
o.datatype = 'range(6, 40)'
o:depends({ type = 'bridge', stp = '1'})

o = s:taboption('devadvanced', Flag, 'igmp_snooping', _('Enable <abbr title="Internet Group Management Protocol">IGMP</abbr> snooping'), _('Enables IGMP snooping on this bridge'))
o.default = o.disabled
o:depends('type', 'bridge')

o = s:taboption('devadvanced', Value, 'hash_max', _('Maximum snooping table size'))
o.placeholder = '512'
o.datatype = 'uinteger'
o:depends({ type = 'bridge', igmp_snooping = '1'})

-- To Do
o = s:taboption('devadvanced', Flag, 'multicast_querier', _('Enable multicast querier'))
o:depends('type', 'bridge')

-- To Do
o = s:taboption('devadvanced', Value, 'robustness', _('Robustness'), _('The robustness value allows tuning for the expected packet loss on the network. If a network is expected to be lossy, the robustness value may be increased. IGMP is robust to (Robustness-1) packet losses'))
o.placeholder = '2'
o.datatype = 'min(1)'
o:depends({ type = 'bridge', multicast_querier = '1'})

o = s:taboption('devadvanced', Value, 'query_interval', _('Query interval'), _('Interval in centiseconds between multicast general queries. By varying the value, an administrator may tune the number of IGMP messages on the subnet; larger values cause IGMP Queries to be sent less often'))
o.placeholder = '12500'
o.datatype = 'uinteger'
o:depends({ type = 'bridge', multicast_querier = '1'})

-- To Do
o = s:taboption('devadvanced', Value, 'query_response_interval', _('Query response interval'), _('The max response time in centiseconds inserted into the periodic general queries. By varying the value, an administrator may tune the burstiness of IGMP messages on the subnet; larger values make the traffic less bursty, as host responses are spread out over a larger interval'))
o.placeholder = '1000'
o.datatype = 'uinteger'
o:depends({ type = 'bridge', multicast_querier = '1'})

o = s:taboption('devadvanced', Value, 'last_member_interval', _('Last member interval'), _('The max response time in centiseconds inserted into group-specific queries sent in response to leave group messages. It is also the amount of time between group-specific query messages. This value may be tuned to modify the "leave latency" of the network. A reduced value results in reduced time to detect the loss of the last member of a group'))
o.placeholder = '100'
o.datatype = 'uinteger'
o:depends({ type = 'bridge', multicast_querier = '1'})

o = s:taboption('devgeneral', Value, 'mtu', _('MTU'))
o:depends('type', '')
o:depends('type', 'bridge')

o = s:taboption('devgeneral', Value, 'macaddr', _('MAC address'))
o.datatype = 'macaddr'
o:depends('type', '')
o:depends('type', 'bridge')
o:depends('type', 'macvlan')
o:depends('type', 'veth')

-- To Do
o = s:taboption('devgeneral', Value, 'peer_name', _('Peer device name'))
o.rmempty = true
o.datatype = 'macaddr'
o:depends('type', 'veth')

o = s:taboption('devgeneral', Value, 'peer_macaddr', _('Peer MAC address'))
o.rmempty = true
o.datatype = 'macaddr'
o:depends('type', 'veth')

o = s:taboption('devgeneral', Value, 'txqueuelen', _('TX queue length'))
o.placeholder = ''
o.datatype = 'uinteger'
o:depends('type', '')

o = s:taboption('devadvanced', Flag, 'promisc', _('Enable promiscuous mode'))
o.default = o.disabled
o:depends('type', '')

-- To Do
o = s:taboption('devadvanced', ListValue, 'rpfilter', _('Reverse path filter'))
o.default = ''
o:value('', _('disabled'))
o:value('loose', _('Loose filtering'))
o:value('strict', _('Strict filtering'))
o:depends('type', '')

o = s:taboption('devadvanced', Flag, 'acceptlocal', _('Accept local'), _('Accept packets with local source addresses'))
o.default = o.disabled
o:depends('type', '')

o = s:taboption('devadvanced', Flag, 'sendredirects', _('Send ICMP redirects'))
o.default = o.enabled
o:depends('type', '')

o = s:taboption('devadvanced', Value, 'neighreachabletime', _('Neighbour cache validity'), _('Time in milliseconds'))
o.placeholder = '30000'
o.datatype = 'uinteger'
o:depends('type', '')

o = s:taboption('devadvanced', Value, 'neighgcstaletime', _('Stale neighbour cache timeout'), _('Timeout in seconds'))
o.placeholder = '60'
o.datatype = 'uinteger'
o:depends('type', '')

o = s:taboption('devadvanced', Value, 'neighlocktime', _('Minimum ARP validity time'), _('Minimum required time in seconds before an ARP entry may be replaced. Prevents ARP cache thrashing.'))
o.placeholder = '0'
o.datatype = 'uinteger'
o:depends('type', '')

o = s:taboption('devgeneral', Flag, 'ipv6', _('Enable IPv6'))
o.default = o.enabled
o:depends('type', '')

o = s:taboption('devgeneral', Value, 'mtu6', _('IPv6 MTU'))
o:depends({ ipv6 = '1', type = '' })

o = s:taboption('devgeneral', Value, 'dadtransmits', _('DAD transmits'), _('Amount of Duplicate Address Detection probes to send'))
o.placeholder = '1'
o.datatype = 'uinteger'
o:depends({ ipv6 = '1', type = '' })

o = s:taboption('devadvanced', Flag, 'multicast', _('Enable multicast support'))
o.default = o.enabled
o:depends('type', '')

o = s:taboption('devadvanced', ListValue, 'igmpversion', _('Force IGMP version'))
o:value('', _('No enforcement'))
o:value('1', _('Enforce IGMPv1'))
o:value('2', _('Enforce IGMPv2'))
o:value('3', _('Enforce IGMPv3'))
o:depends({ multicast = '1', type = '' })

o = s:taboption('devadvanced', ListValue, 'mldversion', _('Force MLD version'))
o:value('', _('No enforcement'))
o:value('1', _('Enforce MLD version 1'))
o:value('2', _('Enforce MLD version 2'))
o:depends({ multicast = '1', type = '' })

o = s:taboption('bridgevlan', Flag, 'vlan_filtering', _('Enable VLAN filterering'))
o:depends('type', 'bridge')

return m
