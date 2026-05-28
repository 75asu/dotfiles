# Running a Laptop as a Headless Server

Notes from setting up a Lenovo IdeaPad 110 (i3-6006U, Ubuntu Server) as a
permanent homelab server. These configs are hardware and distro dependent - verify
before applying blindly on a different machine.

---

## 1. Prevent sleep on lid close

Edit `/etc/systemd/logind.conf`:

```ini
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
IdleAction=ignore
```

- `HandleLidSwitch` - covers lid close when on battery
- `HandleLidSwitchExternalPower` - covers lid close when plugged in (most important)
- `IdleAction` - prevents idle timeout from triggering sleep

Apply without reboot:
```bash
sudo systemctl restart systemd-logind
```

---

## 2. Mask sleep, suspend, hibernate targets

This is the hard lock. Even if something tries to trigger sleep, it cannot.

```bash
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
```

Verify:
```bash
systemctl is-enabled sleep.target suspend.target hibernate.target
# should print: masked masked masked
```

---

## 3. Enable Intel Virtualization (VT-x / KVM)

This requires a physical BIOS change - cannot be done from the OS.

1. Reboot, spam **F2** during POST to enter BIOS (Fn+F2 on 60% keyboards)
2. Navigate to Security or Configuration tab
3. Enable **Intel Virtualization Technology**
4. F10 to save and exit

After reboot, load KVM modules and make them persistent:
```bash
sudo modprobe kvm
sudo modprobe kvm_intel          # Intel CPUs
# sudo modprobe kvm_amd          # AMD CPUs

echo -e "kvm\nkvm_intel" | sudo tee /etc/modules-load.d/kvm.conf

ls -la /dev/kvm                  # should exist
```

---

## 4. Verify the machine is on AC power

Always confirm the laptop is plugged in before leaving it unattended:

```bash
cat /sys/class/power_supply/ADP0/online   # 1 = plugged in
cat /sys/class/power_supply/BAT0/status   # Not charging = full, healthy
cat /sys/class/power_supply/BAT0/capacity # percentage
```

Note: "Not charging" at 95%+ is normal and intentional on most laptops
(battery conservation). It does not mean the machine is on battery.

---

## 5. Verify SATA / disk health

If the machine shows ATA bus errors (`failed command: WRITE DMA`, `PHYRdyChg`),
it's a physical SATA cable connection issue, not a drive failure. Check SMART:

```bash
sudo smartctl -H /dev/sda        # should say PASSED
sudo smartctl -A /dev/sda | grep -E 'Reallocated|Pending|Uncorrectable'
# all should be 0
```

ATA bus errors with a healthy SMART = reseat the SATA cable at both ends
(drive side and motherboard side). Common after months of storage.

---

## 6. Full verification checklist

Run these after any reboot to confirm everything is healthy:

```bash
# Lid / sleep config
grep -E 'HandleLid|IdleAction' /etc/systemd/logind.conf
systemctl is-enabled sleep.target suspend.target hibernate.target

# KVM
ls /dev/kvm
lsmod | grep kvm

# AC power
cat /sys/class/power_supply/ADP0/online

# k3s (if running)
sudo systemctl is-active k3s
sudo kubectl get pods -A | grep -v Running
```

---

## How real companies (Hetzner, Railway) do this

For context - this is how bare metal at scale actually works, vs what we're doing.

**What a real server has that a laptop doesn't:**

| Feature | Laptop homelab | Real server |
|---------|---------------|-------------|
| Remote power control | No (need physical access) | IPMI / iDRAC / iLO - full remote control even if OS is down |
| Remote BIOS access | No | IPMI console - change BIOS settings over network |
| Remote KVM (keyboard/video/mouse) | No | IPMI SOL (Serial over LAN) or HTML5 KVM |
| No lid, no battery | Workarounds needed | Not a concern |
| ECC RAM | No | Yes - bit flip protection |
| Redundant PSU | No | Usually dual PSU |
| Drive hot-swap | No | Yes on rack servers |

**Hetzner's provisioning flow (bare metal):**

1. Server ordered via API or robot.hetzner.com
2. Hetzner boots a rescue system via PXE (network boot - no USB/DVD)
3. You SSH into the rescue system and run `installimage` - their CLI installer
4. Installer partitions disk, installs Ubuntu/Debian, writes config
5. Reboot - server comes up with clean OS
6. From here: Ansible, cloud-init, or a custom provisioner takes over
7. No human physically touches the machine after racking

**Railway's approach (from public talks):**

Railway uses Hetzner bare metal + their own orchestration layer. They provision
machines via the Hetzner API, configure networking (BGP, anycast), and deploy
their own scheduler on top. Their scheduler (written in Go) handles container
placement, networking, and isolation - similar to what Kiln is building.

Key difference vs cloud VMs: bare metal has no hypervisor overhead, full CPU
performance, full access to hardware features like SR-IOV networking and KVM.

**The IPMI pattern (what replaces everything we did manually):**

On a real server, none of the lid/sleep config matters. Instead:
- `ipmitool power on/off/reset` from anywhere
- `ipmitool sol activate` for serial console (like SSH but at hardware level)
- BIOS settings changed via IPMI without physical access
- If the OS panics, IPMI console shows what happened before crash

This is why SRE roles ask about IPMI, iDRAC, iLO - it's the fundamental tool
for managing physical servers remotely. Understanding this gap between a laptop
homelab and real datacenter hardware is useful context for those interviews.
