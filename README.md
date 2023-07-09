# ffbench
A simple script to time compilation of Firefox

Currently only MacOS is supported. Instructions taken from: [The Firefox Source Docs](https://firefox-source-docs.mozilla.org/setup/macos_build.html)

## Running
To run the benchmark, just clone this repository and run:
```
./ffbench.sh
```

The script may exit asking you to fulfill a dependency or run a command. If this happens, perform the recommended action, and then re-run the script.

## Results

### MacBook Pro 16-inch, 2023
```
Model Name:	MacBook Pro
Model Identifier:	Mac14,6
Model Number:	MNWE3LL/A
Chip:	Apple M2 Max
Total Number of Cores:	12 (8 performance and 4 efficiency)
Memory:	32 GB
System Firmware Version:	8422.121.1
OS Loader Version:	8422.121.1
Real SSD Size: 994.66 GB
```

```
real    12m22.663s
user    116m19.962s
sys     6m12.779s
```
