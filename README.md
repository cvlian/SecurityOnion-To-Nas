# SecurityOnion-To-Nas

Security Onion sciprts for saving pcap files in a NAS storage

## How to run?

To activate the packet collecting process, simply type in the shell prompt the following:

```
$ git clone https://github.com/cvlian/SecurityOnion-To-Nas/
$ cd SecurityOnion-To-Nas
$ sudo ./configure.sh --sensor-name=[sensor interface name] --nas-dir=[Synology NAS IP address]:[mount path of shared folder] --shared-dir=[mount point on NFS client]
```

```
Options:
    --sensor-name=<name>             Define specific sensor <name> to process
    --nas-dir=<name>                 Mount path of shared folder
    --shared-dir=<name>              Mount point on NFS client

    --help                           Same as -h
```
