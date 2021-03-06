struct Light
{
    float lightIntensity;
    int lightType;
    int lightCastShadow;
    int lightShadowMapIndex;
    int lightAngleAttenCurveType;
    int lightDistAttenCurveType;
    float2 lightSize;
    int4 lightGUID;
    float4 lightPosition;
    float4 lightColor;
    float4 lightDirection;
    float4 lightDistAttenCurveParams[2];
    float4 lightAngleAttenCurveParams[2];
    row_major float4x4 lightVP;
    float4 padding[2];
};

static const float2 _332[4] = { float2(-0.94201624393463134765625f, -0.39906215667724609375f), float2(0.94558608531951904296875f, -0.768907248973846435546875f), float2(-0.094184100627899169921875f, -0.929388701915740966796875f), float2(0.34495937824249267578125f, 0.29387760162353515625f) };

cbuffer _710 : register(b0, space0)
{
    row_major float4x4 _710_viewMatrix : packoffset(c0);
    row_major float4x4 _710_projectionMatrix : packoffset(c4);
    float4 _710_camPos : packoffset(c8);
    int _710_numLights : packoffset(c9);
    Light _710_allLights[100] : packoffset(c10);
};
TextureCubeArray<float4> cubeShadowMap : register(t3, space0);
SamplerState _cubeShadowMap_sampler : register(s3, space0);
Texture2DArray<float4> shadowMap : register(t1, space0);
SamplerState _shadowMap_sampler : register(s1, space0);
Texture2DArray<float4> globalShadowMap : register(t2, space0);
SamplerState _globalShadowMap_sampler : register(s2, space0);
Texture2D<float4> heightMap : register(t10, space0);
SamplerState _heightMap_sampler : register(s10, space0);
Texture2D<float4> normalMap : register(t5, space0);
SamplerState _normalMap_sampler : register(s5, space0);
Texture2D<float4> diffuseMap : register(t0, space0);
SamplerState _diffuseMap_sampler : register(s0, space0);
Texture2D<float4> metallicMap : register(t6, space0);
SamplerState _metallicMap_sampler : register(s6, space0);
Texture2D<float4> roughnessMap : register(t7, space0);
SamplerState _roughnessMap_sampler : register(s7, space0);
Texture2D<float4> aoMap : register(t8, space0);
SamplerState _aoMap_sampler : register(s8, space0);
TextureCubeArray<float4> skybox : register(t4, space0);
SamplerState _skybox_sampler : register(s4, space0);
Texture2D<float4> brdfLUT : register(t9, space0);
SamplerState _brdfLUT_sampler : register(s9, space0);

static float3 camPos_tangent;
static float3 v_tangent;
static float2 uv;
static float3x3 TBN;
static float4 v_world;
static float4 outputColor;

struct SPIRV_Cross_Input
{
    float4 v_world : TEXCOORD3;
    float2 uv : TEXCOORD4;
    float3x3 TBN : TEXCOORD5;
    float3 v_tangent : TEXCOORD8;
    float3 camPos_tangent : TEXCOORD9;
};

struct SPIRV_Cross_Output
{
    float4 outputColor : SV_Target0;
};

float _109;

float2 ParallaxMapping(float2 texCoords, float3 viewDir)
{
    float numLayers = lerp(32.0f, 8.0f, abs(dot(float3(0.0f, 0.0f, 1.0f), viewDir)));
    float layerDepth = 1.0f / numLayers;
    float currentLayerDepth = 0.0f;
    float2 currentTexCoords = texCoords;
    float currentDepthMapValue = 1.0f - heightMap.Sample(_heightMap_sampler, currentTexCoords).x;
    float2 P = viewDir.xy * 0.100000001490116119384765625f;
    float2 deltaTexCoords = P / numLayers.xx;
    while (currentLayerDepth < currentDepthMapValue)
    {
        currentTexCoords -= deltaTexCoords;
        currentDepthMapValue = 1.0f - heightMap.Sample(_heightMap_sampler, currentTexCoords).x;
        currentLayerDepth += layerDepth;
    }
    float2 prevTexCoords = currentTexCoords + deltaTexCoords;
    float afterDepth = currentDepthMapValue - currentLayerDepth;
    float beforeDepth = ((1.0f - heightMap.Sample(_heightMap_sampler, prevTexCoords).x) - currentLayerDepth) + layerDepth;
    float weight = afterDepth / (afterDepth - beforeDepth);
    float2 finalTexCoords = (prevTexCoords * weight) + (currentTexCoords * (1.0f - weight));
    return finalTexCoords;
}

float3 inverse_gamma_correction(float3 color)
{
    return pow(color, 2.2000000476837158203125f.xxx);
}

float shadow_test(float4 p, Light light, float cosTheta)
{
    float4 v_light_space = mul(p, light.lightVP);
    v_light_space /= v_light_space.w.xxxx;
    float visibility = 1.0f;
    if (light.lightShadowMapIndex != (-1))
    {
        float bias = 0.0005000000237487256526947021484375f * tan(acos(cosTheta));
        bias = clamp(bias, 0.0f, 0.00999999977648258209228515625f);
        float near_occ;
        switch (light.lightType)
        {
            case 0:
            {
                float3 L = p.xyz - light.lightPosition.xyz;
                near_occ = cubeShadowMap.Sample(_cubeShadowMap_sampler, float4(L, float(light.lightShadowMapIndex))).x;
                if ((length(L) - (near_occ * 10.0f)) > bias)
                {
                    visibility -= 0.87999999523162841796875f;
                }
                break;
            }
            case 1:
            {
                v_light_space = mul(v_light_space, float4x4(float4(0.5f, 0.0f, 0.0f, 0.0f), float4(0.0f, 0.5f, 0.0f, 0.0f), float4(0.0f, 0.0f, 0.5f, 0.0f), float4(0.5f, 0.5f, 0.5f, 1.0f)));
                for (int i = 0; i < 4; i++)
                {
                    float2 indexable[4] = _332;
                    near_occ = shadowMap.Sample(_shadowMap_sampler, float3(v_light_space.xy + (indexable[i] / 700.0f.xx), float(light.lightShadowMapIndex))).x;
                    if ((v_light_space.z - near_occ) > bias)
                    {
                        visibility -= 0.2199999988079071044921875f;
                    }
                }
                break;
            }
            case 2:
            {
                v_light_space = mul(v_light_space, float4x4(float4(0.5f, 0.0f, 0.0f, 0.0f), float4(0.0f, 0.5f, 0.0f, 0.0f), float4(0.0f, 0.0f, 0.5f, 0.0f), float4(0.5f, 0.5f, 0.5f, 1.0f)));
                for (int i_1 = 0; i_1 < 4; i_1++)
                {
                    float2 indexable_1[4] = _332;
                    near_occ = globalShadowMap.Sample(_globalShadowMap_sampler, float3(v_light_space.xy + (indexable_1[i_1] / 700.0f.xx), float(light.lightShadowMapIndex))).x;
                    if ((v_light_space.z - near_occ) > bias)
                    {
                        visibility -= 0.2199999988079071044921875f;
                    }
                }
                break;
            }
            case 3:
            {
                v_light_space = mul(v_light_space, float4x4(float4(0.5f, 0.0f, 0.0f, 0.0f), float4(0.0f, 0.5f, 0.0f, 0.0f), float4(0.0f, 0.0f, 0.5f, 0.0f), float4(0.5f, 0.5f, 0.5f, 1.0f)));
                for (int i_2 = 0; i_2 < 4; i_2++)
                {
                    float2 indexable_2[4] = _332;
                    near_occ = shadowMap.Sample(_shadowMap_sampler, float3(v_light_space.xy + (indexable_2[i_2] / 700.0f.xx), float(light.lightShadowMapIndex))).x;
                    if ((v_light_space.z - near_occ) > bias)
                    {
                        visibility -= 0.2199999988079071044921875f;
                    }
                }
                break;
            }
        }
    }
    return visibility;
}

float linear_interpolate(float t, float begin, float end)
{
    if (t < begin)
    {
        return 1.0f;
    }
    else
    {
        if (t > end)
        {
            return 0.0f;
        }
        else
        {
            return (end - t) / (end - begin);
        }
    }
}

float apply_atten_curve(float dist, int atten_curve_type, float4 atten_params[2])
{
    float atten = 1.0f;
    switch (atten_curve_type)
    {
        case 1:
        {
            float begin_atten = atten_params[0].x;
            float end_atten = atten_params[0].y;
            float param = dist;
            float param_1 = begin_atten;
            float param_2 = end_atten;
            atten = linear_interpolate(param, param_1, param_2);
            break;
        }
        case 2:
        {
            float begin_atten_1 = atten_params[0].x;
            float end_atten_1 = atten_params[0].y;
            float param_3 = dist;
            float param_4 = begin_atten_1;
            float param_5 = end_atten_1;
            float tmp = linear_interpolate(param_3, param_4, param_5);
            atten = (3.0f * pow(tmp, 2.0f)) - (2.0f * pow(tmp, 3.0f));
            break;
        }
        case 3:
        {
            float scale = atten_params[0].x;
            float offset = atten_params[0].y;
            float kl = atten_params[0].z;
            float kc = atten_params[0].w;
            atten = clamp((scale / ((kl * dist) + (kc * scale))) + offset, 0.0f, 1.0f);
            break;
        }
        case 4:
        {
            float scale_1 = atten_params[0].x;
            float offset_1 = atten_params[0].y;
            float kq = atten_params[0].z;
            float kl_1 = atten_params[0].w;
            float kc_1 = atten_params[1].x;
            atten = clamp(pow(scale_1, 2.0f) / ((((kq * pow(dist, 2.0f)) + ((kl_1 * dist) * scale_1)) + (kc_1 * pow(scale_1, 2.0f))) + offset_1), 0.0f, 1.0f);
            break;
        }
        case 0:
        {
            break;
        }
        default:
        {
            break;
        }
    }
    return atten;
}

float DistributionGGX(float3 N, float3 H, float roughness)
{
    float a = roughness * roughness;
    float a2 = a * a;
    float NdotH = max(dot(N, H), 0.0f);
    float NdotH2 = NdotH * NdotH;
    float num = a2;
    float denom = (NdotH2 * (a2 - 1.0f)) + 1.0f;
    denom = (3.1415927410125732421875f * denom) * denom;
    return num / denom;
}

float GeometrySchlickGGXDirect(float NdotV, float roughness)
{
    float r = roughness + 1.0f;
    float k = (r * r) / 8.0f;
    float num = NdotV;
    float denom = (NdotV * (1.0f - k)) + k;
    return num / denom;
}

float GeometrySmithDirect(float3 N, float3 V, float3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0f);
    float NdotL = max(dot(N, L), 0.0f);
    float param = NdotV;
    float param_1 = roughness;
    float ggx2 = GeometrySchlickGGXDirect(param, param_1);
    float param_2 = NdotL;
    float param_3 = roughness;
    float ggx1 = GeometrySchlickGGXDirect(param_2, param_3);
    return ggx1 * ggx2;
}

float3 fresnelSchlick(float cosTheta, float3 F0)
{
    return F0 + ((1.0f.xxx - F0) * pow(1.0f - cosTheta, 5.0f));
}

float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
{
    return F0 + ((max((1.0f - roughness).xxx, F0) - F0) * pow(1.0f - cosTheta, 5.0f));
}

float3 reinhard_tone_mapping(float3 color)
{
    return color / (color + 1.0f.xxx);
}

float3 gamma_correction(float3 color)
{
    return pow(color, 0.4545454680919647216796875f.xxx);
}

void frag_main()
{
    float3 viewDir = normalize(camPos_tangent - v_tangent);
    float2 param = uv;
    float3 param_1 = viewDir;
    float2 texCoords = ParallaxMapping(param, param_1);
    float3 tangent_normal = normalMap.Sample(_normalMap_sampler, texCoords).xyz;
    tangent_normal = (tangent_normal * 2.0f) - 1.0f.xxx;
    float3 N = normalize(mul(tangent_normal, TBN));
    float3 V = normalize(_710_camPos.xyz - v_world.xyz);
    float3 R = reflect(-V, N);
    float3 param_2 = diffuseMap.Sample(_diffuseMap_sampler, texCoords).xyz;
    float3 albedo = inverse_gamma_correction(param_2);
    float meta = metallicMap.Sample(_metallicMap_sampler, texCoords).x;
    float rough = roughnessMap.Sample(_roughnessMap_sampler, texCoords).x;
    float3 F0 = 0.039999999105930328369140625f.xxx;
    F0 = lerp(F0, albedo, meta.xxx);
    float3 Lo = 0.0f.xxx;
    for (int i = 0; i < _710_numLights; i++)
    {
        Light light;
        light.lightIntensity = _710_allLights[i].lightIntensity;
        light.lightType = _710_allLights[i].lightType;
        light.lightCastShadow = _710_allLights[i].lightCastShadow;
        light.lightShadowMapIndex = _710_allLights[i].lightShadowMapIndex;
        light.lightAngleAttenCurveType = _710_allLights[i].lightAngleAttenCurveType;
        light.lightDistAttenCurveType = _710_allLights[i].lightDistAttenCurveType;
        light.lightSize = _710_allLights[i].lightSize;
        light.lightGUID = _710_allLights[i].lightGUID;
        light.lightPosition = _710_allLights[i].lightPosition;
        light.lightColor = _710_allLights[i].lightColor;
        light.lightDirection = _710_allLights[i].lightDirection;
        light.lightDistAttenCurveParams[0] = _710_allLights[i].lightDistAttenCurveParams[0];
        light.lightDistAttenCurveParams[1] = _710_allLights[i].lightDistAttenCurveParams[1];
        light.lightAngleAttenCurveParams[0] = _710_allLights[i].lightAngleAttenCurveParams[0];
        light.lightAngleAttenCurveParams[1] = _710_allLights[i].lightAngleAttenCurveParams[1];
        light.lightVP = _710_allLights[i].lightVP;
        light.padding[0] = _710_allLights[i].padding[0];
        light.padding[1] = _710_allLights[i].padding[1];
        float3 L = normalize(light.lightPosition.xyz - v_world.xyz);
        float3 H = normalize(V + L);
        float NdotL = max(dot(N, L), 0.0f);
        float visibility = shadow_test(v_world, light, NdotL);
        float lightToSurfDist = length(L);
        float lightToSurfAngle = acos(dot(-L, light.lightDirection.xyz));
        float param_3 = lightToSurfAngle;
        int param_4 = light.lightAngleAttenCurveType;
        float4 param_5[2] = light.lightAngleAttenCurveParams;
        float atten = apply_atten_curve(param_3, param_4, param_5);
        float param_6 = lightToSurfDist;
        int param_7 = light.lightDistAttenCurveType;
        float4 param_8[2] = light.lightDistAttenCurveParams;
        atten *= apply_atten_curve(param_6, param_7, param_8);
        float3 radiance = light.lightColor.xyz * (light.lightIntensity * atten);
        float3 param_9 = N;
        float3 param_10 = H;
        float param_11 = rough;
        float NDF = DistributionGGX(param_9, param_10, param_11);
        float3 param_12 = N;
        float3 param_13 = V;
        float3 param_14 = L;
        float param_15 = rough;
        float G = GeometrySmithDirect(param_12, param_13, param_14, param_15);
        float param_16 = max(dot(H, V), 0.0f);
        float3 param_17 = F0;
        float3 F = fresnelSchlick(param_16, param_17);
        float3 kS = F;
        float3 kD = 1.0f.xxx - kS;
        kD *= (1.0f - meta);
        float3 numerator = F * (NDF * G);
        float denominator = (4.0f * max(dot(N, V), 0.0f)) * NdotL;
        float3 specular = numerator / max(denominator, 0.001000000047497451305389404296875f).xxx;
        Lo += ((((((kD * albedo) / 3.1415927410125732421875f.xxx) + specular) * radiance) * NdotL) * visibility);
    }
    float ambientOcc = aoMap.Sample(_aoMap_sampler, texCoords).x;
    float param_18 = max(dot(N, V), 0.0f);
    float3 param_19 = F0;
    float param_20 = rough;
    float3 F_1 = fresnelSchlickRoughness(param_18, param_19, param_20);
    float3 kS_1 = F_1;
    float3 kD_1 = 1.0f.xxx - kS_1;
    kD_1 *= (1.0f - meta);
    float3 irradiance = skybox.SampleLevel(_skybox_sampler, float4(N, 0.0f), 1.0f).xyz;
    float3 diffuse = irradiance * albedo;
    float3 prefilteredColor = skybox.SampleLevel(_skybox_sampler, float4(R, 1.0f), rough * 9.0f).xyz;
    float2 envBRDF = brdfLUT.Sample(_brdfLUT_sampler, float2(max(dot(N, V), 0.0f), rough)).xy;
    float3 specular_1 = prefilteredColor * ((F_1 * envBRDF.x) + envBRDF.y.xxx);
    float3 ambient = ((kD_1 * diffuse) + specular_1) * ambientOcc;
    float3 linearColor = ambient + Lo;
    float3 param_21 = linearColor;
    linearColor = reinhard_tone_mapping(param_21);
    float3 param_22 = linearColor;
    linearColor = gamma_correction(param_22);
    outputColor = float4(linearColor, 1.0f);
}

SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    camPos_tangent = stage_input.camPos_tangent;
    v_tangent = stage_input.v_tangent;
    uv = stage_input.uv;
    TBN = stage_input.TBN;
    v_world = stage_input.v_world;
    frag_main();
    SPIRV_Cross_Output stage_output;
    stage_output.outputColor = outputColor;
    return stage_output;
}
