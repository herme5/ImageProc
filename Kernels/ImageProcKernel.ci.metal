//
//  ImageProcKernel.ci.metal
//  ImageProc
//
//  Created by Andrea Ruffino on 04/08/2023.
//  Copyright © 2023 Andrea Ruffino. All rights reserved.
//

#include <CoreImage/CoreImage.h>

extern "C" {
    namespace coreimage {

        float4 colorize(sample_t pixel, float4 color) {
            pixel.rgb = pixel.a * color.rgb;
            pixel.a *= color.a;
            return pixel;
        }

        float4 exclude(sample_t pixel_a, sample_t pixel_b) {
            return abs(pixel_a - pixel_b);
        }

        // Replicates the source around a circle of the given radius, in `count` directions spaced `step` degrees
        // apart, and keeps the most opaque of those samples. This is the gather form of the expansion: every output
        // pixel depends only on its own ring of source samples, so there is nothing to synchronise.
        //
        // The samples sit exactly on the circle rather than filling the disc, which is what the CPU implementations
        // do too — a filled disc would thicken thin artwork differently.
        //
        // Keeping the most opaque sample rather than the per-channel maximum preserves the colors of a multi-colored
        // source instead of bleeding channels together, and is the same thing for the single-colored input `stroked`
        // always produces.
        float4 expand(sampler src, float radius, float count, float step, destination dest) {
            const float degreesToRadians = 0.017453292519943295;
            float2 position = dest.coord();
            float4 best = float4(0.0);

            for (int i = 0; i < int(count); ++i) {
                float angle = step * float(i) * degreesToRadians;
                float2 offset = float2(cos(angle), sin(angle)) * radius;
                float4 candidate = sample(src, samplerTransform(src, position - offset));
                if (candidate.a > best.a) {
                    best = candidate;
                }
            }
            return best;
        }
    }
}
