#!/bin/bash
# Wan2.2 Remix — Скачивание оставшихся моделей
# Запускать из любой папки на RunPod

set -e

MODEL_DIR="/workspace/runpod-slim/ComfyUI/models"
DIFF_DIR="$MODEL_DIR/diffusion_models"
VAE_DIR="$MODEL_DIR/vae"
CLIP_DIR="$MODEL_DIR/clip"

mkdir -p "$DIFF_DIR" "$VAE_DIR" "$CLIP_DIR"

echo "═══════════════════════════════════════════"
echo "  Wan2.2 — Скачиваю оставшиеся модели"
echo "═══════════════════════════════════════════"

check_done() {
    if [ -f "$1" ]; then
        echo "  ✅ $(basename "$1") — уже есть ($(du -h "$1" | cut -f1))"
        return 0
    fi
    return 1
}

download() {
    local repo="$1"
    local filename="$2"
    local local_dir="$3"
    local label="$4"
    
    if check_done "$local_dir/$filename"; then
        return 0
    fi
    
    echo ""
    echo "  📥 $label..."
    python3 -c "
from huggingface_hub import hf_hub_download
hf_hub_download(
    repo_id='$repo',
    filename='$filename',
    local_dir='$local_dir'
)
print('  ✅ $label — готово!')
"
    if [ -f "$local_dir/$filename" ]; then
        echo "  ✅ Размер: $(du -h "$local_dir/$filename" | cut -f1)"
    else
        echo "  ❌ Не скачалось $label"
    fi
}

# 1. UNET Low Lighting
download \
  "FX-FeiHou/wan2.2-Remix" \
  "NSFW/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_fp8_e4m3fn_v2.1.safetensors" \
  "$DIFF_DIR" \
  "UNET Low Lighting"

# 2. VAE
download \
  "Comfy-Org/Wan_2.2_ComfyUI_Repackaged" \
  "split_files/vae/wan_2.1_vae.safetensors" \
  "$VAE_DIR" \
  "VAE Wan"

# 3. CLIP
download \
  "zootkitty/nsfw_wan_umt5-xxl_bf16_fixed" \
  "nsfw_wan_umt5-xxl_bf16_fixed.safetensors" \
  "$CLIP_DIR" \
  "CLIP NSFW UMT5-XXL"

echo ""
echo "═══════════════════════════════════════════"
echo "  Итог — все модели:"
echo "═══════════════════════════════════════════"
for f in "$DIFF_DIR/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_fp8_e4m3fn_v2.1.safetensors" \
         "$DIFF_DIR/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_fp8_e4m3fn_v2.1.safetensors" \
         "$VAE_DIR/wan_2.1_vae.safetensors" \
         "$CLIP_DIR/nsfw_wan_umt5-xxl_bf16_fixed.safetensors"; do
    if [ -f "$f" ]; then
        echo "  ✅ $(basename "$f") — $(du -h "$f" | cut -f1)"
    else
        echo "  ❌ $(basename "$f") — НЕ НАЙДЕН"
    fi
done
echo "═══════════════════════════════════════════"