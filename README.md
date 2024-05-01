# catasm
Simple cat-like command in Linux x86-64 assembly

# Build
`nasm` is required.
```
nasm -felf64 src/main.asm && ld src/main.o -o catasm
```
# Usage
```
./catasm /path/to/file
```
