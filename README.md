Installing OVN from source
=========================

* Clone the OVS repo.

* Compile:

```
./boot.sh
./configure --prefix=/usr --localstatedir=/var  --sysconfdir=/etc --enable-ssl --with-linux=/lib/modules/`uname -r`/build
make -j3
make install
```

* Insert kernel modules 

```
rmmod openvswitch
modprobe libcrc32c
modprobe nf_conntrack_ipv6
modprobe nf_nat_ipv6
modprobe gre
insmod ./datapath/linux/openvswitch.ko
insmod ./datapath/linux/vport-geneve.ko
```

* Copy a startup script

```
cp debian/openvswitch-switch.init /etc/init.d/openvswitch-switch
```

* Start Open vSwitch

```
/etc/init.d/openvswitch-switch start
```

* Start OVN central components

```
/usr/share/openvswitch/scripts/ovn-ctl restart_northd
```

Open up TCP ports.

```
ovn-nbctl set-connection ptcp:6641
ovn-sbctl set-connection ptcp:6642
```

* One time setup on each host
On each host, where you plan to spawn your containers, you will need to
run the following command once.  (You need to run it again if your OVS database
gets cleared.  It is harmless to run it again in any case.)

$LOCAL_IP in the below command is the IP address via which other hosts
can reach this host.  This acts as your local tunnel endpoint.

$ENCAP_TYPE is the type of tunnel that you would like to use for overlay
networking.  The options are "geneve" or "stt".  (Please note that your
kernel should have support for your chosen $ENCAP_TYPE.  Both geneve
and stt are part of the Open vSwitch kernel module that is compiled from this
repo.  If you use the Open vSwitch kernel module from upstream Linux,
you will need a minumum kernel version of 3.18 for geneve.  There is no stt
support in upstream Linux.  You can verify whether you have the support in your
kernel by doing a "lsmod | grep $ENCAP_TYPE".)

```
ovs-vsctl set Open_vSwitch . external_ids:ovn-remote="tcp:$CENTRAL_IP:6642" \
  external_ids:ovn-encap-ip=$LOCAL_IP external_ids:ovn-encap-type="$ENCAP_TYPE"
```

And finally, start the ovn-controller.  (You need to run the below command
on every boot)

```
/usr/share/openvswitch/scripts/ovn-ctl start_controller
```

Creating a simple topology with OVN using namespaces.
====================================================

* Create logical switches "foo" and "bar"

```
ovn-nbctl ls-add foo
ovn-nbctl ls-add bar
```

* Create a router "router"

```
sh ovn-router.sh create-router router
```

* Connect switch "foo" to "router". The router port gets an ip address of
192.168.100.1/24

```
sh ovn-router.sh connect-switch router foo 192.168.100.1/24
```

* Connect switch "bar" to "router. The router port gets an ip address of
192.168.200.1/24

```
sh ovn-router.sh connect-switch router bar 192.168.200.1/24
```

* Create a namespace "foo1" and attach it as a logical port "foo1".
You need to run this command on the machine you plan to spawn your namespace.
If that machine is different than the machine where your northbound database
runs, then you need to provide the --db option. e..g --db=tcp:10.33.75.67:6640

```
sh ovn-port.sh add-port foo foo1 192.168.100.2/24 192.168.100.1
```

* Create a namespace "bar1" and attach it as a logical port "bar1"

```
sh ovn-port.sh  add-port --db=tcp:$IP:6640 bar bar1 192.168.200.2/24 192.168.200.1
```

* Test your pings

```
ip netns exec foo1 ping 192.168.200.2
```
