Shader "Sprites/Custom/SpriteOutline"
{
	Properties
	{
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		[MaterialToggle] PixelSnap ("Pixel snap", Float) = 0
		_OutLineSpread ("OutLine Spread", Range(0.01, 0.05)) = 0.01
		_OutLineColor ("Outline Color", Color) = (1, 1, 1, 1)
		_ShadowOffsetX ("Shadow Offset X", Float) = 0.02
		_ShadowOffsetY ("Shadow Offset Y", Float) = -0.02
		_ShadowColor ("Shadow Color", Color) = (0, 0, 0, 0.8)
	}

	SubShader
	{
		Tags
		{ 
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
		}

		Cull Off
		Lighting Off
		ZWrite Off
		Fog { Mode Off }
		Blend One OneMinusSrcAlpha

		Pass
		{
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile DUMMY PIXELSNAP_ON
			#include "UnityCG.cginc"
			
			struct appdata
			{
				float4 vertex   : POSITION;
				float4 color    : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex	: SV_POSITION;
				fixed4 color    : COLOR;
				float2 texcoord : TEXCOORD0;
			};
			
			sampler2D _MainTex;
			half _OutLineSpread;
			fixed4 _OutLineColor;
			half _ShadowOffsetX;
			half _ShadowOffsetY;
			fixed4 _ShadowColor;

			v2f vert(appdata IN)
			{
				fixed scale = 1.2;

				float2 tex = IN.texcoord * scale;
				tex -= (scale - 1) / 2;

				v2f OUT;
				OUT.vertex = mul(UNITY_MATRIX_MVP, IN.vertex);
				OUT.texcoord = tex;
				OUT.color = IN.color;
				#ifdef PIXELSNAP_ON
				OUT.vertex = UnityPixelSnap (OUT.vertex);
				#endif

				return OUT;
			}

			sampler2D _AlphaTex;
			float _AlphaSplitEnabled;

			fixed4 SampleSpriteTexture (float2 uv)
			{
				fixed4 color = tex2D (_MainTex, uv);

#if UNITY_TEXTURE_ALPHASPLIT_ALLOWED
				if (_AlphaSplitEnabled)
					color.a = tex2D (_AlphaTex, uv).r;
#endif //UNITY_TEXTURE_ALPHASPLIT_ALLOWED

				return color;
			}

			fixed4 frag(v2f IN) : SV_Target
			{
				// アウトライン色
				_OutLineColor.a = 1;
				half2 line_w = half2(_OutLineSpread, 0);
				fixed4 line_col = SampleSpriteTexture(IN.texcoord + line_w.xy)
							    + SampleSpriteTexture(IN.texcoord - line_w.xy)
								+ SampleSpriteTexture(IN.texcoord + line_w.yx)
								+ SampleSpriteTexture(IN.texcoord - line_w.yx);
				_OutLineColor *= step(0.1, line_col.a);

				// 影
				fixed4 shadow = SampleSpriteTexture(IN.texcoord - half2(_ShadowOffsetX, _ShadowOffsetY));
				_ShadowColor *= shadow.a;

				// 元のテクスチャ
				fixed4 base = SampleSpriteTexture(IN.texcoord) * IN.color;

				// 合成
				fixed4 main_col = base;
				main_col += _OutLineColor * (1 - main_col.a);
				main_col += _ShadowColor * (1 - main_col.a);
				return main_col;
			}
		ENDCG
		}
	}
}
