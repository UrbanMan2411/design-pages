#!/bin/bash
# ═══════════════════════════════════════════════════════════
# Wan2.2 Remix — RunPod Setup Script
# Для запуска в Jupyter Notebook на RunPod:
#   !bash /workspace/comfyui-wan22/setup-wan22.sh
# ═══════════════════════════════════════════════════════════

set -e

COMFYUI_DIR="${1:-/workspace/ComfyUI}"
MODELS_DIR="$COMFYUI_DIR/models"
CUSTOM_NODES="$COMFYUI_DIR/custom_nodes"

echo "═══════════════════════════════════════════════"
echo "  Wan2.2 Remix — ComfyUI на RunPod"
echo "  Путь: $COMFYUI_DIR"
echo "═══════════════════════════════════════════════"

if [ ! -d "$COMFYUI_DIR" ]; then
    echo "⏳ ComfyUI не найден — клонирую..."
    git clone https://github.com/comfyanonymous/ComfyUI "$COMFYUI_DIR"
    cd "$COMFYUI_DIR" && pip install -r requirements.txt
fi

# ═══════════════════════════════════════════════════
# 1. CUSTOM NODES
# ═══════════════════════════════════════════════════

echo ""
echo "📦 Устанавливаю кастомные ноды..."
mkdir -p "$CUSTOM_NODES"
cd "$CUSTOM_NODES"

git_clone_or_pull() {
    local url=$1
    local name=$(basename "$url" .git)
    if [ -d "$name" ]; then
        echo "  ✅ $name — уже стоит, обновляю..."
        cd "$name" && git pull --quiet && cd ..
    else
        echo "  📥 $name..."
        git clone --quiet "$url" "$name"
    fi
}

git_clone_or_pull "https://github.com/kijai/ComfyUI-KJNodes"
git_clone_or_pull "https://github.com/princepainter/ComfyUI-PainterNodes"
git_clone_or_pull "https://github.com/princepainter/Comfyui-PainterVRAM"
git_clone_or_pull "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
git_clone_or_pull "https://github.com/chflame163/ComfyUI_LayerStyle"
git_clone_or_pull "https://github.com/rgthree/rgthree-comfy"
git_clone_or_pull "https://github.com/cubiq/ComfyUI_essentials"

# ═══════════════════════════════════════════════════
# 2. MODELS
# ═══════════════════════════════════════════════════

echo ""
echo "🧠 Скачиваю модели..."

mkdir -p "$MODELS_DIR/diffusion_models" "$MODELS_DIR/vae" "$MODELS_DIR/clip"

dl() {
    local url=$1
    local dest=$2
    local label=$3
    if [ -f "$dest" ]; then
        local sz=$(du -h "$dest" | cut -f1)
        echo "  ✅ $label — уже есть ($sz)"
    else
        echo "  📥 $label..."
        wget --progress=bar:force:noscroll -O "$dest" "$url" 2>&1 | tail -2
    fi
}

dl \
  "https://huggingface.co/FX-FeiHou/wan2.2-Remix/resolve/main/NSFW/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_fp8_e4m3fn_v2.1.safetensors?download=true" \
  "$MODELS_DIR/diffusion_models/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_fp8_e4m3fn_v2.1.safetensors" \
  "UNET High Lighting"

dl \
  "https://huggingface.co/FX-FeiHou/wan2.2-Remix/resolve/main/NSFW/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_fp8_e4m3fn_v2.1.safetensors?download=true" \
  "$MODELS_DIR/diffusion_models/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_fp8_e4m3fn_v2.1.safetensors" \
  "UNET Low Lighting"

dl \
  "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" \
  "$MODELS_DIR/vae/wan_2.1_vae.safetensors" \
  "VAE"

dl \
  "https://huggingface.co/zootkitty/nsfw_wan_umt5-xxl_bf16_fixed/resolve/main/nsfw_wan_umt5-xxl_bf16_fixed.safetensors?download=true" \
  "$MODELS_DIR/clip/nsfw_wan_umt5-xxl_bf16_fixed.safetensors" \
  "CLIP"

# ═══════════════════════════════════════════════════
# 3. VERIFY
# ═══════════════════════════════════════════════════

echo ""
echo "═══════════════════════════════════════════════"
echo "  Проверка"
echo "═══════════════════════════════════════════════"

all_ok=true
for f in \
  "$MODELS_DIR/diffusion_models/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_fp8_e4m3fn_v2.1.safetensors" \
  "$MODELS_DIR/diffusion_models/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_fp8_e4m3fn_v2.1.safetensors" \
  "$MODELS_DIR/vae/wan_2.1_vae.safetensors" \
  "$MODELS_DIR/clip/nsfw_wan_umt5-xxl_bf16_fixed.safetensors"; do
    if [ -f "$f" ]; then
        echo "  ✅ $(basename $f) — $(du -h $f | cut -f1)"
    else
        echo "  ❌ $(basename $f) — НЕ НАЙДЕН"
        all_ok=false
    fi
done

echo ""
if $all_ok; then
    echo "  🎉 Всё готово!"
    echo "  → Перезапусти ComfyUI"
    echo "  → Импортируй workflow JSON"
    echo "  → Queue Prompt и поехали!"
else
    echo "  ⚠️  Что-то не скачалось — проверь интернет/HF."
fi
echo "═══════════════════════════════════════════════"