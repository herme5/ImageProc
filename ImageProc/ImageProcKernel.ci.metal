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
    }
}
