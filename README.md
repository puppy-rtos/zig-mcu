# zig-mcu

可以在 mcu 上运行的最简 zig 工程

**目前支持架构：**

- riscv32
- stm32f4

## 依赖

- zig: 0.14.0

## 构建方式

```
zig build
```

## 下载运行

目前支持基于 QEMU 调试，以及在F4系列芯片真机运行，具体调试方法根据./vscode/launch.json自行探索。
