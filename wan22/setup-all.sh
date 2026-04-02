#!/bin/bash
set -e

# ════ Автопоиск ComfyUI ════
COMFYUI=""
for d in /workspace/runpod-slim/ComfyUI /workspace/ComfyUI /root/ComfyUI /ComfyUI; do
    [ -d "$d" ] && COMFYUI="$d" && break
done

if [ -z "$COMFYUI" ]; then
    read -p "🔧 Путь к ComfyUI: " COMFYUI
    [[ "$COMFYUI" != /* ]] && COMFYUI="/workspace/$COMFYUI"
fi
COMFYUI="${COMFYUI%/}"

NODES="$COMFYUI/custom_nodes"
MODELS="$COMFYUI/models"

echo "════════════════════════════════════════"
echo "  🚀 Wan2.2 Remix — RunPod Setup v5"
echo "  ComfyUI: $COMFYUI"
echo "════════════════════════════════════════"
[ -d "$COMFYUI" ] || { echo "❌ НЕ НАЙДЕНО: $COMFYUI"; exit 1; }

# ════ 1/4 НОДЫ ════
echo ""
echo "▶ 1/4 Ноды..."
mkdir -p "$NODES" && cd "$NODES"

clone() {
    local n=$(basename "$1" .git)
    if [ -d "$n" ]; then echo "  ✅ $n"
    else echo "  📥 $n..."; git clone "$1" "$n" --quiet && echo "  ✅ $n"
    fi
}

clone https://github.com/kijai/ComfyUI-KJNodes
clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite
clone https://github.com/chflame163/ComfyUI_LayerStyle
clone https://github.com/rgthree/rgthree-comfy
clone https://github.com/cubiq/ComfyUI_essentials
clone https://github.com/princepainter/ComfyUI-PainterNodes
clone https://github.com/princepainter/Comfyui-PainterVRAM

# ════ 2/4 МОДЕЛИ ════
echo ""
echo "▶ 2/4 Модели..."
mkdir -p "$MODELS/diffusion_models" "$MODELS/vae" "$MODELS/clip"
pip install -q huggingface_hub 2>/dev/null

dl() {
    local repo="$1" fname="$2" ldir="$3" label="$4"
    local base=$(basename "$fname")
    local found=$(find "$ldir" -name "$base" -type f 2>/dev/null | head -1)
    if [ -n "$found" ]; then
        echo "  ✅ $label ($(du -h "$found" | cut -f1))"
        return
    fi
    echo "  📥 $label..."
    # ВАЖНО: только именованные параметры!
    python3 << PYEOF
from huggingface_hub import hf_hub_download
hf_hub_download(
    repo_id="${repo}",
    filename="${fname}",
    local_dir="${ldir}"
)
PYEOF
    local found2=$(find "$ldir" -name "$base" -type f 2>/dev/null | head -1)
    [ -n "$found2" ] && echo "  ✅ $label ($(du -h "$found2" | cut -f1))" || echo "  ❌ $label"
}

dl "FX-FeiHou/wan2.2-Remix" \
   "NSFW/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_fp8_e4m3fn_v2.1.safetensors" \
   "$MODELS/diffusion_models" \
   "UNET High (~14 GB)"

dl "FX-FeiHou/wan2.2-Remix" \
   "NSFW/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_fp8_e4m3fn_v2.1.safetensors" \
   "$MODELS/diffusion_models" \
   "UNET Low  (~14 GB)"

dl "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" \
   "split_files/vae/wan_2.1_vae.safetensors" \
   "$MODELS/vae" \
   "VAE (~250 MB)"

dl "zootkitty/nsfw_wan_umt5-xxl_bf16_fixed" \
   "nsfw_wan_umt5-xxl_bf16_fixed.safetensors" \
   "$MODELS/clip" \
   "CLIP (~11 GB)"

# ════ 3/4 ЗАВИСИМОСТИ ════
echo ""
echo "▶ 3/4 Зависимости..."
for d in "$NODES"/ComfyUI-KJNodes \
         "$NODES"/ComfyUI-VideoHelperSuite \
         "$NODES"/ComfyUI_LayerStyle \
         "$NODES"/rgthree-comfy \
         "$NODES"/ComfyUI_essentials \
         "$NODES"/ComfyUI-PainterNodes \
         "$NODES"/Comfyui-PainterVRAM; do
    if [ -f "$d/requirements.txt" ]; then
        echo "  📦 $(basename "$d")..."
        pip install -r "$d/requirements.txt" -q 2>/dev/null || true
    fi
done

# ════ 4/4 ИТОГ ════
echo ""
echo "════════════════════════════════════════"
echo "  🎉 ВСЁ ГОТОВО!"
echo ""
echo "  1. Перезапусти ComfyUI"
echo "  2. Import: wan22-remix-workflow.json"
echo "     https://raw.githubusercontent.com/UrbanMan2411/design-pages/main/wan22/wan22-remix-workflow.json"
echo "  3. Queue Prompt → Поехали!"
echo "════════════════════════════════════════"
