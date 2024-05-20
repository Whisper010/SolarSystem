
#include <metal_stdlib>
using namespace metal;

#include "definitions.h"

struct VertexIn {
    float4 position [[attribute(0)]];
    float2 texcoord[[attribute(1)]];
    float3 normal [[attribute(2)]];
};

struct Fragment {
    float4 position [[position]];
    float2 texcoord;
    float4 color;
    float3 normal;
    float3 cameraPos;
    float3 fragPos;
    bool useTexture;
};

matrix_float3x3 extractUpperLeft3x3(matrix_float4x4 m) {
    return matrix_float3x3(
        float3(m[0][0], m[0][1], m[0][2]),
        float3(m[1][0], m[1][1], m[1][2]),
        float3(m[2][0], m[2][1], m[2][2])
    );
};

vertex Fragment vertexShader(
    const VertexIn vertex_in [[stage_in]],
    unsigned int vid [[vertex_id]],
    constant matrix_float4x4 &model [[buffer(1)]],
    constant CameraParameters &camera [[buffer(2)]],
    constant bool &useTexture [[buffer(3)]],
    constant vector_float4 &color [[buffer(4)]]) {
    
                                 
        //Extract the 3x3 matrix from the 4x4 model matrix
        matrix_float3x3 diminished_model = extractUpperLeft3x3(model);
        
        Fragment output;
        
        // perform transformation on vertices to adjust world position or camera view transformation, or projection
        output.position = camera.projection * camera.view * model * vertex_in.position;
        
        output.texcoord = vertex_in.texcoord;
        output.color = color;
        output.useTexture = useTexture;
        
        output.normal = normalize(diminished_model * vertex_in.normal);
        
        output.cameraPos = camera.position;
        output.fragPos = float3(model * vertex_in.position);
        
        return output;
    }

fragment float4 fragmentShader(
    Fragment input [[stage_in]],
    texture2d<float> objectTexture [[texture(0)]],
    sampler samplerObject [[sampler(0)]],
    constant DirectionalLight &sun [[buffer(0)]]) {
        
        float lightIntensity = 2.0;
        
        float3 baseColor = input.useTexture ? float3(objectTexture.sample(samplerObject, input.texcoord)) : float3(input.color);
        
        float ambient = 0.5;
        float3 color = ambient * baseColor ;
        
        //Diffuse
        float3 lightDir = normalize(-sun.forwards);
         float3 normal = normalize(input.normal);
         float3 lightAmount = max(0.0, dot(normal, lightDir));
         color += lightAmount * baseColor * sun.color * lightIntensity;
        
        // Specular  (optional)
        
//         float3 fragCamera = normalize(input.cameraPos - input.fragPos);
//         float3 halfVec = normalize(lightDir + fragCamera);
//         float specularAmount = pow(max(0.0, dot(normal, halfVec)), 32);
//         color += specularAmount * float3(1.0) * lightIntensity; 
        
        return float4(color, 1.0);
}



