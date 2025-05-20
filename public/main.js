// TODO: Import the Rust WASM JavaScript module here as rustWasm

window.addEventListener('DOMContentLoaded', async () => {
  const canvas = document.getElementById('canvas');
  const ctx = canvas.getContext('2d', { willReadFrequently: true });
  const img = new Image();
  img.src = './tsunami.jpg';


  // Setting up AssemblyScript WASM
  let asWasm = null;
  let memory = null;
  let globalPtr = null;
  let globalView = null;
  let globalLen = 0;

  const jsTimeElement = document.getElementById('js-time');
  const wasmTimeElement = document.getElementById('as-time');
  const rustTimeElement = document.getElementById('rs-time');

  img.onload = () => {
    canvas.width = img.width;
    canvas.height = img.height;
    ctx.drawImage(img, 0, 0);
  };

  // Load AssemblyScript WASM
  WebAssembly.instantiateStreaming(fetch('/dist/as_blur.wasm'), {
    env: {
      abort(msg, file, line, col) {
        console.error('[WASM ABORT]', { msg, file, line, col });
      },
    }
  }).then(({ instance }) => {
    asWasm = instance.exports;
    memory = asWasm.memory;
    console.log('[WASM] Loaded AssemblyScript WebAssembly successfully.');
    document.getElementById('asBlurBtn').disabled = false;
  }).catch((err) => {
    console.error("[WASM] Failed to load AssemblyScript WASM:", err);
  });

  let wasmInstance;
  // TODO: Load and initialize Rust WASM here.

  // AssemblyScript event listener
  document.getElementById('asBlurBtn').addEventListener('click', () => {
    if (!asWasm || !memory) return;

    const loader = document.getElementById('as-loader');
    loader.style.display = 'block';

    requestAnimationFrame(() => {
      setTimeout(() => {
        try {
          const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
          const data = imageData.data;
          const width = canvas.width;
          const height = canvas.height;

          const rgbaBytes = width * height * 4;
          const grayBytes = width * height;
          const tempBytes = width * height;
          const totalBytes = rgbaBytes + grayBytes + tempBytes;

          // Always grow memory BEFORE allocation
          while (asWasm.memory.buffer.byteLength < totalBytes + 64) {
            asWasm.memory.grow(1); // 64KB pages
          }

          memory = asWasm.memory;
          if (globalPtr && asWasm.deallocate) {
            asWasm.deallocate(globalPtr);
          }

          globalPtr = asWasm.allocate(totalBytes);
          globalLen = totalBytes;
          globalView = new Uint8Array(memory.buffer, globalPtr, totalBytes);

          // Copy RGBA data into buffer
          for (let i = 0; i < rgbaBytes; i++) {
            globalView[i] = data[i];
          }

          const start = performance.now();
          asWasm.blur(globalPtr, width, height);
          const end = performance.now();

          // Refresh view in case buffer grew
          globalView = new Uint8Array(memory.buffer, globalPtr, globalLen);

          // Copy results back to ImageData
          for (let i = 0; i < rgbaBytes; i++) {
            data[i] = globalView[i];
          }

          ctx.putImageData(imageData, 0, 0);
          wasmTimeElement.textContent = `${(end - start).toFixed(2)} ms`;
          loader.style.display = 'none';
        } catch (err) {
          console.error('[ERROR] WASM blur handler failed:', err);
          loader.style.display = 'none';
        }
      }, 10);
    });
  });

  // JavaScript implementation of blur and event listener
  document.getElementById('jsBlurBtn').addEventListener('click', () => {
    const loader = document.getElementById('js-loader');
    loader.style.display = 'block';

    requestAnimationFrame(() => {
      setTimeout(() => {
        const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
        const data = imageData.data;
        const width = canvas.width;
        const height = canvas.height;
        const gray = new Uint8ClampedArray(width * height);

        for (let i = 0; i < width * height; i++) {
          const r = data[i * 4];
          const g = data[i * 4 + 1];
          const b = data[i * 4 + 2];
          gray[i] = Math.round(0.299 * r + 0.587 * g + 0.114 * b);
        }

        const radius = 7;
        const sigma = 3.0;
        const size = radius * 2 + 1;
        const kernel = new Float32Array(size * size);
        let sum = 0;

        const twoSigmaSq = 2 * sigma * sigma;
        const piSigma = Math.sqrt(2 * Math.PI * sigma * sigma);

        for (let y = -radius; y <= radius; y++) {
          for (let x = -radius; x <= radius; x++) {
            const distSq = x * x + y * y;
            const val = Math.exp(-distSq / twoSigmaSq) / piSigma;
            const idx = (y + radius) * size + (x + radius);
            kernel[idx] = val;
            sum += val;
          }
        }

        for (let i = 0; i < kernel.length; i++) {
          kernel[i] /= sum;
        }

        const start = performance.now();

        for (let y = 0; y < height; y++) {
          for (let x = 0; x < width; x++) {
            let r = 0, g = 0, b = 0;
            let ki = 0;

            for (let dy = -radius; dy <= radius; dy++) {
              const cy = Math.min(height - 1, Math.max(0, y + dy));
              for (let dx = -radius; dx <= radius; dx++) {
                const cx = Math.min(width - 1, Math.max(0, x + dx));
                const idx = (cy * width + cx) * 4;
                const w = kernel[ki++];
                r += gray[cy * width + cx] * w;
              }
            }

            const i = (y * width + x) * 4;
            const grayVal = r;
            data[i] = grayVal;
            data[i + 1] = grayVal;
            data[i + 2] = grayVal;
          }
        }

        const end = performance.now();
        ctx.putImageData(imageData, 0, 0);
        jsTimeElement.textContent = `${(end - start).toFixed(2)} ms`;
        loader.style.display = 'none';
      }, 10);
    });
  });

  // Rust event listener
  // TODO: Fill in the todos
  document.getElementById('rustBlurBtn').addEventListener('click', () => {
    if (!rustWasm) {
      console.error("[WASM] Rust WASM not initialized.");
      return;
    }

    const loader = document.getElementById('rs-loader');
    loader.style.display = 'block';

    requestAnimationFrame(() => {
      setTimeout(() => {
        const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
        const data = imageData.data;
        const len = data.length;

        // TODO: Allocate appropriate amount of memory for Rust WASM

        const start = performance.now();
        // TODO: Call Rust WASM blur here
        const end = performance.now();

        // TODO: Copy the WASM buffer back to the ImageData and then deallocate the memory

        ctx.putImageData(imageData, 0, 0);
        rustTimeElement.textContent = `${(end - start).toFixed(2)} ms`;
        loader.style.display = 'none';
      }, 10);
    });
  });

  // Reset button event listener
  document.getElementById('resetBtn').addEventListener('click', () => {
    ctx.drawImage(img, 0, 0);
    jsTimeElement.textContent = '-';
    wasmTimeElement.textContent = '-';
    rustTimeElement.textContent = '-';
  });
});
