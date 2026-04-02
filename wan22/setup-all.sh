#!/bin/bash
# ═══════════════════════════════════════════════════════════
#  Wan2.2 Remix — Полный скрипт для RunPod
#  Всё в одном: ноды + модели + зависимости
# ═══════════════════════════════════════════════════════════

set -e

COMFYUI="/workspace/runpod-slim/ComfyUI"
NODES="$COMFYUI/custom_nodes"
MODELS="$COMFYUI/models"

echo "═══════════════════════════════════════════════"
echo "  Wan2.2 Remix — RunPod Setup"
echo "  ComfyUI: $COMFYUI"
echo "═══════════════════════════════════════════════"

# ───────────────────────────────────────────────────
# 1. CUSTOM NODES — Git clone
# ───────────────────────────────────────────────────
echo ""
echo "▶ Шаг 1: Кастомные ноды..."
mkdir -p "$NODES"
cd "$NODES"

clone() {
    url="$1"
    name=$(basename "$url" .git)
    if [ -d "$name" ]; then
        echo "  ✅ $name — уже установлен"
    else
        echo "  📥 $name..."
        git clone "$url" "$name" --quiet 2>&1 && echo "  ✅ $name — готово!"
    fi
}

clone https://github.com/kijai/ComfyUI-KJNodes
clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite
clone https://github.com/chflame163/ComfyUI_LayerStyle
clone https://github.com/rgthree/rgthree-comfy
clone https://github.com/cubiq/ComfyUI_essentials
clone https://github.com/princepainter/ComfyUI-PainterNodes
clone https://github.com/princepainter/Comfyui-PainterVRAM

# ───────────────────────────────────────────────────
# 2. MODELS — скачать через huggingface_hub
# ───────────────────────────────────────────────────
echo ""
echo "▶ Шаг 2: Модели..."

mkdir -p "$MODELS/diffusion_models" "$MODELS/vae" "$MODELS/clip"

pip install -q huggingface_hub 2>/dev/null

dl() {
    repo="$1"
    filename="$2"
    local_dir="$3"
    label="$4"
    
    # Проверяем все вложенные пути
    found=""
    for suffix in "" $(dirname "$filename" | tr '/' '\n' | while read p; do
        echo "*/$p/"
    done | tr '\n' ' '); do
        local base=$(basename "$filename")
        local path=$(dirname "$filename")
        for candidate in "$local_dir/$base" "$local_dir/$path/$base"; do
            if [ -f "$candidate" ]; then
                found="$candidate"
                break
            fi
        done
    done
    
    if [ -n "$found" ]; then
        echo "  ✅ $label — уже есть ($(du -h "$found" | cut -f1))"
        return 0
    fi
    
    echo "  📥 $label..."
    python3 -c "
from huggingface_hub import hf_hub_download
hf_hub_download(repo_id='$repo', filename='$filename', local_dir='$local_dir')
print(f'  ✅ $label — скачано!')
"
    
    echo "     Размер: $(du -h $(find "$local_dir" -name "$(basename "$filename")" 2>/dev/null | head -1) | cut -f1 2>/dev/null || echo '?')"
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
   "CLIP NSFW UMT5-XXL (~11 GB)"

# ───────────────────────────────────────────────────
# 3. DEPENDENCIES — pip install requirements для каждой ноды
# ───────────────────────────────────────────────────
echo ""
echo "▶ Шаг 3: Зависимости нод..."

for d in "$NODES"/ComfyUI-KJNodes "$NODES"/ComfyUI-VideoHelperSuite \
         "$NODES"/ComfyUI_LayerStyle "$NODES"/rgthree-comfy \
         "$NODES"/ComfyUI_essentials "$NODES"/ComfyUI-PainterNodes \
         "$NODES"/Comfyui-PainterVRAM; do
    if [ -f "$d/requirements.txt" ]; then
        name=$(basename "$d")
        echo "  📦 $name..."
        pip install -r "$d/requirements.txt" -q 2>/dev/null || true
    fi
done

# ───────────────────────────────────────────────────
# 4. VERIFY — проверяем всё
# ───────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════"
echo "  ПРОВЕРКА"
echo "═══════════════════════════════════════════════"

# Модели
echo ""
echo "  🧠 Модели:"
for f in "$MODELS/diffusion_models/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_fp8_e4m3fn_v2.1.safetensors" \
         "$MODELS/diffusion_models/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_fp8_e4m3fn_v2.1.safetensors" \
         "$MODELS/vae/wan_2.1_vae.safetensors" \
         "$MODELS/clip/nsfw_wan_umt5-xxl_bf16_fixed.safetensors"; do
    if [ -f "$f" ]; then
        echo "     ✅ $(basename "$f") — $(du -h "$f" | cut -f1)"
    else
        echo "     ❌ $(basename "$f") — НЕ НАЙДЕН"
    fi
done

# Ноды
echo ""
echo "  📦 Кастомные ноды:"
for n in ComfyUI-KJNodes ComfyUI-VideoHelperSuite ComfyUI_LayerStyle rgthree-comfy \
         ComfyUI_essentials ComfyUI-PainterNodes Comfyui-PainterVRAM; do
    if [ -d "$NODES/$n" ]; then
        echo "     ✅ $n"
    else
        echo "     ❌ $n — НЕ НАЙДЕН"
    fi
done

total_size=$(du -sh "$MODELS/diffusion_models" 2>/dev/null | cut -f1)
echo ""
echo "  💾 Общий размер моделей: ~${total_size:-?}"

echo ""
echo "═══════════════════════════════════════════════"
echo "  🎉 ГОТОВО!"
echo ""
echo "  1. Перезапусти ComfyUI"
echo "  2. Import workflow: wan22-remix-workflow.json"
echo "     https://raw.githubusercontent.com/UrbanMan2411/design-pages/main/wan22/wan22-remix-workflow.json"
echo "  3. Queue Prompt → Поехали!"
echo "═══════════════════════════════════════════════"