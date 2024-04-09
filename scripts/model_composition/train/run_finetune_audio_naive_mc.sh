#!/bin/bash

# Note: set the base path to the project base path
BASE_PATH="/path/to/base_path"
cd $BASE_PATH
# Note: set the base path to the user root or other path for cache
ROOT="/path/to/user_root"
MODEL_BASE="/path/to/vicuna-7b-v1.5"
PRETRAIN_ADAPTER_PATH="checkpoints/modelcompose-audio-pretrain/mm_projector.bin"

current_time=$(date +"%Y-%m-%d %H:%M:%S")

export WANDB_API_KEY=""
export WANDB_MODE=""
export WANDB_ENTITY=""
export WANDB_PROJECT=""
export WANDB_RUN_NAME=""

check_gpu_idle 0 1 2 3 4 5 6 7


DATA_FILE="data/train/cleaned_audio_instruction_data_formatted.json"

OUTPUT_DIR="modelcompose-audio-finetune-naive-mc"

HF_DATASETS_OFFLINE=1 TRANSFORMERS_OFFLINE=1 \
XDG_CACHE_HOME="$ROOT/.cache" \
HF_HOME="$ROOT/.cache/huggingface" \
PYTHONPATH=$BASE_PATH \
deepspeed --include localhost:0,1,2,3,4,5,6,7 --master_port 29952 modelcompose/train/train_multimodal.py \
    --lora_strategy same --lora_r 128 --lora_alpha 256 --mm_projector_lr 2e-5 \
    --deepspeed ./scripts/zero2.json \
    --model_name_or_path $MODEL_BASE \
    --pretrain_mm_mlp_adapter $PRETRAIN_ADAPTER_PATH \
    --version v1 \
    --data_path $DATA_FILE \
    --mm_audio_encoder beats/BEATs_iter3_plus_AS2M.pt \
    --mm_audio_projector_type qformer_32N_2L \
    --group_by_modality_length False \
    --bf16 True \
    --output_dir checkpoints/$OUTPUT_DIR \
    --num_train_epochs 1 \
    --per_device_train_batch_size 8 \
    --per_device_eval_batch_size 4 \
    --gradient_accumulation_steps 2 \
    --evaluation_strategy "no" \
    --save_strategy "steps" \
    --save_steps 50000 \
    --save_total_limit 1 \
    --learning_rate 2e-5 \
    --weight_decay 0. \
    --warmup_ratio 0.03 \
    --lr_scheduler_type "cosine" \
    --logging_steps 1 \
    --tf32 True \
    --model_max_length 2048 \
    --gradient_checkpointing True \
    --dataloader_num_workers 4 \
    --dataloader_drop_last True \
    --lazy_preprocess True \
    --report_to wandb