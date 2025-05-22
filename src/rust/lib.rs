use wasm_bindgen::prelude::*;
use std::f32;

#[wasm_bindgen]
pub fn allocate(size: usize) -> *mut u8 {
    let mut buffer = Vec::with_capacity(size);
    buffer.resize(size, 0);
    let ptr = buffer.as_mut_ptr();
    std::mem::forget(buffer);
    ptr
}

#[wasm_bindgen]
pub fn deallocate(ptr: *mut u8, size: usize) {
    unsafe {
        let _ = Vec::from_raw_parts(ptr, size, size);
    }
}

#[wasm_bindgen]
pub fn blur(ptr: *mut u8, width: i32, height: i32) {
    // Set up the Gaussian blur parameters
    let width = width as usize;
    let height = height as usize;
    let radius: i32 = 7; // Use i32 for radius
    let sigma = 3.0;
    
    // Access pixel data
    let data = unsafe { std::slice::from_raw_parts_mut(ptr, width * height * 4) };
    
    // Step 1: Convert to grayscale first (exactly like JS)
    let mut gray = vec![0u8; width * height];
    for i in 0..width * height {
        let r = data[i * 4] as f32;
        let g = data[i * 4 + 1] as f32;
        let b = data[i * 4 + 2] as f32;
        gray[i] = (0.299 * r + 0.587 * g + 0.114 * b).round() as u8;
    }
    
    // Step 2: Create Gaussian kernel (exactly like JS)
    let size = (radius * 2 + 1) as usize;
    let mut kernel = vec![0.0f32; size * size];
    
    let two_sigma_sq = 2.0 * sigma * sigma;
    let pi_sigma = 2.0 * std::f32::consts::PI * sigma * sigma;

    let mut sum = 0.0;

    for y in -radius..=radius {
        for x in -radius..=radius {
            let dist_sq = (x * x + y * y) as f32;
            let val = f32::exp(-dist_sq / two_sigma_sq) / pi_sigma;
            let idx = ((y + radius) * size as i32 + (x + radius)) as usize;
            kernel[idx] = val;
            sum += val;
        }
    }
    
    // Normalize kernel
    for val in kernel.iter_mut() {
        *val /= sum;
    }
    
    // Step 3: Apply blur to grayscale image
    let mut blurred = vec![0.0f32; width * height];
    
    // Iterate over each pixel in the image
    for y in 0..height {
        for x in 0..width {
            // Iterate over the neighbors of the pixel
            let mut val = 0.0;
            let mut ki = 0;
            
            for dy in -radius..=radius {
                // TODO: Implement the blurring logic while taking boundaries into account
                // Hint: Take a look at clamp()
            }
            
            blurred[y * width + x] = val;
        }
    }
    
    // Step 4: Copy results back to image data
    for y in 0..height {
        for x in 0..width {
            let i = (y * width + x) * 4;
            let gray_val = blurred[y * width + x].round().clamp(0.0, 255.0) as u8;
            data[i]     = gray_val;  // Red channel
            data[i + 1] = gray_val;  // Green channel
            data[i + 2] = gray_val;  // Blue channel
        }
    }
}
