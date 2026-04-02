#!/bin/bash
# ═══════════════════════════════════════════════════════════
#  Wan2.2 Remix — RunPod Setup (v3)
#  Автопоиск ComfyUI + ноды + модели + зависимости
# ═══════════════════════════════════════════════════════════

set -e

echo "🔍 Ищу ComfyUI..."

# Автопоиск в типичных местах
COMFYUI=""
for d in /workspace/runpod-slim/ComfyUI /workspace/ComfyUI /root/ComfyUI /ComfyUI; do
    if [ -d "$d" ]; then
        COMFYUI="$d"
        break
    fi
done

# Если не нашли — спрашиваем
if [ -z "$COMFYUI" ]; then
    read -p "🔧 Путь к ComfyUI: " COMFYUI
    if [[ "$COMFYUI" != /* ]]; then
        COMFYUI="/workspace/$COMFYUI"
    fi
fi

NODES="$COMFYUI/custom_nodes"
MODELS="$COMFYUI/models"

echo "═══════════════════════════════════════════"
echo "  🚀 Wan2.2 Remix — RunPod Setup"
echo "  Путь: $COMFYUI"
echo "═══════════════════════════════════════════"

if [ ! -d "$COMFYUI" ]; then
    echo "❌ НЕ НАЙДЕНО: $COMFYUI"
    exit 1
fi

# ── 1/4 НОДЫ ──
echo ""
echo "▶ 1/4 Кастомные ноды..."
mkdir -p "$NODES"
cd "$NODES"

clone() {
    local name=$(basename "$1" .git)
    if [ -d "$name" ]; then
        echo "  ✅ $name"
    else
        echo "  📥 $name..."
        git clone "$1" "$name" --quiet && echo "  ✅ $name"
    fi
}

clone https://github.com/kijai/ComfyUI-KJNodes
clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite
clone https://github.com/chflame163/ComfyUI_LayerStyle
clone https://github.com/rgthree/rgthree-comfy
clone https://github.com/cubiq/ComfyUI_essentials
clone https://github.com/princepainter/ComfyUI-PainterNodes
clone https://github.com/princepainter/Comfyui-PainterVRAM

# ── 2/4 МОДЕЛИ ──
echo ""
echo "▶ 2/4 Модели..."
mkdir -p "$MODELS/diffusion_models" "$MODELS/vae" "$MODELS/clip"

pip install -q huggingface_hub 2>/dev/null

dl() {
    local label="$4"
    local base=$(basename "$2")
    local found=$(find "$3" -name "$base" -type f 2>/dev/null | head -1)
    if [ -n "$found" ]; then
        echo "  ✅ $label ($(du -h "$found" | cut -f1))"
        return 0
    fi
    echo "  📥 $label..."
    python3 -c "from huggingface_hub import hf_hub_download; hf_hub_download('$1','$2','$3')"
    local found2=$(find "$3" -name "$base" -type f 2>/dev/null | head -1)
    [ -n "$found2" ] && echo "  ✅ $label ($(du -h "$found2" | cut -f1))"
}

dl "FX-FeiHou/wan2.2-Remix" "NSFW/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_fp8_e4m3fn_v2.1.safetensors" "$MODELS/diffusion_models" "UNET High"
dl "FX-FeiHou/wan2.2-Remix" "NSFW/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_fp8_e4m3fn_v2.1.safetensors" "$MODELS/diffusion_models" "UNET Low"
dl "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" "split_files/vae/wan_2.1_vae.safetensors" "$MODELS/vae" "VAE"
dl "zootkitty/nsfw_wan_umt5-xxl_bf16_fixed" "nsfw_wan_umt5-xxl_bf16_fixed.safetensors" "$MODELS/clip" "CLIP"

# ── 3/4 ЗАВИСИМОСТИ ──
echo ""
echo "▶ 3/4 Зависимости..."
for d in "$NODES"/ComfyUI-KJNodes "$NODES"/ComfyUI-VideoHelperSuite "$NODES"/ComfyUI_LayerStyle "$NODES"/rgthree-comfy "$NODES"/ComfyUI_essentials "$NODES"/ComfyUI-PainterNodes "$NODES"/Comfyui-PainterVRAM; do
    if [ -f "$d/requirements.txt" ]; then
        echo "  📦 $(basename "$d")..."
        pip install -r "$d/requirements.txt" -q 2>/dev/null || true
    fi
done

# ── 4/4 ПРОВЕРКА ──
echo ""
echo "═══════════════════════════════════════════"
echo " ✅ ГОТОВО!"
echo ""
echo "  Перезапусти ComfyUI → Import workflow → Queue!"
echo "═══════════════════════════════════════════"
