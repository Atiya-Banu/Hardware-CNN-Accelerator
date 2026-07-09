# Hardware-Accelerated 2D Convolution Engine

## Project Overview
This project implements a high-throughput, pipelined $3\times3$ Convolution Engine designed for real-time image processing applications on FPGAs. It utilizes a **Laplacian edge-detection filter** kernel to process streaming pixel inputs continuously.

## Key Features
- **Stream-Based Processing:** Processes data on every clock cycle using a fully pipelined architecture.
- **Line Buffer Memory Architecture:** Utilizes highly efficient internal line buffers to maintain a sliding $3\times3$ data window without stalling the data stream.
- **Signed Arithmetic:** Handles signed calculation paths to accurately report negative gradient changes on edges.

## Verification Results
Functional correctness was verified via testbench simulation using signed decimal waveform monitoring. The simulation captures the streaming pixel sequence alongside the stable kernel weights (`w00` through `w22`) to compute edge detection gradients.

![Simulation Waveform](docs/simulation_waveform.png)
