tpl-c900-openwrt-install
========================

This repository details how to install OpenWrt on a TP-Link Archer C900 (US). I've been through these steps and though it's worked for me, it might not work for everyone. My C900 is currently fully functional on OpenWrt.

### Disclaimer
I'm not responsible for turning your router into a toaster. You're following these instructions of your own accord. These instructions are not for the faint of heart -- they are geared towards guiding fairly technical users. If you don't understand what you're doing when you run these commands or tools, you probably shouldn't be attempting this.

### Prerequisites
This guide assumes you're running Linux and that you have a Go installation. Having a copy of fish shell is recommended, but not required -- you can call the go tool yourself.

### Background
On relatively recent devices (including the Archer C900) TP-Link seems to have implemented some kind of firmware verification scheme that prevents the installation of third-party firmware. Curiously, The Archer C2 v3, the EU region equivalent of the C900, seems to have no such protection, even though the two devices are practically identical in terms of hardware.

This approach to installing OpenWrt doesn't involve attacking the firmware verification scheme head-on.  Instead, it relies on gaining shell access to the device. While there is a dropbear server running on port 22 by default, it seems to have been modified to disable PTY and exec channels, i.e. to disallow running any commands. TP-Link seem to be using the server as an authentication mechanism for the API behind their mobile app, which SSH forwards into a service listening on the router's localhost.

### Approach
Fortunately, it's possible to configure the dropbear server to again allow the execution of commands. This functionality is unfortunately not exposed through the web interface or mobile app, because that would be _too_ easy. Instead, one has to modify the encrypted backup file. The keys for said backup file are hardcoded into the device firmware. The backup file itself is a tar file, compressed with Zlib and encrypted in AES-256-CBC mode (in that order.) Inside the tar file, the configuration is compressed and encrypted in the same manner and stored in `ori-backup-user-config.bin`. The configuration file itself is XML which might be a straight dump from UCI (TP-Link bases their firmware off OpenWrt 12.09.) TP-Link configures dropbear from UCI variables as well, so the goal would be to download a backup, unpack it, modify dropbear config keys, repack, then restore the backup via the webui.

### Instructions
This repository contains all the necessary tools to unpack and repack the configuration file. Additionally, there's a sample modified backup file to get you started. You should still generate your own as fun stuff like MAC address and network configuration is also restored with the backup file.

##### Prelude
Before even extracting the files, we need to extract the backup encryption keys from the stock firmware.
1. [Download the firmware from TP-Link's support site.](https://static.tp-link.com/ArcherC900%28US%29_V1_161130.zip)
2. Extract the rootfs from the firmware image. At the current revision (V1_161130) it's offset by 1105537 bytes. You can run something like this to extract it:
`dd if=stock.bin of=stock.squashfs bs=1 skip=1105537`.
3. Decompress the rootfs, like so:
`unsquashfs stock.squashfs`.
This should decompress the filesystem into `./squashfs-root`.
4. Extract the encryption keys from the Lua bytecode. Going off the previous steps:
`strings squashfs-root/usr/lib/lua/luci/model/crypto.lua`. This should output a sizeable list of strings. What you're looking for is two hexadecimal strings. One of them (the key) should be significantly longer than any other string in the list. The other one (IV) is right after the key.
5. Copy `.encryption_params.sample` into `encryption_params`. Paste the key and the IV you found into the appropriate places.

##### Modification
You should download the backup file from the router (the page to do so should be in System Tools -> Backup and Restore). These instructions will assume that you have the backup in this directory that the tools are in with a name of `backup.bin`.
1. Run `extract.fish`. If you don't have fish shell, take a look at the script to see how to follow the steps manually, it's pretty self-explanatory.
2. The decrypted config file should now be `data/config.xml`. There should be a section in the file that looks something like this:
```xml
<dropbear name="dropbear">
<RootPasswordAuth>on</RootPasswordAuth>
<SysAccountLogin>off</SysAccountLogin>
<Port>22</Port>
<PasswordAuth>on</PasswordAuth>
</dropbear>
```
3. Modify the dropbear section. Somewhere between the opening and closing tags, add the RemoteSSH tag: `<RemoteSSH>on</RemoteSSH>`. Admire your handiwork and save the file.
4. Run `package.fish`. You should how have a `backup_final.bin` file.
5. Restore the router using `backup_final.bin`, on the same page that you used to download the backup. Needless to say, don't turn off your router. It should reboot normally.

##### Flashing
At this point, your router should be online again after the restore reboot. If nothing went wrong, you should be able to `ssh` directly into the router as root with the password you set for the webui.
1. `ssh` into your router if you haven't already:
`ssh root@<router_ip>`. Verify that you're able to get to a prompt. If not, something went wrong along the way.
2. Download [the latest snapshot sysupgrade image](https://downloads.openwrt.org/snapshots/targets/ath79/generic/). The file should be named `openwrt-ath79-generic-tplink_archer-c2-v3-squashfs-sysupgrade.bin`. You can alternatively use any custom sysupgrade image, just make sure it's compatible with the Archer C2 v3. **Please make sure that it's a sysupgrade image**, otherwise you will brick your router while attempting the following steps.
3. Check the checksum of the file against the one posted on the download site.
4. In another terminal, upload the sysupgrade image to your router: `scp openwrt-ath79-generic-tplink_archer-c2-v3-squashfs-sysupgrade.bin root@<router_ip>:/tmp/`. The image is now uploaded to /tmp/, in RAM.
5. Going back the router shell, run `cat /proc/mtd`. Your output should be similar to this:
```
dev:    size   erasesize  name
mtd0: 00020000 00010000 "factory-uboot"
mtd1: 00010000 00010000 "u-boot"
mtd2: 00100000 00010000 "kernel"
mtd3: 006a0000 00010000 "rootfs"
mtd4: 00010000 00010000 "ART"
```
If your partition layout is any different, **do not continue**.
6. Flash the image with `mtd write /tmp/openwrt-ath79-generic-tplink_archer-c2-v3-squashfs-sysupgrade.bin mtd2:mtd3`. **Verify that mtd2 and mtd3 correspond with kernel and rootfs, respectively**. This overwrites the stock kernel and rootfs with the OpenWrt image. OpenWrt's partitioning is different than stock, but that doesn't really matter -- there really isn't a partition table on this specific device, it's hardcoded into the kernel. As far as I understand it, as long as the offset that u-boot boots from is the same, the new kernel will boot and understand the partition layout and everyone will be happy.
7. Once the `mtd` command finishes, type `reboot` to reboot the router.
8. Profit! The router should now be running OpenWrt. Be patient, first boot takes a while. If something went wrong while flashing, you can attempt TFTP recovery (the U-Boot partition shouldn't have been touched.) Remember that you've flashed a snapshot image, so you'll have to install LuCi manually.

Happy hacking!
