#!/bin/bash
# ═══════════════════════════════════════════════════════════
#  Wan2.2 Remix — RunPod Setup
#  Ноды + Модели + Зависимости — всё в одном
# ═══════════════════════════════════════════════════════════

set -e

# ── Путь к ComfyUI ──
read -p "🔧 Путь к ComfyUI [/workspace/runpod-slim/ComfyUI]: " COMFYUI
COMFYUI="${COMFYUI:-/workspace/runpod-slim/ComfyUI}"

NODES="$COMFYUI/custom_nodes"
MODELS="$COMFYUI/models"

echo "═══════════════════════════════════════════"
echo "  Wan2.2 Remix — RunPod Setup"
echo "  ComfyUI: $COMFYUI"
echo "═══════════════════════════════════════════"

if [ ! -d "$COMFYUI" ]; then
    echo "❌ Папка не найдена: $COMFYUI"
    echo "   Укажи правильный путь и запусти снова"
    exit 1
fi

# ═══════════════════════════════════════════════
# 1. CUSTOM NODES
# ═══════════════════════════════════════════════
echo ""
echo "▶ Шаг 1 из 4: Кастомные ноды..."
mkdir -p "$NODES"
cd "$NODES"

clone() {
    url="$1"
    name=$(basename "$url" .git)
    if [ -d "$name" ]; then
        echo "  ✅ $name"
    else
        echo "  📥 $name..."
        git clone "$url" "$name" --quiet
        echo "  ✅ $name"
    fi
}

clone https://github.com/kijai/ComfyUI-KJNodes
clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite
clone https://github.com/chflame163/ComfyUI_LayerStyle
clone https://github.com/rgthree/rgthree-comfy
clone https://github.com/cubiq/ComfyUI_essentials
clone https://github.com/princepainter/ComfyUI-PainterNodes
clone https://github.com/princepainter/Comfyui-PainterVRAM

# ═══════════════════════════════════════════════
# 2. MODELS
# ═══════════════════════════════════════════════
echo ""
echo "▶ Шаг 2 из 4: Модели..."
mkdir -p "$MODELS/diffusion_models" "$MODELS/vae" "$MODELS/clip"

pip install -q huggingface_hub 2>/dev/null

dl() {
    repo="$1"
    filename="$2"
    local_dir="$3"
    label="$4"

    found=$(find "$local_dir" -name "$(basename "$filename")" 2>/dev/null | head -1)
    if [ -n "$found" ] && [ -f "$found" ]; then
        local sz=$(du -h "$found" | cut -f1)
        echo "  ✅ $label ($sz)"
        return 0
    fi

    echo "  📥 $label..."
    python3 -c "
from huggingface_hub import hf_hub_download
hf_hub_download(repo_id='$repo', filename='$filename', local_dir='$local_dir')
"
    found=$(find "$local_dir" -name "$(basename "$filename")" 2>/dev/null | head -1)
    if [ -n "$found" ] && [ -f "$found" ]; then
        local sz=$(du -h "$found" | cut -f1)
        echo "  ✅ $label ($sz)"
    else
        echo "  ❌ Ошибка: $label"
    fi
}

dl "FX-FeiHou/wan2.2-Remix" \
   "NSFW/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_fp8_e4m3fn_v2.1.safetensors" \
   "$MODELS/diffusion_models" \
   "UNET High Lighting (~14 GB)"

dl "FX-FeiHou/wan2.2-Remix" \
   "NSFW/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_fp8_e4m3fn_v2.1.safetensors" \
   "$MODELS/diffusion_models" \
   "UNET Low Lighting (~14 GB)"

dl "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" \
   "split_files/vae/wan_2.1_vae.safetensors" \
   "$MODELS/vae" \
   "VAE Wan (~250 MB)"

dl "zootkitty/nsfw_wan_umt5-xxl_bf16_fixed" \
   "nsfw_wan_umt5-xxl_bf16_fixed.safetensors" \
   "$MODELS/clip" \
   "CLIP NSFW (~11 GB)"

# ═══════════════════════════════════════════════
# 3. DEPENDENCIES
# ═══════════════════════════════════════════════
echo ""
echo "▶ Шаг 3 из 4: Зависимости..."

for d in "$NODES"/ComfyUI-KJNodes \
         "$NODES"/ComfyUI-VideoHelperSuite \
         "$NODES"/ComfyUI_LayerStyle \
         "$NODES"/rgthree-comfy \
         "$NODES"/ComfyUI_essentials \
         "$NODES"/ComfyUI-PainterNodes \
         "$NODES"/Comfyui-PainterVRAM; do
    if [ -f "$d/requirements.txt" ]; then
        name=$(basename "$d")
        echo "  📦 $name..."
        pip install -r "$d/requirements.txt" -q 2>/dev/null || true
    fi
done

# ═══════════════════════════════════════════════
# 4. VERIFY
# ═══════════════════════════════════════════════
echo ""
echo "════════════════════════════════════════════"
echo "  ПРОВЕРКА"
echo "═══════════════════════════════════════════"

all_ok=true

echo ""
echo "  🧠 Модели:"
for f in "$MODELS/diffusion_models/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_fp8_e4m3fn_v2.1.safetensors" \
         "$MODELS/diffusion_models/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_fp8_e4m3fn_v2.1.safetensors" \
         "$MODELS/vae/wan_2.1_vae.safetensors" \
         "$MODELS/clip/nsfw_wan_umt5-xxl_bf16_fixed.safetensors"; do
    found=$(find "$(dirname "$f")" -name "$(basename "$f")" 2>/dev/null | head -1)
    if [ -n "$found" ] && [ -f "$found" ]; then
        echo "     ✅ $(basename "$f") — $(du -h "$found" | cut -f1)"
    else
        echo "     ❌ $(basename "$f") — НЕ НАЙДЕН"
        all_ok=false
    fi
done

echo ""
echo "  📦 Ноды:"
for n in ComfyUI-KJNodes ComfyUI-VideoHelperSuite ComfyUI_LayerStyle rgthree-comfy \
         ComfyUI_essentials ComfyUI-PainterNodes Comfyui-PainterVRAM; do
    if [ -d "$NODES/$n" ]; then
        echo "     ✅ $n"
    else
        echo "     ❌ $n"
        all_ok=false
    fi
done

total=$(du -sh "$MODELS" 2>/dev/null | cut -f1)
echo ""
echo "  💾 Итого моделей: ~$total"

echo ""
echo "═══════════════════════════════════════════"
if $all_ok; then
    echo "  🎉 ВСЁ ГОТОВО!"
else
    echo "  ⚠️  Что-то не установилось — проверь выше"
fi
echo ""
echo "  1. Перезапусти ComfyUI"
echo "  2. Import: wan22-remix-workflow.json"
echo "     https://raw.githubusercontent.com/UrbanMan2411/design-pages/main/wan22/wan22-remix-workflow.json"
echo "  3. Queue Prompt → Поехали!"
echo "═══════════════════════════════════════════"