# Nihilum

[![Platform](https://img.shields.io/badge/platform-x86__64--UEFI-blue)]() [![Language](https://img.shields.io/badge/language-x86__64%20Assembly-red)]() [![Status](https://img.shields.io/badge/status-Alpha-orange)]()

**Nihilum** is a fundamentally new operating system ecosystem, compiler, and programming language built from scratch with absolute zero legacy dependencies. It utterly rejects the decades of historical layers, patch stacks, and "temporary solutions" that modern computer systems (C, Rust, Linux, Windows, etc.) rely upon.

Born from "nothingness", Nihilum provides a clean, modern, and high-performance bare-metal architecture aiming for absolute and uninterrupted control over the hardware.

## 🌌 Philosophy & Vision

Modern software engineering is shaped by patches added layer upon layer over concepts dating back to the 1970s. Nihilum is a radical stance against this "legacy" culture:

- **Zero Legacy:** No old OS subroutines, no heavy abstraction layers, and no 50-year-old POSIX standards.
- **Absolute Transparency:** Written purely in x86-64 assembly and runs directly with UEFI.
- **Unified Architecture:** The bootloader, kernel, compiler, operating system, shell, and basic toolchain are a single integrated entity: *Nihilum*.
- **Performance:** There are no unnecessary layers between the processor and the software; every clock cycle is completely under the coder's control.

*"The old gods died with patches. The new era is born from nothingness."*

## 🏗 System Architecture

Nihilum is an end-to-end custom-designed structure:

- **Nihilum Bootloader (`boot.asm`, `BOOTX64.EFI`):** Boots the operating system from a pure sector directly over UEFI, without any virtual file system clutter.
- **Nihilum Kernel (`main.asm`):** An extremely fast kernel providing deterministic execution, stripped of unnecessary background processes.
- **Nihilum Compiler:** A natively running, self-hosted compiler chain. It is designed to generate a single binary from assembly to high-level Nihilum code.
  - **Lexer (`lexer.asm`)**
  - **Parser (`parser.asm`)**
  - **Code Generation (`codegen.asm`)**
- **Hardware Interaction & Interrupts:** Custom Interrupt Service Routines (ISRs - `isr.asm`) and tailored low-level pixel/text rendering engine (`font.asm`).

## ⚙️ Project Directory Overview

* `boot.asm` / `boot.nih`: Bootloader source codes.
* `BOOTX64.EFI`: Directly executable UEFI boot image.
* `main.asm`: Main kernel entry point.
* `lexer.asm` / `parser.asm` / `codegen.asm`: Native compiler built to compile its own programming language.
* `isr.asm`: Interrupt and exception handlers.
* `font.asm`: Custom low-level screen and character rendering engine.
* `manifesto.txt`: The official manifesto that forms the philosophical foundation of the project.

## 🚀 Getting Started & Setup

*(Note: Nihilum is an advanced system aimed at bare-metal execution on x86-64 architectures. It cannot be installed on any POSIX system; it must be booted directly on the hardware or in a virtual machine.)*

### Prerequisites
- **Hardware/Emulator:** A physical machine with x86-64 instruction set support or a hypervisor like QEMU/VirtualBox.
- **UEFI Support:** The system only boots in UEFI-supported environments (Legacy BIOS is not supported).
- **Compiler (For the current stage):** NASM (Netwide Assembler).

### Build Instructions
Currently, Nihilum is compiled using NASM. In future stages, Nihilum will compile itself by running its own compiler within.

```bash
# Compiling main assembly modules of the project into object files
nasm -f elf64 lexer.asm -o lexer.o
nasm -f elf64 parser.asm -o parser.o
nasm -f elf64 codegen.asm -o codegen.o
nasm -f elf64 main.asm -o main.o
```

### Running in an Emulator
You can test the system on QEMU using OVMF (Open Source UEFI Firmware):

```bash
qemu-system-x86_64 -m 512M -bios /path/to/OVMF_CODE.fd -drive file=fat:rw:hdd,format=raw
```
*(This command will boot the structure inside the `hdd` folder as a virtual UEFI disk. Ensure the `BOOTX64.EFI` file is within the standard `EFI/BOOT/` hierarchy.)*

## 📖 The Manifesto

To understand that this project is not just a technical experiment but also a rebellion against modern industry standards, read the **[manifesto.txt](./manifesto.txt)** file, which details our development philosophy.

> "There are no patches in my code. There is no legacy in my code. Writing code here is not a privilege, it is a revolution."

## 🤝 Contributing

Nihilum is for professionals who are tired of the chronic complexity and unreliability of current operating systems. Anyone who has a strong grasp of x86-64 assembly, hardware architecture, and zero-legacy goals can join this revolution.

---
**Nihilum OS** | *Born from nothingness.*
