Shader "Unlit/MeshFillerSS"
{
    Properties
    {
        [MainTexture] _BaseMap ("Texture", 2D) = "white" { }
        [MainColor] _BaseColor ("Base Color", Color) = (0, 0, 0, 1)
        _FillColor ("Fill Color", Color) = (1, 1, 1, 1)
        _FillAmount ("Fill Amount", float) = 0
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" "LightMode" = "UniversalForward" }
        LOD 100
        
        Pass
        {
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                float3 normalOS: NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float4 uv: TEXCOORD0;
                float4 positionCS: SV_POSITION;
                float3 positionVS: TEXCOORD4;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            
            CBUFFER_START(UnityPerMaterial)
            half4 _BaseMap_ST;
            half4 _BaseColor;
            half4 _FillColor;
            half4 _OutlineColor;
            half _FillAmount;
            CBUFFER_END
            
            Varyings vert(Attributes i)
            {
                Varyings o;
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_TRANSFER_INSTANCE_ID(i, o);
                
                VertexPositionInputs positionInputs = GetVertexPositionInputs(i.positionOS.xyz);
                
                o.positionCS = positionInputs.positionCS;
                //half3 camPos = GetCameraPositionWS();
                
                //half3  CamDirection = UNITY_MATRIX_V._m30_m31_m32;
                //float3 camForward = -normalize(UNITY_MATRIX_V._m20_m21_m22);
                //float3 camUp = normalize(UNITY_MATRIX_V._m10_m11_m12);
                //float3 camRight = normalize(UNITY_MATRIX_V._m00_m01_m02);
                
                float3 objectViewPos = mul(UNITY_MATRIX_MV, float4(0, 0, 0, 1)).xyz;
                
                o.positionVS = positionInputs.positionVS - objectViewPos;
                
                o.uv = float4(TRANSFORM_TEX(i.uv, _BaseMap), ComputeScreenPos(i.positionOS).xy);
                return o;
            }
            
            half4 frag(Varyings i): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                // sample the texture
                half4 col = 1;
                half2 sUv = i.positionVS.xy;
                half fill = i.positionVS.y;

                //Simple Fill Method
                // half edgeFill =  step(fill,_FillAmount);
                // col.rgb = lerp(_BaseColor, _FillColor,edgeFill);

                //Fancy Fill Method
                half edge1 = _FillAmount + cos(i.positionVS.x * 12 + _Time.z) * 0.02;
                half edge2 = _FillAmount + cos(i.positionVS.x * 6 - _Time.z*1.5) * 0.02;
                half edge1Fill = step(fill, edge1);
                half edge2Fill = step(fill, edge2);

                col = lerp(_BaseColor, _FillColor, (edge1Fill+edge2Fill)*0.5);
                return col;
            }
            ENDHLSL
            
        }
    }
}