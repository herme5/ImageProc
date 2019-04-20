//
//  ColorFilter.metal
//  Anagram
//
//  Created by Andrea Ruffino on 11/01/2019.
//  Copyright © 2019 Andrea Ruffino. All rights reserved.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>

using namespace metal;

extern "C" {
    namespace coreimage {
        
        float4 colorize(sample_t src, float4 color) {
            src.rgb = src.a * color.rgb;
            src.a *= color.a;
            return src;
        }
        
    }
}
