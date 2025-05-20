// src/assembly/index.ts
// AssemblyScript implementation of blur

// Entry point: uses manual memory layout, no heap allocs
export function blur(ptr: usize, width: i32, height: i32): void {
  const size = width * height;
  const rgbaSize = size * 4;
  trace("blur ptr=" + ptr.toString());

  const grayPtr = ptr + rgbaSize;
  const tempPtr = grayPtr + size;

  toGrayscale(ptr, grayPtr, width, height);
  blurGrayscaleSIMD(grayPtr, tempPtr, width, height);
  mergeGrayToRGBA(grayPtr, ptr, width, height);
}

// Converts RGBA to grayscale at grayPtr
function toGrayscale(rgbaPtr: usize, grayPtr: usize, width: i32, height: i32): void {
  const size = width * height;
  for (let i = 0; i < size; i++) {
    const r = load<u8>(rgbaPtr + i * 4 + 0);
    const g = load<u8>(rgbaPtr + i * 4 + 1);
    const b = load<u8>(rgbaPtr + i * 4 + 2);
    const y = (299 * r + 587 * g + 114 * b) / 1000;
    store<u8>(grayPtr + i, <u8>y);
  }
}

function mergeGrayToRGBA(grayPtr: usize, rgbaPtr: usize, width: i32, height: i32): void {
  const size = width * height;
  for (let i = 0; i < size; i++) {
    const gray = load<u8>(grayPtr + i);
    const a = load<u8>(rgbaPtr + i * 4 + 3); // preserve alpha


    store<u8>(rgbaPtr + i * 4 + 0, gray);
    store<u8>(rgbaPtr + i * 4 + 1, gray);
    store<u8>(rgbaPtr + i * 4 + 2, gray);
    store<u8>(rgbaPtr + i * 4 + 3, 255); // write alpha back
  }
}

// Grayscale blur using horizontal SIMD-style loop and vertical scalar pass
function blurGrayscaleSIMD(grayPtr: usize, tempPtr: usize, width: i32, height: i32): void {
  const radius = 3;
  const kernelWidth = radius * 2 + 1;

  // Horizontal pass
  for (let y = 0; y < height; y++) {
    const rowStart = y * width;

    for (let x = radius; x <= width - radius - 16; x += 16) {
      let acc = new StaticArray<i32>(16);
      for (let i = 0; i < 16; i++) unchecked(acc[i] = 0);

      for (let dx = -radius; dx <= radius; dx++) {
        const base = grayPtr + rowStart + x + dx;
        for (let i = 0; i < 16; i++) {
          unchecked(acc[i] += load<u8>(base + i));
        }
      }

      for (let i = 0; i < 16; i++) {
        const idx = rowStart + x + i;
        store<u8>(tempPtr + idx, <u8>(unchecked(acc[i]) / kernelWidth));
      }
    }

    // Fallback for end of row
    for (let x = width - radius - (width % 16); x < width - radius; x++) {
      let sum = 0, count = 0;
      for (let dx = -radius; dx <= radius; dx++) {
        const px = x + dx;
        if (px >= 0 && px < width) {
          sum += load<u8>(grayPtr + rowStart + px);
          count++;
        }
      }
      const idx = rowStart + x;
      store<u8>(tempPtr + idx, <u8>(sum / count));
    }
  }

  // Vertical pass
  for (let y = radius; y < height - radius; y++) {
    for (let x = 0; x < width; x++) {
      let sum = 0, count = 0;
      for (let dy = -radius; dy <= radius; dy++) {
        const py = y + dy;
        if (py >= 0 && py < height) {
          sum += load<u8>(tempPtr + (py * width + x));
          count++;
        }
      }
      const idx = y * width + x;
      store<u8>(grayPtr + idx, <u8>(sum / count));
    }
  }
}

// Allocation for the JS side
export function allocate(size: i32): usize {
  return __new(size, idof<ArrayBuffer>());
}

export function deallocate(ptr: usize): void {
  __free(ptr);
}
