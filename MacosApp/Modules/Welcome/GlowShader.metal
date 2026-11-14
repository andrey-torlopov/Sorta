#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

struct Uniforms {
    float time;
    float2 resolution;
    float2 glowPosition;
    float isLight;   // 1 - светлая тема, 0 - тёмная
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = float4(in.position, 0.0, 1.0);
    out.texCoord = in.texCoord;
    return out;
}

// Функция для создания мягкого градиента
float smoothGradient(float2 uv, float2 center, float radius) {
    float dist = distance(uv, center);
    return 1.0 - smoothstep(0.0, radius, dist);
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant Uniforms &uniforms [[buffer(0)]]) {
    float2 uv = in.texCoord;
    float2 normalizedCoord = (in.texCoord * uniforms.resolution) / uniforms.resolution.y;

    // Создаем несколько блуждающих пятен с разными параметрами
    float2 glow1Pos = float2(
        0.5 + sin(uniforms.time * 0.5) * 0.3,
        0.5 + cos(uniforms.time * 0.3) * 0.25
    );

    float2 glow2Pos = float2(
        0.5 + cos(uniforms.time * 0.4) * 0.35,
        0.5 + sin(uniforms.time * 0.6) * 0.3
    );

    float2 glow3Pos = float2(
        0.5 + sin(uniforms.time * 0.35 + 2.0) * 0.28,
        0.5 + cos(uniforms.time * 0.45 + 1.5) * 0.32
    );

    // Нормализуем координаты для правильного соотношения сторон
    float aspect = uniforms.resolution.x / uniforms.resolution.y;
    float2 normalizedUV = float2(uv.x * aspect, uv.y);
    float2 normalizedGlow1 = float2(glow1Pos.x * aspect, glow1Pos.y);
    float2 normalizedGlow2 = float2(glow2Pos.x * aspect, glow2Pos.y);
    float2 normalizedGlow3 = float2(glow3Pos.x * aspect, glow3Pos.y);

    // Создаем градиенты для каждого пятна
    float glow1 = smoothGradient(normalizedUV, normalizedGlow1, 0.6);
    float glow2 = smoothGradient(normalizedUV, normalizedGlow2, 0.55);
    float glow3 = smoothGradient(normalizedUV, normalizedGlow3, 0.5);

    if (uniforms.isLight > 0.5) {
        // Светлая тема: мягкие пастельные пятна на светлой базе.
        float3 lightBackground = float3(0.9333, 0.9412, 0.9647); // #EEF0F6
        float3 lightColor1 = float3(0.70, 0.66, 0.95); // лавандовый
        float3 lightColor2 = float3(0.62, 0.78, 0.99); // голубой
        float3 lightColor3 = float3(0.99, 0.72, 0.82); // розовый

        float3 lightFinal = lightBackground;
        lightFinal = mix(lightFinal, lightColor1, glow1 * 0.45);
        lightFinal = mix(lightFinal, lightColor2, glow2 * 0.45);
        lightFinal = mix(lightFinal, lightColor3, glow3 * 0.45);
        return float4(lightFinal, 1.0);
    }

    // Тёмная тема: исходное неоновое свечение (похоже на Яндекс.Музыку).
    float3 color1 = float3(0.8, 0.2, 0.9); // Фиолетовый
    float3 color2 = float3(0.2, 0.4, 1.0); // Синий
    float3 color3 = float3(1.0, 0.3, 0.5); // Розовый

    // Смешиваем цвета
    float3 finalColor = color1 * glow1 + color2 * glow2 + color3 * glow3;

    // Добавляем мягкое свечение
    finalColor *= 0.7;

    // Базовый темный фон
    float3 backgroundColor = float3(0.05, 0.05, 0.08);

    // Смешиваем с фоном
    finalColor = mix(backgroundColor, finalColor, 0.6);

    // Добавляем легкий blur эффект
    float totalGlow = (glow1 + glow2 + glow3) * 0.3;
    finalColor += totalGlow * 0.15;

    return float4(finalColor, 1.0);
}
