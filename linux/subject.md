## Overview

Linux is the most widely used kernel, the core of an operating system. It runs in data centers, phones, gaming consoles, cars, planes, submarines, and space stations. Operating systems built on it are called **"Linux distributions."**

This project is the foundation of the Sysadmin branch. You will build a Debian server to a written specification and prove that the server meets it.

Anyone can click through an installer. A system administrator makes deliberate choices, understands every one of them, and can hand someone a document that rebuilds the machine exactly.

The next five projects all build on the server you produce here.

> **Tux mascot**
>
> "But this wasn't to be just any penguin. Above all, Linus wanted one that looked happy, as if it had just polished off a pitcher of beer and then had the best sex of its life."
>
> *Just for Fun: The Story of an Accidental Revolutionary* — Linus Torvalds, David Diamond

---

## Role Play

You have just been handed your first server.

Your team lead does not want a screenshot of a finished installer. They want a machine that is:

* partitioned sensibly
* runs only what it needs
* comes with a runbook

So that when it dies at 3 a.m. someone else can rebuild it.

Today you are the sysadmin who builds that machine and writes the document that makes it survivable.

---

## Learning Objectives

By the end of this project you will be able to:

* Install a minimal Debian server without a desktop environment.
* Design a disk layout using LVM.
* Extend a logical volume on a running system without data loss.
* Set hostname, locale, and timezone.
* Configure static networking from the command line.
* Write a systemd service unit that:

  * starts on boot
  * restarts on failure
  * logs to the journal
* Analyze the boot sequence with `systemd-analyze` and `journalctl`.
* Document your work as a runbook precise enough for another person to reproduce.

You will also practice the soft skill at the center of system administration:

> Writing documentation that someone else can act on without asking you a single question.

---

# Instructions

Install Debian in a virtual machine using the hypervisor of your choice:

* VirtualBox on x86-64
* UTM on Apple Silicon

---

# Installation

Install Debian **without a desktop environment**.

Select the **minimal package set only**.

Set the following during installation:

* Hostname
* Locale
* Timezone

---

# Storage

Partition the disk using **LVM (Logical Volume Manager)**.

Create separate logical volumes for:

* `/`
* `/home`
* `/var`
* `swap`

## Volume Size Justification

In your `README.md`, justify the size you gave each volume.

A justification explains **what would happen if that volume filled up**.

> Repeating the number back is not a justification.

---

## Extend a Logical Volume

Once the installation is complete:

1. Extend one logical volume.
2. Grow its filesystem.
3. Perform the operation while the system is running.
4. Do not lose any data.
5. Document the commands you used.

### Important

Growing is the **online operation**.

Shrinking an `ext4` filesystem requires unmounting it first, and **XFS cannot be shrunk at all**.

Explain in your runbook why you would rather:

> Over-provision the volume group and grow later than guess large up front.

---

# Networking

Configure a **static IP address** from the command line by editing the system's network configuration files.

Do **not** use a graphical tool.

Confirm that the machine:

* resolves DNS
* reaches the Internet

---

# A Service of Your Own

Write a small script that runs continuously and does something useful and repeatable.

For example:

* Every minute, append disk usage to a log file.
* Check that a directory exists and recreate it if it does not.

The script must keep running:

```text
do the work
    ↓
sleep
    ↓
loop
```

Then write a **systemd service unit** for it that:

* starts automatically on boot
* restarts automatically whenever the process stops
* restarts whether it exited cleanly or crashed
* uses `Restart=always`
* writes its output to the journal
* allows the output to be viewed with `journalctl`

---

## Important: Keep the Script Running

A script that does its work once and exits needs a **systemd timer**, not a service with a restart policy.

`Restart=always` is rejected outright on a `Type=oneshot` unit.

On a `Type=simple` script that exits immediately, it trips the start rate limit and leaves the unit failed.

**Keep the loop.**

---

## Service Naming

Choose a clear name for the service and use that same name everywhere:

* in the script
* in the unit file
* in your runbook

You will keep building on this service.

In `login`, you control who is allowed to restart it.

In `add-vm`, you provision it from code.

---

# Understand Your Boot

Include a short report in your `README.md` that answers the following questions.

## 1. Slowest Units

Which units are slowest at boot?

Use:

```bash
systemd-analyze blame
```

## 2. Analyze One Unit

Pick one of the slowest units.

Explain, in your own words:

* what it does
* why it takes that long

## 3. `enabled` vs `active`

What is the difference between a service that is **enabled** and one that is **active**?

---

# Runbook

Your `README.md` must be a **runbook**.

It must be precise enough that another student can follow it and produce the same machine with:

* the same volumes
* the same service
* the same network configuration

If your auditor cannot rebuild your server from your runbook, your runbook is not finished.

---

# Project Repository Structure

```text
linux
├── README.md                  # the runbook: build steps, volume sizing,
│                              # grow procedure, boot report
├── scripts
│   └── myservice.sh           # the script behind your systemd service
└── systemd
    └── myservice.service      # your systemd unit file
```

## Files

### `README.md`

The `README.md` is the **most important deliverable**.

It contains:

* the runbook
* volume sizing justification
* grow procedure
* boot report

### `scripts/myservice.sh`

Contains the logic your service runs.

### `systemd/myservice.service`

Contains the systemd unit file that supervises the service.

> `myservice` is an example name. Pick your own and use it consistently across the script, the unit file, and your runbook.

---

# Tips

## Take a VM Snapshot

Take a snapshot of the VM immediately after a clean install.

When you break something while experimenting with LVM, you will be glad you did.

## Leave Free Space in the Volume Group

Leave free space in the volume group rather than allocating every extent at install time.

You cannot grow a volume out of space that is already spoken for.

Keep some free extents after you finish the exercise.

Your auditor asks you to repeat the live grow, and `vgs` reporting zero free space ends that step before it starts.

## Give `/var` Real Headroom

Give `/var` real headroom.

Logs, package caches, and databases live there, and a full `/var` is one of the most common ways a server falls over.

## `Restart=always`

`Restart=on-failure` ignores a clean exit, and systemd counts a plain kill as clean.

If you want the service back no matter how it stopped, use:

```ini
Restart=always
```

## View Service Logs

Use:

```bash
journalctl -u <your-service>.service
```

This shows only your service's logs, which is far easier to read than the full journal.

## Write the Runbook as You Go

Write the runbook as you go, not at the end.

A runbook reconstructed from memory always misses the step that mattered.

---

# Resources

* **Debian Administrator's Handbook** — the canonical reference for administering Debian.
* **LVM (Arch Wiki)** — clear explanations of physical volumes, volume groups, and logical volumes.
* **systemd unit files (Arch Wiki)** — how to write and enable a service unit.
* `man systemd.service` — the restart policies and what each one counts as a failure.
* `man systemd-analyze` — measuring boot performance.
