#include "OpenGLShaderManager.hpp"

#define VS_SHADER_SOURCE_FILE "Shaders/basic_vs.glsl"
#define PS_SHADER_SOURCE_FILE "Shaders/basic_ps.glsl"
#define VS_SHADOWMAP_SOURCE_FILE "Shaders/shadowmap_vs.glsl"
#define PS_SHADOWMAP_SOURCE_FILE "Shaders/shadowmap_ps.glsl"
#define VS_OMNI_SHADOWMAP_SOURCE_FILE "Shaders/shadowmap_omni_vs.glsl"
#define PS_OMNI_SHADOWMAP_SOURCE_FILE "Shaders/shadowmap_omni_ps.glsl"
#define GS_OMNI_SHADOWMAP_SOURCE_FILE "Shaders/shadowmap_omni_gs.glsl"
#define DEBUG_VS_SHADER_SOURCE_FILE "Shaders/debug_vs.glsl"
#define DEBUG_PS_SHADER_SOURCE_FILE "Shaders/debug_ps.glsl"
#define VS_PASSTHROUGH_SOURCE_FILE "Shaders/passthrough_vs.glsl"
#define PS_SIMPLE_TEXTURE_SOURCE_FILE "Shaders/depthtexture_ps.glsl"
#define VS_PASSTHROUGH_CUBEMAP_SOURCE_FILE "Shaders/passthrough_cube_vs.glsl"
#define PS_SIMPLE_DEPTH_CUBEMAP_SOURCE_FILE "Shaders/depthcubemap_ps.glsl"
#define PS_SIMPLE_CUBEMAP_SOURCE_FILE "Shaders/cubemap_ps.glsl"
#define VS_SKYBOX_SOURCE_FILE "Shaders/skybox_vs.glsl"
#define PS_SKYBOX_SOURCE_FILE "Shaders/skybox_ps.glsl"

#include "OpenGLShaderManagerCommonBase.cpp"