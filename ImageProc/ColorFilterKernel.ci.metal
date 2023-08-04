//
//  ColorFilterKernel.ci.metal
//  ImageProc
//
//  Created by Andrea Ruffino on 04/08/2023.
//  Copyright © 2023 Andrea Ruffino. All rights reserved.
//

#include <CoreImage/CoreImage.h>

extern "C" {
    namespace coreimage {
        float4 colorFilterKernel(sample_t pixel, float4 color) {
            pixel.rgb = pixel.a * color.rgb;
            pixel.a *= color.a;
            return pixel;
        }
    }
}
