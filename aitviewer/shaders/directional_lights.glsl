struct DirLight {
    vec3 pos;
    vec3 color;
    float intensity_ambient;
    float intensity_diffuse;
    bool shadow_enabled;
    mat4 matrix;
};

#define NR_DIR_LIGHTS 2

uniform DirLight dirLights[NR_DIR_LIGHTS];
uniform sampler2DShadow shadow_maps[NR_DIR_LIGHTS];

uniform float diffuse_coeff;
uniform float ambient_coeff;

vec3 directionalLight(DirLight dirLight, vec3 color, vec3 fragPos, vec3 normal, float shadow) {
    // Ambient
    vec3 ambient = dirLight.intensity_ambient * dirLight.color * ambient_coeff;

    // Diffuse
    vec3 lightDir = normalize(dirLight.pos - fragPos);
    float diff = max(dot(normal, lightDir), 0.0);
    vec3 diffuse = diffuse_coeff * diff * dirLight.intensity_diffuse * dirLight.color;

    // Specular
//    vec3 viewDir = normalize(viewPos - fragPos);
//    vec3 reflectDir = reflect(-lightDir, normal);
//    float spec = pow(max(dot(viewDir, reflectDir), 0.0), dirLight.shininess);
//    vec3 specular = dirLight.specular * spec * dirLight.color;

    return (ambient + (1.0 - shadow)*diffuse) * color;
}

// Gratefully adopted from https://learnopengl.com/Advanced-Lighting/Shadows/Shadow-Mapping
float shadow_calculation(sampler2DShadow shadow_map, vec4 frag_pos_light_space, vec3 light_dir, vec3 normal) {
    // perform perspective divide (not needed for orthographic projection)
    vec3 projCoords = frag_pos_light_space.xyz / frag_pos_light_space.w;

    // transform to [0,1] range
    projCoords = projCoords * 0.5 + 0.5;

    // get closest depth value from light's perspective (using [0,1] range fragPosLight as coords)
    // float closestDepth = texture(shadow_map, projCoords.xy).r;

    // get depth of current fragment from light's perspective
    float currentDepth = projCoords.z;

    // calculate bias to remove shadow acne
    float bias = max(0.005 * (1.0 - dot(normal, light_dir)), 0.001);

    float shadow = 0.0;
    vec2 texelSize = 1.0 / textureSize(shadow_map, 0);
    for(int x = -1; x <= 1; ++x) {
        for(int y = -1; y <= 1; ++y) {
             shadow += texture(shadow_map, vec3(projCoords.xy + vec2(x, y) * texelSize, currentDepth - bias));
        }
    }
    shadow /= 9.0;

    if (projCoords.z > 1.0)
        shadow = 0.0;

    return shadow;
}

vec3 compute_lighting(vec3 base_color, vec3 vert, vec3 normal, vec4 vert_light[NR_DIR_LIGHTS]) {
    vec3 color = vec3(0.0, 0.0, 0.0);
    for(int i = 0; i < NR_DIR_LIGHTS; i++){
        float shadow = dirLights[i].shadow_enabled ? shadow_calculation(shadow_maps[i], vert_light[i], dirLights[i].pos, normal) : 0.0;
        color += directionalLight(dirLights[i], base_color.rgb, vert, normal, shadow);
    }
    return color;
}